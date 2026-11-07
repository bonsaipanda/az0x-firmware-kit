# Source of /boot/boot.scr.uimg on Akai Force (gen1, ada2)
# uImage: 64-byte legacy header (magic 27051956, type=script 0x06, arch=ARM 0x02, os=Linux 0x05, comp=none),
# then 8-byte script-image table (u32 BE length=0x1cf, u32 0 terminator). Text below = bytes 72..end.
# uImage name field: ''


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

setenv bootargs "${bootargs} fsck.repair=yes"
bootz ${kernel_addr_r} - ${fdt_addr_r}
