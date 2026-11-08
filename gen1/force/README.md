# Akai Force (gen1)

- Device tree compatible: `inmusic,ada2` (board `az01`, RK3288 or RK3288-C)
- Device trees: `rk3288-az01-ada2.dtb`, `rk3288-az01-ada2-c.dtb`
- Update-mode USB id: `09e8:4040`
- Reference data from a Force on 3.10: [reference/](reference)

## Status

| What | Status |
|---|---|
| Buildroot config | done; `make defconfig` passes |
| Full build | works (2026-11-07): rootfs uses ~80 MiB, update image 14 MiB |
| Boots on hardware | yes (2026-11-08, flashed with fastboot): boot messages on screen, hello app runs |
| Display, touch | console on screen; touchscreen (ILI2116) and buttons show up as inputs |
| Pads/knobs/audio (internal USB) | ALSA cards "Akai Pro Force" + "ADA2", MIDI ports Force Public/Private/MIDI Port (2026-11-08) |
| Ethernet + SSH | works (2026-11-08) |
| Wi-Fi | firmware loads; 0.1.0 never started wpa_supplicant (bad `-s` flag), fixed after 0.1.0; radios also start rfkill-blocked (unblocked in S41 since this fix). Needs the board's NVRAM file, see below |
| USB cable to computer | works (2026-11-08): create `/data/az0x/usb-to-computer` and the rear port goes to the computer at boot (serial console + `ssh root@10.55.0.1`) |

## Build

```sh
make force
```

## Wi-Fi firmware

linux-firmware has the Broadcom firmware, but not the board-specific NVRAM
`.txt` files. Copy them from your own device (`/lib/firmware/brcm/*.txt`)
into a folder and build with:

```sh
AZ0X_EXTRA_FIRMWARE=/path/to/folder make force
```

Lay out the folder like `/lib/firmware` (so `brcm/brcmfmac43455-sdio.txt`).

## SSH for development

```sh
AZ0X_SSH_AUTHORIZED_KEYS=~/.ssh/id_ed25519.pub make force
```
