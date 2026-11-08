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
udevadm settle 2>/dev/null || true

# Wait for the partition's block device. Writing before it exists would
# make dd create a plain file in /dev instead.
PART="${DEV}1"
n=0
while [ ! -b "$PART" ] && [ $n -lt 20 ]; do
	sleep 0.5
	n=$((n + 1))
done
if [ -e "$PART" ] && [ ! -b "$PART" ]; then
	echo "$PART exists but is not a block device (left over from an earlier run?)."
	echo "Remove it with: sudo rm $PART   then run this again."
	exit 1
fi
[ -b "$PART" ] || { echo "$PART did not appear; replug the stick and try again"; exit 1; }

dd if="$IMG" of="$PART" bs=4M conv=fsync status=progress
sync

PARTUUID=$(blkid -s PARTUUID -o value "$PART")
echo
echo "Done. Stick PARTUUID: $PARTUUID"
echo "Next: tools/kexec-test-boot.sh <device-ip> <images-dir> $PARTUUID"
