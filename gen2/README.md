# gen2: MPC XL, MPC Live III, MPC One G2, MPC Key 37 G2

Not started. We don't have gen2 hardware.

What we know from inMusic's open source release
([branch mpc-g2/3.10](https://github.com/inmusic-software/az0x-open-source/tree/mpc-g2/3.10)):

- 64-bit ARM (aarch64), kernel `linux-imb-6.18.44`.
- Unlike gen1, the release includes the bootloader source
  (`u-boot-imb v2026.07-inmusic`).
- The gen1 updater already contains code for signed ("v3") update images
  and fastboot key commands. Gen2 devices may require signed images.
  Check this first.

If you own a gen2 device and want to help, see
[CONTRIBUTING.md](../CONTRIBUTING.md).
