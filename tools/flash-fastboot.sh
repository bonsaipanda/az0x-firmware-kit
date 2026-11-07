#!/bin/sh
# Flash a kit-built rootfs to a gen1 device in fastboot recovery mode.
#
#   tools/flash-fastboot.sh output/force/images/rootfs.ext4
#
# Writes ONLY the "rootfs" partition. Never touches the bootloader,
# its environment, or the data partition. See docs/RECOVERY.md for how to
# start the device in fastboot mode.
set -eu

IMG=${1:-}
if [ -z "$IMG" ] || [ ! -f "$IMG" ]; then
	echo "usage: $0 path/to/rootfs.ext4"
	exit 1
fi
command -v fastboot >/dev/null || {
	echo "fastboot not found. Install it (Debian/Ubuntu: sudo apt install fastboot)."
	exit 1
}

MAX=$((500 * 1024 * 1024))
SIZE=$(stat -c %s "$IMG")
[ "$SIZE" -le "$MAX" ] || { echo "$IMG is larger than the 500 MiB rootfs partition"; exit 1; }

echo "Waiting for a device in fastboot mode..."
fastboot devices | grep -q . || { echo "No fastboot device found. See docs/RECOVERY.md."; exit 1; }
fastboot devices

printf 'Flash %s to the "rootfs" partition? Type yes: ' "$IMG"
read -r answer
[ "$answer" = yes ] || { echo "Cancelled."; exit 1; }

fastboot flash rootfs "$IMG"
echo "Done. Reboot the device (fastboot reboot, or power cycle)."
