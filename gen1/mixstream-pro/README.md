# Numark MixStream Pro (gen1 family)

> Draft. Not built or tested on hardware yet.

- SoC: RK3288, 2 GB RAM. Board `az05`, device `nh08`.
- Device tree: `rk3288-az05-nh08.dtb`, model "Numark MIXSTREAM PRO",
  compatible `inmusic,nh08`. `-nh08s` is the sibling for the MixStream Pro
  variants (Engine knows "NH08S": MixStream Pro+ / Pro Go); both are built,
  U-Boot picks one through `${fdtfile}`.
- Stock firmware: Engine OS (`MIXSTREAMPRO-*-Update.img`), AZ01 v1, unsigned,
  one image for Denon Prime 4 (`jc11`), Prime 2 (`jc16`) and MixStream Pro
  (`nh08`). Partitions in the image: `splash`, `recoverysplash` (raw
  800x1280, 4 bytes per pixel, like the Force) and `rootfs`. Stock kernel
  6.18.57-az01 (PREEMPT_RT, LoadPin), the same inMusic tree the kit uses.
- USB ids in the image header: `15e4:d008`, `15e4:d00b`, `15e4:203f`. Seen
  on the device: in Update Mode the MixStream Pro is `15e4:203f` ("Numark
  MIXSTREAM PRO", bcdDevice 99.99, one "Android Fastboot" interface).

## Hardware (from the stock device tree and Engine OS)

- Display: the same 7" 800x1280 MIPI-DSI panel as the Force
  (`urt,umo-p076md-t`), touchscreen ILI2116/ILI2117 on I2C.
- Audio: `inmusic,nh08-audio` (nh08 codec + TI TAS5805M amp for the built-in
  speakers). Kernel modules already in the inMusic config. The amp's DSP
  needs `/lib/firmware/eta5805-dsp-nh08.bin` (from Engine OS).
- Controls (jog wheels, pads, faders): a separate MCU, "NH08 Controller"
  (Engine flashes it from `/usr/Engine/Firmware/NH08 Controller`). Seen on
  the device with the kit: it is ALSA card "Surface" ("MIDI UART - Control
  Surface"), a rawmidi port `hw:0,0` over a UART, not a USB device.
- Wi-Fi/Bluetooth: Broadcom/Cypress BCM4345 family on SDIO (Engine OS ships
  `brcmfmac43455-sdio` / `brcmfmac43456-sdio` and `BCM4345C0/C5.hcd`).
- Ethernet, RTC hym8563, PMIC act8846. The USB switch (`usb-mux`) only has
  one state ("basic"); there is no Force-style internal/external switch.
- Same reboot modes as the Force (`loader` = 0x5242c301), so
  `az0x-reboot loader` should enter Update Mode.

## Storage

Engine OS mounts `/data` by PARTUUID `9dd41a93-59ad-4908-833a-9bf00af5b60e`,
the same data partition UUID as on the Force, and the same U-Boot
environment location (`/etc/fw_env.config`). The layout is very likely the
same as the Force's (data = partition 8), but check it before relying on
`/dev/mmcblk0p8` in the kit's fstab.

## Firmware files

Like the Force, the proprietary firmware isn't in this repository. Build
with `AZ0X_EXTRA_FIRMWARE=<dir>` holding, copied from the stock Engine OS
image's `/usr/lib/firmware`: `brcm/brcmfmac4345[56]-sdio.{bin,txt}`,
`brcm/BCM4345C0.hcd`, `brcm/BCM4345C5.hcd`, `eta5805-dsp-nh08.bin` and
`ilitek/`.

## Update Mode

Hold Left Deck **CUE + SAVED LOOP + AUTO LOOP** while powering on
(confirmed 2026-11-08). Pressing POWER leaves it again.

## Open questions

- The data partition number on a real unit.
- The control surface's MIDI messages (jog wheels, pads, faders) for an app.

## Caution

The stock Engine OS updater (libaz01-prog 1.8.1) carries Denon/Numark public
keys (`/usr/lib/az0x/pubkeys`) and code for signed images and for programming
secure-boot fuses. Don't install future official updates on a unit you want
to keep open until someone has checked them.
