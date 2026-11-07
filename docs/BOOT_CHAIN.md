# gen1 boot chain, partitions and update images

What we found on an Akai Force running firmware 3.10, read-only. The raw
data is in [gen1/force/reference](../gen1/force/reference). The MPC Live
is expected to be the same apart from device trees; this will be confirmed
once its reference data is in.

## Summary

- **Nothing checks a signature.** The bootloader is U-Boot 2016.05 with
  no RSA code, and the device reports `secure-boot: 0`. Update images
  (AZ01 v1) carry only a SHA-1 per partition.
- **The kernel lives in the root filesystem.** U-Boot loads `/boot/zImage`
  and a device tree from the `rootfs` partition, so replacing that one
  partition replaces the whole OS.
- **There is a fastboot recovery mode** in U-Boot, so a broken rootfs can
  be reflashed over USB.

## Boot

1. The RK3288 boot ROM loads U-Boot SPL from eMMC (sector 64), then U-Boot
   (`U-Boot 2016.05-inmusic-20180928`).
2. U-Boot's `bootcmd` runs `az01_bootcmd`. If the recovery button is held
   (read through an ADC, sets `dorecovery=1`), it starts fastboot instead.
3. Otherwise it scans the partition marked bootable (`rootfs`) for
   `/boot/boot.scr.uimg` and runs it.
4. The script loads `/boot/zImage` and `/boot/${fdtfile}` and runs
   `bootz`. U-Boot sets `fdtfile` itself. The Force uses
   `rk3288-az01-ada2.dtb` or `rk3288-az01-ada2-c.dtb` (RK3288 vs RK3288-C
   boards), so the rootfs carries both.
5. Kernel command line comes from the U-Boot environment:
   `root=PARTUUID=24d1deac-... rootwait ro console=ttyS2,115200 ...`, plus
   whatever the script appends, plus `isolcpus=2-3` built into the kernel.
6. If loading fails, U-Boot prints "Boot failed, resetting to
   bootloader..." and resets into the bootloader.

## eMMC partitions (GPT, `mmcblk0`)

| # | Name | Size | Contents |
|---|---|---|---|
| 1 | uboot-spl | 64 KiB | U-Boot SPL. **Never write.** |
| 2 | env | 8 KiB | U-Boot environment. **Never write.** |
| 3 | uboot | 384 KiB | U-Boot. **Never write.** |
| 4 | splash | 4 MiB | boot splash image |
| 5 | recoverysplash | 4 MiB | recovery splash image |
| 6 | rootfs | 500 MiB | ext4, read-only root filesystem, bootable flag. **The kit writes only this.** |
| 7 | synths | 1 GiB | ext4, stock plugin content |
| 8 | data | rest (~5.8 GiB) | ext4, user data (projects, samples) |

There is one rootfs, no A/B slots. The SD card is `mmcblk1`.

## AZ01 v1 update image

Used by gen1 3.x updates (`Force-3.10.0-update.img`). All integers are
little-endian.

- `str` = u32 length (without the NUL), the bytes, a NUL, zero padding up
  to a multiple of 4.
- `blob` = u32 length, the bytes, zero padding up to a multiple of 4.

File header:

| Field | Type | Example (Force) |
|---|---|---|
| magic | char[4] | `AZ01` |
| format version | u32 | 1 |
| header length | u32 | 0x74 (offset just past the description) |
| version string | str | `SNAPSHOT-20261014151952` |
| compatibles | u32 n, n × str | `inmusic,ada2` |
| update-mode USB ids | u32 m, m × u32 (VID<<16 \| PID) | `09e8:4040` |
| description | str | `Akai Professional Force upgrade image` |

Zero padding up to a multiple of 8, then records. Each record starts with
a 16-byte prefix: tag (char[4]), header length (u32, from the tag to the
first payload byte), payload length (u64).

- `PART`: then partition name (str, a GPT partition label such as
  `rootfs`), compression (str, `xz`), hash count (u32), and per hash an
  algorithm (str, `sha1` or `sha256`) and value (blob). Then the payload.
  The next record starts at the next multiple of 8.
- `EOF\0`: header length 16, payload length 0. Always the last 16 bytes.

**The hash covers the compressed payload bytes only.** No signature.

The MPC gen1 image accepts the compatibles `acv5 acv8 acva acva2 acvb acvm
acvr acv5s` and USB ids `09e8:403a 403b 4046 4047 404b 4052 4056 4057`.

`tools/az0x_img.py` reads, checks, unpacks and creates these images.

### Newer formats

The updater also knows signed "v2/v3" images: FDT based, `sha256,rsa2048`,
keys in `/usr/lib/az0x/pubkeys`. Gen1 3.10 images don't use them, but a
future official update could start requiring them. See
[RECOVERY.md](RECOVERY.md).

## How the stock updater applies an image

`az01-update --file <img>` checks the image, then kexecs the kernel with
`/opt/ramfs-update.squashfs` as a ramdisk. The ramdisk checks the hashes
and writes each `PART` to the GPT partition with that name. It refuses to
run unless the device is on mains power. `az01-update --usb` reboots into
USB update mode.

## Running system notes

- **LoadPin is enforcing** in the stock kernel: kernel modules and firmware
  only load from the filesystem the first one came from (the rootfs). The
  kit keeps all modules and firmware on the rootfs.
- Stock root filesystem: Yocto 5.0 (scarthgap), systemd, kernel
  6.18.26-az01 PREEMPT_RT. The kit uses BusyBox init instead.
- Stock app start: `acvs.service` runs `/usr/bin/az01-launch-MPC`, which
  updates the control surface MCU firmware if it is in DFU mode, then runs
  `/usr/bin/MPC`.
- Pads, buttons, knobs and the Force's own audio interface are USB devices
  on an internal hub (`09e8:0040 Akai Pro Force`): a USB audio card and
  three MIDI ports. The touchscreen is an ILI2116 on I2C, the display a
  800x1280 DSI panel (`/dev/fb0`, `/dev/dri/card0`), the on-board codec is
  card `ADA2`. Wi-Fi/BT is Broadcom (brcmfmac SDIO).
