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
| Boots on hardware | first install 2026-11-08: installs via stock "USB Drive Update", reboots to a blinking cursor, not reachable on network yet |
| Display, touch | not tested |
| Pads/knobs/audio (internal USB) | not tested |
| Wi-Fi | needs the board's NVRAM file (`brcmfmac4339-sdio.txt` or `brcmfmac43455-sdio.txt`), see below |

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
