# gen1: Rockchip RK3288 devices

Akai Force, MPC Live, MPC Live II, MPC X, MPC X SE, MPC One, MPC One+,
MPC Key 37, MPC Key 61. All use a Rockchip RK3288 (4x Cortex-A17, 32-bit
ARM), eMMC storage and the same boot chain. See
[docs/BOOT_CHAIN.md](../docs/BOOT_CHAIN.md).

| Folder | Device | Device tree compatible | Tested |
|---|---|---|---|
| [force](force) | Akai Force | `inmusic,ada2` | not yet |
| [mpc-live](mpc-live) | MPC Live | `inmusic,acv5`? | not yet |

Each gen1 MPC model has its own device tree, so each gets its own folder.
The official MPC update image accepts these compatibles: acv5, acv8, acva,
acva2, acvb, acvm, acvr, acv5s. Which model is which isn't confirmed yet.

## What's shared

`common/` holds what all gen1 devices use:

- `boot.cmd`: the U-Boot script, compiled to `/boot/boot.scr.uimg`
- `linux.fragment`: kernel options the kit adds on top of each device's config
- `rootfs-overlay/`: init setup and the app launcher
- `post-build.sh`, `post-image.sh`: Buildroot hooks
