#!/usr/bin/env python3
"""Read, check, unpack and create AZ01 version 1 update images.

AZ01 v1 is the update container used by gen1 Akai MPC / Force firmware
(e.g. 3.10). It is integrity-checked (per-partition hash) but not signed.
The layout is described in docs/BOOT_CHAIN.md.

  az0x_img.py info   IMAGE
  az0x_img.py verify IMAGE
  az0x_img.py unpack IMAGE OUTDIR [--raw]
  az0x_img.py pack   OUT --compatible inmusic,ada2 --usb-id 09e8:4040 \
                     --version 1.0 --description "..." --part rootfs=rootfs.ext4

Only the Python standard library is used.
"""

import argparse
import hashlib
import lzma
import os
import shutil
import struct
import sys
import tempfile

MAGIC = b"AZ01"
FORMAT_VERSION = 1
CHUNK = 1 << 20


def align(n, a):
    return (n + a - 1) // a * a


class FormatError(Exception):
    pass


# --- low level encoding -----------------------------------------------------

def enc_u32(v):
    return struct.pack("<I", v)


def enc_str(s):
    b = s.encode()
    body = b + b"\0"
    return enc_u32(len(b)) + body + b"\0" * (align(len(body), 4) - len(body))


def enc_blob(b):
    return enc_u32(len(b)) + b + b"\0" * (align(len(b), 4) - len(b))


class Reader:
    def __init__(self, data, pos=0):
        self.data, self.pos = data, pos

    def need(self, n):
        if self.pos + n > len(self.data):
            raise FormatError("truncated at offset 0x%x" % self.pos)

    def u32(self):
        self.need(4)
        v, = struct.unpack_from("<I", self.data, self.pos)
        self.pos += 4
        return v

    def str(self):
        n = self.u32()
        self.need(align(n + 1, 4))
        b = self.data[self.pos:self.pos + n]
        if self.data[self.pos + n] != 0:
            raise FormatError("string at 0x%x not NUL terminated" % (self.pos - 4))
        self.pos += align(n + 1, 4)
        return b.decode()

    def blob(self):
        n = self.u32()
        self.need(align(n, 4))
        b = bytes(self.data[self.pos:self.pos + n])
        self.pos += align(n, 4)
        return b


# --- parsing ----------------------------------------------------------------

class Part:
    def __init__(self, name, compression, hashes, offset, length):
        self.name = name
        self.compression = compression
        self.hashes = hashes          # list of (algorithm, bytes)
        self.offset = offset          # payload offset in the file
        self.length = length          # payload length


class Image:
    pass


def read_image(path):
    """Parse an AZ01 v1 image. Reads headers only; payloads stay on disk."""
    size = os.path.getsize(path)
    with open(path, "rb") as f:
        head = f.read(64 * 1024)
        if head[:4] != MAGIC:
            raise FormatError("not an AZ01 image (magic %r)" % head[:4])
        r = Reader(head, 4)
        img = Image()
        img.path, img.size = path, size
        img.format_version = r.u32()
        if img.format_version != FORMAT_VERSION:
            raise FormatError("AZ01 format version %d is not supported "
                              "(only v1; newer versions are signed)" % img.format_version)
        img.header_len = r.u32()
        img.version = r.str()
        img.compatibles = [r.str() for _ in range(r.u32())]
        img.usb_ids = [r.u32() for _ in range(r.u32())]
        img.description = r.str()
        if r.pos != img.header_len:
            raise FormatError("header length says 0x%x, fields end at 0x%x"
                              % (img.header_len, r.pos))

        img.parts = []
        pos = align(img.header_len, 8)
        while True:
            f.seek(pos)
            pre = f.read(16)
            if len(pre) < 16:
                raise FormatError("missing EOF record (file ends at 0x%x)" % size)
            tag, hlen, plen = struct.unpack("<4sIQ", pre)
            if tag == b"EOF\0":
                if hlen != 16 or plen != 0:
                    raise FormatError("bad EOF record at 0x%x" % pos)
                img.eof_offset = pos
                if pos + 16 != size:
                    raise FormatError("%d bytes after EOF record" % (size - pos - 16))
                break
            if tag != b"PART":
                raise FormatError("unknown record %r at 0x%x" % (tag, pos))
            f.seek(pos)
            rr = Reader(f.read(hlen), 16)
            name = rr.str()
            comp = rr.str()
            hashes = []
            for _ in range(rr.u32()):
                algo = rr.str()
                hashes.append((algo, rr.blob()))
            if rr.pos != hlen:
                raise FormatError("PART header at 0x%x: length 0x%x, fields end at 0x%x"
                                  % (pos, hlen, rr.pos))
            off = pos + hlen
            if off + plen > size:
                raise FormatError("PART %s payload runs past end of file" % name)
            img.parts.append(Part(name, comp, hashes, off, plen))
            pos = align(off + plen, 8)
    return img


