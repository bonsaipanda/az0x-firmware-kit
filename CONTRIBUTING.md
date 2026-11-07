# Contributing

## Adding a device

1. Collect reference data from the device running stock firmware, read-only
   (see `gen1/force/reference/` for what we collect and how).
   Remove serial numbers and MAC addresses before committing.
2. Copy the nearest device folder (for gen1, start from `gen1/force`) and
   change the device tree name, kernel config and partition notes.
3. Add the device to `DEVICES` in the top-level `Makefile`.
4. Say in the device's README what you tested on real hardware.

## Rules

- No inMusic or Akai proprietary files: no stock firmware images, no
  binaries copied from the device, no keys, no app content, no logos.
  Text you collect from a device (kernel config, partition table, boot
  script, device tree) is fine.
- Never ask people to write the bootloader partitions. The kit only writes
  `rootfs`.
- Keep the kit app-neutral. App-specific things belong in the app's own
  repository.
