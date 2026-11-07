#!/usr/bin/env python3
"""Tests for az0x_img.py. Run: python3 -I tools/test_az0x_img.py

The header test rebuilds the Force 3.10 header from its known field values
and checks the offsets measured on the official image (header_len 0x74,
first record at 0x78, PART header length 0x4c)."""

import hashlib
import lzma
import os
import struct
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import az0x_img as az  # noqa: E402


class FormatTests(unittest.TestCase):
    def test_force_header_offsets(self):
        hdr = az.build_header("SNAPSHOT-20261014151952", ["inmusic,ada2"],
                              [az.parse_usb_id("09e8:4040")],
                              "Akai Professional Force upgrade image")
        self.assertEqual(hdr[:4], b"AZ01")
        self.assertEqual(struct.unpack_from("<II", hdr, 4), (1, 0x74))
        self.assertEqual(len(hdr), 0x78)
        part = az.build_part_header("rootfs", "xz", [("sha1", b"\0" * 20)], 186528020)
        self.assertEqual(struct.unpack_from("<I", part, 4)[0], 0x4c)
        self.assertEqual(len(part), 0x4c)

    def test_roundtrip(self):
        with tempfile.TemporaryDirectory() as d:
            raw = os.path.join(d, "rootfs.ext4")
            data = os.urandom(3000) + b"\0" * 200000 + b"tail"
            with open(raw, "wb") as f:
                f.write(data)
            out = os.path.join(d, "test.img")
            az.pack(out, "1.2.3", ["inmusic,ada2", "inmusic,acv5"],
                    [az.parse_usb_id("09e8:4040")], "test image",
                    [("rootfs", raw), ("data", raw)])
            img = az.read_image(out)
            self.assertEqual(img.version, "1.2.3")
            self.assertEqual(img.compatibles, ["inmusic,ada2", "inmusic,acv5"])
            self.assertEqual([az.usb_id_str(v) for v in img.usb_ids], ["09e8:4040"])
            self.assertEqual([p.name for p in img.parts], ["rootfs", "data"])
            for p in img.parts:
                self.assertEqual(p.offset % 4, 0)
            self.assertTrue(all(ok for _, _, ok in az.check_hashes(img)))
            # sha1 covers the compressed payload, as on official images
            with open(out, "rb") as f:
                f.seek(img.parts[0].offset)
                payload = f.read(img.parts[0].length)
            self.assertEqual(hashlib.sha1(payload).digest(), img.parts[0].hashes[0][1])
            self.assertEqual(lzma.decompress(payload), data)
            files = az.unpack(img, os.path.join(d, "out"))
            with open(files[0], "rb") as f:
                self.assertEqual(f.read(), data)

    def test_corruption_detected(self):
        with tempfile.TemporaryDirectory() as d:
            raw = os.path.join(d, "r")
            with open(raw, "wb") as f:
                f.write(b"x" * 5000)
            out = os.path.join(d, "t.img")
            az.pack(out, "v", ["c"], [], "d", [("rootfs", raw)])
            img = az.read_image(out)
            with open(out, "r+b") as f:
                f.seek(img.parts[0].offset + 10)
                b = f.read(1)
                f.seek(-1, 1)
                f.write(bytes([b[0] ^ 0xFF]))
            self.assertFalse(az.check_hashes(az.read_image(out))[0][2])

    def test_rejects_other_versions(self):
        with tempfile.TemporaryDirectory() as d:
            p = os.path.join(d, "v3.img")
            with open(p, "wb") as f:
                f.write(b"AZ01" + struct.pack("<II", 3, 12) + b"\0" * 64)
            with self.assertRaises(az.FormatError):
                az.read_image(p)


if __name__ == "__main__":
    unittest.main()
