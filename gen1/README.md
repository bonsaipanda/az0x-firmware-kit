# gen1: Rockchip RK3288 devices

Akai Force, MPC Live, MPC Live II, MPC X, MPC X SE, MPC One, MPC One+,
MPC Key 37, MPC Key 61. All use a Rockchip RK3288 (4x Cortex-A17, 32-bit
ARM), eMMC storage and the same boot chain. See
[docs/BOOT_CHAIN.md](../docs/BOOT_CHAIN.md).

| Folder | Device | Device tree compatible | Tested |
|---|---|---|---|
| [force](force) | Akai Force | `inmusic,ada2` | not yet |
| [mpc-live](mpc-live) | MPC Live | `inmusic,acv5` (probably) | not yet |

Each device has its own device tree (most have a plain and a `-c` variant
for RK3288 vs RK3288-C boards), so each gets its own folder.

## Device trees in inMusic's kernel (6.18.44, mpc-g1/3.10)

Akai devices, from `arch/arm/boot/dts/rockchip/`:

| File | Model string | Compatible |
|---|---|---|
| rk3288-az01-ada2(-c) | Akai Professional Force | `inmusic,ada2` |
| rk3288-az01-mpc-acv5(-c) | InMusic MPC ACV5 | `inmusic,acv5` |
| rk3288-az01-mpc-acv8(-c) | InMusic MPC ACV8 | `inmusic,acv8` |
| rk3288-az01-acv5s | MPC X SE | `inmusic,acv5s` |
| rk3288-az01-acva(-c) | MPC One | `inmusic,acva` |
| rk3288-az01-acvb(-c) | MPC Live Mk 2 | `inmusic,acvb` |
| rk3288-az01-acvm(-c) | MPC Key 61 | `inmusic,acvm` |
| rk3288-az05-acva2 | MPC One+ | `inmusic,acva2` |
| rk3288-az05-acvm | MPC Key 61 | `inmusic,acvm` |
| rk3288-az05-acvr | MPC Key 37 | `inmusic,acvr` |

By elimination, acv5 is most likely the original MPC Live and acv8 the
MPC X. Nothing in the kernel confirms that yet.

The same kernel also carries device trees for other inMusic RK3288
products (Denon Prime / SC series, HeadRush, Alesis, Numark Mixstream).

## What's shared

`common/` holds what all gen1 devices use:

- `boot.cmd`: the U-Boot script, compiled to `/boot/boot.scr.uimg`
- `linux.fragment`: kernel options the kit adds on top of each device's config
- `rootfs-overlay/`: init setup and the app launcher
- `post-build.sh`, `post-image.sh`: Buildroot hooks
