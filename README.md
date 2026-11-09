# az0x-firmware-kit

Build your own minimal Linux firmware for inMusic "az0x" hardware (Akai
Professional MPC and Force), one that boots straight into a single
application of your choice, with none of the stock software on it.

It is a [Buildroot](https://buildroot.org) external tree. You get a small
root filesystem with the kernel from
[inMusic's open source release](https://github.com/inmusic-software/az0x-open-source),
the right device tree and boot script for your device, ALSA, Wi-Fi and SSH
for development, and your app started (and restarted) at boot.

> **Unofficial.** This project is not made, endorsed or supported by
> inMusic or Akai Professional. Flashing custom firmware is at your own
> risk. Read [docs/RECOVERY.md](docs/RECOVERY.md) before you flash anything.

## Status

| Folder | Devices | Status |
|---|---|---|
| [gen1/force](gen1/force) | Akai Force | being brought up |
| [gen1/mpc-live](gen1/mpc-live) | MPC Live (gen 1) | being brought up |
| [gen1](gen1) | MPC X, Live II, One, One+, Key 37/61 | not started, help wanted |
| [gen2](gen2) | MPC XL, Live III, One G2, Key 37 G2 | not started, help wanted |

We can only test on hardware we own. If you have another device, see
[CONTRIBUTING.md](CONTRIBUTING.md).

## Layout

```
gen1/                    1st generation (Rockchip RK3288, 32-bit ARM)
  common/                shared by all gen1 devices: boot script, rootfs overlay, scripts
  force/                 Akai Force: Buildroot config, kernel config, device notes
  mpc-live/              MPC Live: same
gen2/                    2nd generation (64-bit ARM), not started
package/az0x-app/        Buildroot package that installs "the app"
app/hello/               example app; replace with your own
tools/                   host tools: AZ01 update-image packer, fastboot flashing
docs/                    boot chain, recovery, licensing
```

## Quick start

On a Linux PC with the usual
[Buildroot requirements](https://buildroot.org/downloads/manual/manual.html#requirement):

```sh
make force          # or: make mpc-live
```

The first build takes an hour or more. You get, in `output/force/images/`:

- `rootfs.ext4`: the root filesystem (kernel, device tree and boot script are inside `/boot`)
- `force-update.img`: the same, wrapped as an AZ01 update image

## Using your own app

Your app is a source folder with a Makefile. `make` builds it, and
`make install DESTDIR=...` must install an executable `/opt/app/start`.
Point the build at it:

```sh
make force-menuconfig     # az0x firmware kit -> application source directory
```

or set `BR2_PACKAGE_AZ0X_APP_SOURCE_DIR` in your own copy of the device's
`buildroot.defconfig`. See [app/hello](app/hello) for the smallest example.

### USB sound cards for your app

The device's USB port can also show up on the computer as sound cards (USB
Audio Class 2: no driver needed on Linux, macOS or Windows 10+), each its own
device, for example for OBS. List them in `/data/az0x/usb-audio`, one per
line, and reboot:

```
# id     channels  rates               name on the computer
mix      2         44100,48000,96000   Djaia Full Mix
master   2         44100,48000,96000   Djaia Master
```

They only send (device to computer), 32-bit, at the rate the computer picks.
On the device each is an ALSA card (`UAC2Gadget`); `/run/az0x/usb-audio`
says which card number each id got. Your app plays into it and corrects for
the drift between its own sound card's clock and the USB clock (the card's
`Playback Pitch 1000000` control, or resampling). The RK3288 has room for 2
such cards next to the USB serial port and network; more lines are skipped.

## Flashing

See [docs/RECOVERY.md](docs/RECOVERY.md). In short: start the device in
fastboot recovery mode and flash `rootfs.ext4` to the `rootfs` partition
with `tools/flash-fastboot.sh`. Only the root filesystem is written. The
bootloader and your `data` partition stay as they are.

## How it works

[docs/BOOT_CHAIN.md](docs/BOOT_CHAIN.md) describes what we found out about
the boot process, partitions and the update image format.

## License

The kit's own files are MIT licensed (see [LICENSE](LICENSE)). Images you
build contain GPL software (Linux, BusyBox and others). If you distribute
images, see [docs/LICENSING.md](docs/LICENSING.md).