def usb_id_str(v):
    return "%04x:%04x" % (v >> 16, v & 0xFFFF)


def iter_payload(f, part):
    f.seek(part.offset)
    left = part.length
    while left:
        b = f.read(min(CHUNK, left))
        if not b:
            raise FormatError("short read in %s" % part.name)
        left -= len(b)
        yield b


def check_hashes(img):
    """Return list of (part, algo, ok)."""
    out = []
    with open(img.path, "rb") as f:
        for p in img.parts:
            hs = {}
            for algo, _ in p.hashes:
                try:
                    hs[algo] = hashlib.new(algo)
                except ValueError:
                    raise FormatError("unknown hash algorithm %r" % algo)
            for chunk in iter_payload(f, p):
                for h in hs.values():
                    h.update(chunk)
            for algo, value in p.hashes:
                out.append((p, algo, hs[algo].digest() == value))
    return out


# --- writing ----------------------------------------------------------------

def build_header(version, compatibles, usb_ids, description):
    body = enc_u32(FORMAT_VERSION) + b"\0\0\0\0" + enc_str(version)
    body += enc_u32(len(compatibles)) + b"".join(enc_str(c) for c in compatibles)
    body += enc_u32(len(usb_ids)) + b"".join(enc_u32(v) for v in usb_ids)
    body += enc_str(description)
    header_len = 4 + len(body)
    body = body[:4] + enc_u32(header_len) + body[8:]
    hdr = MAGIC + body
    return hdr + b"\0" * (align(header_len, 8) - header_len)


def build_part_header(name, compression, hashes, payload_len):
    fields = enc_str(name) + enc_str(compression) + enc_u32(len(hashes))
    for algo, value in hashes:
        fields += enc_str(algo) + enc_blob(value)
    return b"PART" + struct.pack("<IQ", 16 + len(fields), payload_len) + fields


def compress_to(src, dst, compression):
    if compression == "none":
        shutil.copyfile(src, dst)
        return
    if compression != "xz":
        raise FormatError("unsupported compression %r" % compression)
    comp = lzma.LZMACompressor(lzma.FORMAT_XZ, check=lzma.CHECK_CRC32, preset=6)
    with open(src, "rb") as fi, open(dst, "wb") as fo:
        for b in iter(lambda: fi.read(CHUNK), b""):
            fo.write(comp.compress(b))
        fo.write(comp.flush())


def pack(out, version, compatibles, usb_ids, description, parts,
         compression="xz", algo="sha1"):
    """parts: list of (partition_name, raw_file_path)."""
    tmpdir = tempfile.mkdtemp(prefix="az0x-img-")
    try:
        with open(out + ".tmp", "wb") as fo:
            fo.write(build_header(version, compatibles, usb_ids, description))
            for name, src in parts:
                payload = os.path.join(tmpdir, "payload")
                compress_to(src, payload, compression)
                h = hashlib.new(algo)
                with open(payload, "rb") as fp:
                    for b in iter(lambda: fp.read(CHUNK), b""):
                        h.update(b)
                plen = os.path.getsize(payload)
                fo.write(build_part_header(name, compression, [(algo, h.digest())], plen))
                with open(payload, "rb") as fp:
                    shutil.copyfileobj(fp, fo, CHUNK)
                fo.write(b"\0" * (align(fo.tell(), 8) - fo.tell()))
                os.unlink(payload)
            fo.write(b"EOF\0" + struct.pack("<IQ", 16, 0))
        os.replace(out + ".tmp", out)
    finally:
        shutil.rmtree(tmpdir, ignore_errors=True)


