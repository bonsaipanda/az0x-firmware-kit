#!/bin/sh
# Buildroot post-image hook for gen1 devices: wraps rootfs.ext4 into an
# AZ01 v1 update image.
# Args: $1 = images dir, then BR2_ROOTFS_POST_SCRIPT_ARGS:
#       $2 = device name, $3 = DT compatible, $4.. = update-mode USB ids
set -eu

IMAGES=$1
DEVICE=$2
COMPAT=$3
shift 3

ROOTFS="$IMAGES/rootfs.ext4"
# The rootfs partition is 500 MiB on gen1 devices.
MAX=$((500 * 1024 * 1024))
SIZE=$(stat -c %s "$ROOTFS")
if [ "$SIZE" -gt "$MAX" ]; then
	echo "post-image: rootfs.ext4 is $SIZE bytes, the rootfs partition holds $MAX"
	exit 1
fi

usb_args=""
for id in "$@"; do
	usb_args="$usb_args --usb-id $id"
done

# Use the build machine's python3, not Buildroot's host-python3: Buildroot
# puts $HOST_DIR/bin first in PATH, and its host-python3 is built without
# the lzma module that az0x_img.py needs.
PYTHON=$(PATH=$(printf '%s' "$PATH" | tr ':' '\n' | grep -v "^${HOST_DIR:-/nonexistent}/" | paste -sd: -) command -v python3) || {
	echo "post-image: no python3 outside $HOST_DIR"
	exit 1
}

VERSION="az0x-kit-$(git -C "$BR2_EXTERNAL_AZ0X_PATH" describe --always --dirty 2>/dev/null || echo unknown)"

# shellcheck disable=SC2086
"$PYTHON" -I "$BR2_EXTERNAL_AZ0X_PATH/tools/az0x_img.py" pack \
	"$IMAGES/$DEVICE-update.img" \
	--version "$VERSION" \
	--compatible "$COMPAT" $usb_args \
	--description "az0x-firmware-kit image for $DEVICE (unofficial)" \
	--part "rootfs=$ROOTFS"

"$PYTHON" -I "$BR2_EXTERNAL_AZ0X_PATH/tools/az0x_img.py" verify "$IMAGES/$DEVICE-update.img"

echo
echo "Images in $IMAGES:"
echo "  rootfs.ext4          flash with: tools/flash-fastboot.sh $IMAGES/rootfs.ext4"
echo "  $DEVICE-update.img   AZ01 update image"
