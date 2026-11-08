#!/bin/sh
# Buildroot post-build hook for gen1 devices.
# Args: $1 = target dir, then BR2_ROOTFS_POST_SCRIPT_ARGS:
#       $2 = device name, $3 = DT compatible, $4.. = update-mode USB ids
set -eu

TARGET_DIR=$1
DEVICE=$2
COMMON=$(dirname "$0")

# Boot script: U-Boot looks for /boot/boot.scr.uimg on the rootfs.
"$HOST_DIR/bin/mkimage" -A arm -O linux -T script -C none -n "az0x-kit" \
	-d "$COMMON/boot.cmd" "$TARGET_DIR/boot/boot.scr.uimg"

test -f "$TARGET_DIR/boot/zImage" || { echo "post-build: /boot/zImage missing"; exit 1; }
ls "$TARGET_DIR"/boot/*.dtb >/dev/null 2>&1 || { echo "post-build: no device trees in /boot"; exit 1; }

mkdir -p "$TARGET_DIR/data" "$TARGET_DIR/sdcard"

# SSH host keys persist on the data partition (the rootfs is read-only).
# S41az0x-network creates the folder at boot.
rm -rf "$TARGET_DIR/etc/dropbear"
ln -s /data/az0x/dropbear "$TARGET_DIR/etc/dropbear"

# Optional: extra firmware files (for example the Wi-Fi NVRAM .txt files,
# which are board specific and not in linux-firmware). Copied as-is into
# /lib/firmware. Set AZ0X_EXTRA_FIRMWARE=/path/to/dir when building.
if [ -n "${AZ0X_EXTRA_FIRMWARE:-}" ]; then
	mkdir -p "$TARGET_DIR/lib/firmware"
	cp -a "$AZ0X_EXTRA_FIRMWARE"/. "$TARGET_DIR/lib/firmware/"
fi

# Optional: SSH public keys for root, for development.
# Set AZ0X_SSH_AUTHORIZED_KEYS=/path/to/authorized_keys when building.
if [ -n "${AZ0X_SSH_AUTHORIZED_KEYS:-}" ]; then
	install -D -m 0600 "$AZ0X_SSH_AUTHORIZED_KEYS" "$TARGET_DIR/root/.ssh/authorized_keys"
	chmod 0700 "$TARGET_DIR/root/.ssh"
fi

cat > "$TARGET_DIR/etc/az0x-kit-release" <<EOF
DEVICE=$DEVICE
KIT_VERSION=$(git -C "$BR2_EXTERNAL_AZ0X_PATH" describe --always --dirty 2>/dev/null || echo unknown)
BUILD_DATE=$(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF
