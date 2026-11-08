# Test-boot without flashing

Before you flash anything, you can boot a kit build from a USB stick
while the device keeps its stock firmware. Nothing is written to the
device's eMMC. Power-cycle the device and it's back on stock.

How it works: the stock system already has `kexec`, which starts another
kernel without going through the bootloader. We load the kit kernel from
`/tmp`, reuse the running device tree, and point the kernel at the root
filesystem on the stick.

## You need

- A kit build (`make force`).
- SSH access as root to the device on stock firmware.
- A USB stick you can erase (1 GB is plenty).
- Optional: a network cable. Ethernet comes up by DHCP on its own.

## Steps

1. **Bake your SSH key and Wi-Fi firmware into the build**, so you can log
   in to the test system:

   ```sh
   mkdir -p ~/az0x-firmware/brcm
   scp 'root@<device-ip>:/lib/firmware/brcm/*.txt' ~/az0x-firmware/brcm/
   AZ0X_SSH_AUTHORIZED_KEYS=~/.ssh/id_ed25519.pub \
   AZ0X_EXTRA_FIRMWARE=~/az0x-firmware make force
   ```

2. **Optional, for Wi-Fi:** put a `wpa_supplicant.conf` on the device's data
   partition (the stock system mounts it at `/data`):

   ```sh
   ssh root@<device-ip> 'mkdir -p /data/az0x && cat > /data/az0x/wpa_supplicant.conf' <<'EOF'
   ctrl_interface=/run/wpa_supplicant
   network={
       ssid="YourNetwork"
       psk="YourPassword"
   }
   EOF
   ```

3. **Write the stick** on your PC (this erases it):

   ```sh
   sudo tools/make-test-stick.sh /dev/sdX output/force/images/rootfs.ext4
   ```

   It prints the stick's PARTUUID.

4. **Plug the stick into the device** and boot it:

   ```sh
   tools/kexec-test-boot.sh <device-ip> output/force/images <partuuid>
   ```

5. After about 30 seconds the device should show the kit's console on its
   screen, and `ssh root@<device-ip>` should work. The IP may change,
   because the test system asks DHCP for its own address.

6. **Back to stock:** power-cycle the device.

## What to check

```sh
cat /etc/az0x-kit-release
dmesg | grep -i -E 'error|fail|loadpin|firmware'
cat /proc/asound/cards; amidi -l
cat /proc/bus/input/devices
ip addr
```
