# On-device updates

> Tested on the Force (2026-11-08): kit -> kit in ~45 s, kit -> stock 3.10.

The device can install another firmware image by itself, without a
computer: a kit build, or a stock image to go back to stock. An app (for
example a "Firmware" page) only has to call one command.

```sh
az0x-update --check /media/usb/Force-3.10.0-update.img   # check only
az0x-update /media/usb/Force-3.10.0-update.img           # install
```

The image can be on a USB stick, an SD card or `/data`.

## How it works

The running system lives on the `rootfs` partition, so it can't overwrite
it while it runs. Stock solves this with Akai's own updater (a closed
program, started with kexec), which the kit can't ship or use. The kit
does it like this instead:

1. **`az0x-update IMAGE` (normal system)** checks the image: AZ01 v1
   format, made for this device (device-tree compatible), SHA-1 of the
   rootfs payload. Then it builds a tiny RAM system in `/run/az0x-update`
   (BusyBox, its libraries, `az0x-reboot`) and sends init `SIGQUIT`.
2. **BusyBox init** runs the shutdown steps (services stop, disks become
   read-only), stops every process, and runs its `restart` action,
   `/usr/libexec/az0x/restart`. That switches PID 1 into the RAM system
   (`chroot`), so nothing uses the `rootfs` partition any more.
3. **The RAM updater** (`/usr/libexec/az0x/update-stage2`) mounts the disk
   with the image again, checks the SHA-1 again, and streams the payload
   (`unxz`) onto the partition the system booted from. Progress is shown on
   the screen and logged to `/data/az0x/logs/update.log`. Then it restarts
   into the new system.

If anything fails before writing starts, it restarts into the old system.
If writing fails halfway, it restarts into Update Mode so a computer can
reflash the device.

## Update Mode from software

`az0x-reboot loader` restarts into the same Update Mode as MATRIX + LOAD +
SAVE (tested on the Force). An app can offer it as "Restart into Update
Mode" for people who update from a computer.

## Safety

- Only the partition the system booted from is written. U-Boot, its
  settings and `/data` are never written (except the update log).
- **Power loss while writing** leaves a half-written system. U-Boot is
  untouched, so Update Mode (button combo) and a reflash from a computer
  still work. Apps should not start an update on battery power (MPC Live).
- Stock images newer than AZ01 v1 (signed) are refused.

## Alternative for later: A/B slots

Writing a second system partition while the old one keeps running would
survive power loss better, but takes over the 1 GiB `synths` partition that
stock uses. It can be added later on top of the same checks.
