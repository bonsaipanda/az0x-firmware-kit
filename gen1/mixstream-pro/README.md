# Numark MixStream Pro (gen1 family)

> Draft. Not built or tested on hardware yet.

- SoC: RK3288, 2 GB RAM. Board `az05`, device `nh08`.
- Device tree compatible: `inmusic,nh08` (`rk3288-az05-nh08.dtb`; `-nh08s`
  is a variant that may need checking).
- Stock firmware: Engine OS (`MIXSTREAMPRO-*-Update.img`), AZ01 v1, unsigned,
  shared with Denon Prime 4 / Prime 2. The image lists USB ids `15e4:d008`,
  `15e4:d00b` and `15e4:203f`; which one is the MixStream Pro in Update Mode
  is still to be checked (the draft uses `15e4:203f`).
- Same 7" 800x1280 panel and touchscreen as the Force. Audio: `nh08` codec
  plus a TAS5805M amp for the built-in speakers (kernel modules, already
  in the inMusic kernel config).
- Same U-Boot environment layout and reboot modes as the Force, so
  `az0x-reboot loader` should enter Update Mode.

## Open questions

- Button combination for Update Mode (fastboot) at power-on.
- eMMC partition layout (the kit's fstab assumes `/data` on partition 8).
- How the jog wheels and controls talk to the SoC (own MCUs; USB or UART).

## Caution

The stock Engine OS updater carries Denon/Numark public keys and code for
signed images and for programming secure-boot fuses. Don't install future
official updates on a unit you want to keep open until someone has checked
them.
