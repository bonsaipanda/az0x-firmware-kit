# On-device updates (design, not built yet)

Goal: the app (for example a "Firmware" page) lets the user pick another
firmware image, kit or stock, and the device installs it by itself, without
a computer.

## Why it needs a separate mode

The running system lives on the `rootfs` partition, so it can't overwrite
that partition while it runs. Stock solves this by kexec'ing an updater
ramdisk; the kit can't (LoadPin blocks kexec). U-Boot runs our
`boot.scr`, though, so the kit lets U-Boot start the updater instead.

## Flow

1. **App stages the update.** It copies the chosen `*-update.img` to
   `/data/az0x/update/update.img`, checks it (`az0x_img`-style: header,
   compatible device, SHA-1 of the payload), and creates
   `/data/az0x/update/pending`. Then it restarts the device normally.
2. **boot.scr picks updater mode.** If `pending` exists on the data
   partition, it loads the normal `zImage` and dtb plus
   `/boot/az0x-updater.cpio.xz` (a small BusyBox initramfs, ~1-2 MiB),
   and boots with that as the initrd.
3. **The updater** (`/init` in the initramfs):
   - shows progress on the screen console;
   - mounts `/data`, verifies `update.img` again;
   - unpacks the rootfs payload (xz) straight onto the `rootfs` partition;
   - reads it back and compares the hash;
   - removes `pending` (keeps a log in `/data/az0x/logs/update-N.log`);
   - restarts into the new system.
4. If the image is bad, it removes `pending`, logs why, and restarts into
   the unchanged old system.

Works the same for stock images (the AZ01 v1 format is the same), so
"go back to stock" is just picking the stock image.

## Safety

- U-Boot, its environment and `/data` are never written.
- **Power loss during step 3** leaves a half-written rootfs, and
  `boot.scr` lives on that partition, so the device can't start the
  updater again by itself. Recovery is Update Mode (MATRIX + LOAD + SAVE)
  plus `tools/flash-fastboot.sh` or the official updater, as today. The app
  should refuse to start an update on battery (MPC Live) below a safe
  level.
- Fastboot / Update Mode stays reachable from software too:
  `az0x-reboot loader` (tested on the Force).

## Alternative considered: A/B slots

Writing the new system into a second partition (the 1 GiB `synths`) while
the old one runs survives power loss better, but takes over a partition
that stock uses, and needs `boot.scr` slot switching plus a fallback
counter. It can be added later on top of the same image checks.
