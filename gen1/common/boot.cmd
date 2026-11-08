# U-Boot script for gen1 az0x devices, compiled to /boot/boot.scr.uimg.
#
# The stock U-Boot finds this script on the bootable "rootfs" partition and
# runs it. U-Boot itself sets ${fdtfile} for the device (for example
# rk3288-az01-ada2.dtb or rk3288-az01-ada2-c.dtb on the Force), and
# ${bootargs} (root=PARTUUID=..., console) comes from the U-Boot
# environment. So the rootfs must carry every device tree the device
# might ask for.
#
# Based on the stock script (gen1/force/reference/boot.cmd).

load ${devtype} ${devnum}:${distro_bootpart} ${kernel_addr_r} ${prefix}zImage || exit
load ${devtype} ${devnum}:${distro_bootpart} ${fdt_addr_r} ${prefix}${fdtfile} || exit

if test "${board_name}" = "az01b"
then
	if load ${devtype} ${devnum}:${distro_bootpart} ${loadaddr} ${prefix}rk3288-az01b.dtbo
	then
		fdt addr ${fdt_addr_r}
		fdt resize
		fdt apply ${loadaddr}
	fi
fi

# Quiet boot by default: no text on the screen, the device's own boot
# picture (splash partition) stays up until the app draws. Messages still
# go to the serial port and /data/az0x/logs.
#
# Verbose boot for development: create /data/az0x/verbose-boot (gen1 keeps
# /data on partition 8). console=tty0 (last, so it becomes /dev/console)
# then shows kernel and init messages on the screen too; fbcon=rotate:3
# turns the text upright on the portrait panels.
setenv bootargs "${bootargs} fsck.repair=yes fbcon=rotate:3"
if test -e ${devtype} ${devnum}:8 /az0x/verbose-boot
then
	setenv bootargs "${bootargs} console=tty0 loglevel=7"
else
	setenv bootargs "${bootargs} quiet loglevel=3 vt.global_cursor_default=0"
fi
bootz ${kernel_addr_r} - ${fdt_addr_r}
