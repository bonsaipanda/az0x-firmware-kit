# Hardware video encoder (RK3288 VEPU1)

The RK3288 has a hardware video encoder (Rockchip calls it VEPU1, a Hantro H1):
H.264 (up to High profile), VP8 and JPEG. Mainline Linux has no H.264 encoder
driver for it (the stateless encoder API was still under review in 2026), so
the kit uses Rockchip's own driver and library. MixStream Pro only for now.

| Piece | What | Licence |
|---|---|---|
| `package/az0x-rk-vcodec` | Rockchip's MPP kernel driver (`rk_vcodec.ko`), trimmed to VEPU1, ported to the kit's 6.18 kernel. Gives `/dev/mpp_service`. Loaded by udev from the device tree. | GPL-2.0+ or MIT |
| `gen1/common/patches/linux/0002-…` | Device tree: `mpp-srv` and `vepu@ff9a0000` nodes (as in Rockchip's own rk3288.dtsi), `vpu_mmu` enabled. The mainline `video-codec` (hantro) node stays disabled. | GPL-2.0+ or MIT |
| `package/az0x-rockchip-mpp` | Rockchip's MPP library (`librockchip_mpp.so`) plus `mpi_enc_test`. One patch: allocate from the rockchip-drm node (the GPU owns `renderD128`). | Apache-2.0, MIT |

Source of the driver: rockchip-linux/kernel `develop-6.1` (77168c8),
`drivers/video/rockchip/mpp`. Every change is marked `djaia:` in the sources.
The ones that matter:

- **IOMMU.** Mainline rockchip-iommu defers attaching, and the arm32 DMA code
  then never sets up its IOMMU mapping: the device stays in bypass with plain
  DMA, and buffers get the physical address of their first page only. Run like
  that, the encoder writes across RAM (it killed dropbear in the first test).
  The driver now attaches an arm IOMMU mapping itself (IOVAs from 256 MiB),
  lifts the DMA segment limit so a buffer is one IOVA block, and refuses to
  probe, to import a split buffer, or to start a job unless the IOMMU is in
  paging mode (`RK_MMU_STATUS` bit 0, checked before every job).
- Mainline APIs: `dma_buf_*_unlocked`, `fd_file()`, `class_create(name)`,
  `void` remove, one IOMMU fault handler per domain (set once at probe).
- The vendor IOMMU/PMU hooks (`rockchip_iommu_enable/disable`,
  `rockchip_pmu_idle_request`) don't exist in mainline: the IOMMU refresh after
  a reset is a detach + re-attach, the bus idle request is skipped.
- `MPP_CMD_SET_SESSION_FD` only accepts our own session files (the vendor code
  read `private_data` of any file descriptor).

## Trying it

```
mpi_enc_test -w 1280 -h 720 -t 7 -f 0 -o /run/test.h264 -n 300 -rc 1 -bps 2000000 -fps 30 -v f
```

`-t 7` is H.264, `-f 0` NV12 input (a generated test pattern without `-i`),
`-rc 1` constant bitrate. Measured on the MixStream Pro (2026-11-20): 720p
H.264 High at 75 fps sustained for 3600 frames, exactly 2.0 Mbit/s, CPU
temperature unchanged (60-63 °C, same as idle).

## Testing a driver change without flashing

LoadPin only lets modules load from the rootfs and the kernel can't unload
modules, so:

```
echo 0 > /proc/sys/kernel/loadpin/enforce   # until the next reboot
insmod /run/rk_vcodec.ko
```

and reboot between tries.
