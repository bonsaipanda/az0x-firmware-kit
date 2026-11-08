# Flashing and recovery

> Untested on hardware yet. Until a device README says "tested", treat
> every step here as experimental.

## Before you flash

- **Back up your data partition** (projects, samples). The kit doesn't
  write it, but back it up anyway.
- **Write down your firmware version.** You can go back to stock by
  installing the official update image again.
- **Don't install future official updates on a device you want to keep
  open** until someone has checked them. The stock updater already contains
  code for signed images and for programming secure-boot fuses. If an
  update ever enables that, custom firmware could stop booting for good.

## Flash with fastboot (recommended)

1. Power the device off.
2. Hold the recovery button combination while powering on. U-Boot then
   starts fastboot over USB.
   - **Force:** hold **MATRIX + LOAD + SAVE** at power-on. The Force shows
     up on the PC (via its USB port, through the "Force Hub") as `09e8:4040`
     with an "Android Fastboot" interface. This is the same mode inMusic's
     updater app uses ("Update Mode").
   - Other devices: not known yet.
3. Connect the device's USB port to your PC. `fastboot devices` should list
   it.
4. Run `tools/flash-fastboot.sh output/<device>/images/rootfs.ext4`.
5. `fastboot reboot`.

Only the `rootfs` partition is written. U-Boot, its environment and your
data stay as they are.

## Go back to stock

Flash the stock rootfs the same way. Get it from the official update image:

```sh
tools/az0x_img.py unpack Force-3.10.0-update.img stock/
tools/flash-fastboot.sh stock/rootfs.img
```

## Update Mode (official way back)

inMusic's Update Mode *is* this fastboot mode. Besides flashing a rootfs
yourself, you can run the official Akai updater app (Windows/macOS) while
the device is in it to restore stock firmware, as long as the bootloader
is intact. The kit never writes the bootloader.

## If it doesn't boot

- **The rootfs is bad** (kernel panics, black screen): U-Boot is untouched,
  so fastboot recovery still works. Flash a good rootfs.
- **U-Boot itself is broken**: this can't happen through the kit, which
  never writes the bootloader. If it happens anyway, the RK3288 boot ROM
  has a USB recovery mode (MaskROM, used with `rkdeveloptool`). Getting
  into it may mean opening the case and shorting the eMMC clock. That's the
  last resort.
