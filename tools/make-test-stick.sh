#!/bin/sh
# Write a kit rootfs to a USB stick for a test boot (see docs/TEST_BOOT.md).
#
#   sudo tools/make-test-stick.sh /dev/sdX output/force/images/rootfs.ext4
#
# ERASES the whole stick. Refuses anything that isn't a removable USB disk.
set -eu

DEV=${1:-}
IMG=${2:-}
if [ -z "$DEV" ] || [ -z "$IMG" ] || [ ! -b "$DEV" ] || [ ! -f "$IMG" ]; then
	echo "usage: sudo $0 /dev/sdX path/to/rootfs.ext4"
	exit 1
fi
[ "$(id -u)" = 0 ] || { echo "run with sudo"; exit 1; }

name=$(basename "$DEV")
case "$name" in
	sd[a-z]) ;;
	*) echo "$DEV: give the whole disk, like /dev/sdb (not a partition)"; exit 1 ;;
esac
[ "$(cat "/sys/block/$name/removable" 2>/dev/null)" = 1 ] ||
	{ echo "$DEV is not a removable disk; refusing"; exit 1; }
readlink -f "/sys/block/$name" | grep -q /usb ||
	{ echo "$DEV is not on USB; refusing"; exit 1; }
if grep -q "^/dev/$name" /proc/mounts; then
	echo "$DEV has mounted partitions; unmount them first"
	exit 1
fi

lsblk -o NAME,SIZE,MODEL,VENDOR "$DEV"
printf 'ERASE everything on %s and write %s? Type yes: ' "$DEV" "$IMG"
read -r answer
[ "$answer" = yes ] || { echo "Cancelled."; exit 1; }

# One GPT partition, big enough for the image.
SIZE_MIB=$(( ($(stat -c %s "$IMG") + 1048575) / 1048576 + 8 ))
wipefs -a "$DEV" >/dev/null
printf 'label: gpt\nstart=2048, size=%sMiB, name=az0x-rootfs\n' "$SIZE_MIB" | sfdisk -q "$DEV"
partprobe "$DEV" 2>/dev/null || true
sleep 2
dd if="$IMG" of="${DEV}1" bs=4M conv=fsync status=progress
sync

PARTUUID=$(blkid -s PARTUUID -o value "${DEV}1")
echo
echo "Done. Stick PARTUUID: $PARTUUID"
echo "Next: tools/kexec-test-boot.sh <device-ip> <images-dir> $PARTUUID"
