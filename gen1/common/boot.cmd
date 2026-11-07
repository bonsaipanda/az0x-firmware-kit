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

# fbcon=rotate:1 turns the boot console upright on the portrait panels.
setenv bootargs "${bootargs} fsck.repair=yes fbcon=rotate:1"
bootz ${kernel_addr_r} - ${fdt_addr_r}
