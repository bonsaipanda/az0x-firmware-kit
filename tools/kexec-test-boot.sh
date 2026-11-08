#!/bin/sh
# Test-boot a kit build on a gen1 device WITHOUT writing to its eMMC.
# See docs/TEST_BOOT.md.
#
#   tools/kexec-test-boot.sh <device-ip> <images-dir> <stick-partuuid>
#
# The device must be running stock firmware with SSH (root) access and the
# test stick plugged in. This copies the kit kernel to the device's /tmp,
# loads it with kexec and does a clean reboot into it. The device's own
# device tree is reused. Power-cycling the device returns to stock.
set -eu

IP=${1:-}
IMAGES=${2:-}
PARTUUID=${3:-}
if [ -z "$IP" ] || [ -z "$PARTUUID" ] || [ ! -f "$IMAGES/zImage" ]; then
	echo "usage: $0 <device-ip> <images-dir> <stick-partuuid>"
	exit 1
fi
SSH="ssh ${AZ0X_SSH_OPTS:-} root@$IP"

$SSH "blkid | grep -q 'PARTUUID=\"$PARTUUID\"'" ||
	{ echo "The device doesn't see a partition with PARTUUID $PARTUUID. Is the stick plugged in?"; exit 1; }
$SSH 'command -v kexec >/dev/null' || { echo "kexec not found on the device"; exit 1; }

# shellcheck disable=SC2086
scp ${AZ0X_SSH_OPTS:-} "$IMAGES/zImage" "root@$IP:/tmp/az0x-zImage"

CMDLINE="root=PARTUUID=$PARTUUID rootwait ro console=ttyS2,115200 fbcon=rotate:1"
echo "Loading kernel with: $CMDLINE"
$SSH "kexec -l /tmp/az0x-zImage --command-line='$CMDLINE'"

printf 'Reboot %s into the test system now? Type yes: ' "$IP"
read -r answer
[ "$answer" = yes ] || { $SSH 'kexec -u'; echo "Cancelled, kernel unloaded."; exit 1; }

$SSH 'systemctl kexec' || true
echo "Rebooting into the test system. Give it ~30 s, then: ssh root@$IP"
echo "To go back to stock: power-cycle the device."