def unpack(img, outdir, raw=False):
    os.makedirs(outdir, exist_ok=True)
    written = []
    with open(img.path, "rb") as f:
        for p in img.parts:
            if raw or p.compression == "none":
                dst = os.path.join(outdir, p.name + (".bin" if p.compression == "none" else "." + p.compression))
                with open(dst, "wb") as fo:
                    for b in iter_payload(f, p):
                        fo.write(b)
            elif p.compression == "xz":
                dst = os.path.join(outdir, p.name + ".img")
                d = lzma.LZMADecompressor(lzma.FORMAT_XZ)
                with open(dst, "wb") as fo:
                    for b in iter_payload(f, p):
                        fo.write(d.decompress(b))
            else:
                raise FormatError("can't decompress %r (use --raw)" % p.compression)
            written.append(dst)
    return written


# --- command line -------------------------------------------------------------

def parse_usb_id(s):
    vid, pid = s.split(":")
    return (int(vid, 16) << 16) | int(pid, 16)


def cmd_info(a):
    img = read_image(a.image)
    print("AZ01 v%d  %s" % (img.format_version, img.path))
    print("  version:     %s" % img.version)
    print("  description: %s" % img.description)
    print("  compatible:  %s" % ", ".join(img.compatibles))
    print("  usb ids:     %s" % ", ".join(usb_id_str(v) for v in img.usb_ids))
    for p in img.parts:
        print("  PART %-10s %s, %d bytes at 0x%x" % (p.name, p.compression, p.length, p.offset))
        for algo, value in p.hashes:
            print("       %s %s" % (algo, value.hex()))
    return 0


def cmd_verify(a):
    img = read_image(a.image)
    bad = 0
    for p, algo, ok in check_hashes(img):
        print("%-10s %-7s %s" % (p.name, algo, "OK" if ok else "MISMATCH"))
        bad += not ok
    return 1 if bad else 0


def cmd_unpack(a):
    img = read_image(a.image)
    for path in unpack(img, a.outdir, a.raw):
        print(path)
    return 0


def cmd_pack(a):
    parts = []
    for spec in a.part:
        name, _, src = spec.partition("=")
        if not name or not src:
            raise SystemExit("--part must be NAME=FILE")
        parts.append((name, src))
    pack(a.out, a.version, a.compatible, [parse_usb_id(u) for u in a.usb_id],
         a.description, parts, a.compression, a.hash)
    print(a.out)
    return 0


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    sub = ap.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("info", help="print the header")
    p.add_argument("image")
    p.set_defaults(fn=cmd_info)
    p = sub.add_parser("verify", help="check every partition hash")
    p.add_argument("image")
    p.set_defaults(fn=cmd_verify)
    p = sub.add_parser("unpack", help="write each partition to OUTDIR")
    p.add_argument("image")
    p.add_argument("outdir")
    p.add_argument("--raw", action="store_true", help="don't decompress")
    p.set_defaults(fn=cmd_unpack)
    p = sub.add_parser("pack", help="create an image")
    p.add_argument("out")
    p.add_argument("--version", required=True, help="build/version string")
    p.add_argument("--compatible", action="append", required=True,
                   help="device-tree compatible the image accepts (repeatable)")
    p.add_argument("--usb-id", action="append", default=[],
                   help="VID:PID of the device in update mode (repeatable)")
    p.add_argument("--description", required=True)
    p.add_argument("--part", action="append", required=True,
                   help="PARTLABEL=raw image file, e.g. rootfs=rootfs.ext4")
    p.add_argument("--compression", default="xz", choices=["xz", "none"])
    p.add_argument("--hash", default="sha1", choices=["sha1", "sha256"])
    p.set_defaults(fn=cmd_pack)
    a = ap.parse_args(argv)
    try:
        return a.fn(a)
    except FormatError as e:
        print("error: %s" % e, file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
