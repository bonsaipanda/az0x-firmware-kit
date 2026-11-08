/*
 * az0x-reboot: restart the device with a reboot argument.
 *
 *   az0x-reboot loader    restart into Update Mode (fastboot), like the
 *                         stock "Switch to Update Mode"
 *   az0x-reboot           plain restart
 *
 * The kernel's reboot-mode driver turns the argument into a magic value
 * that the stock U-Boot reads on the next boot. Nothing is written to
 * disk, so the boot after that is a normal one again.
 */
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <sys/reboot.h>
#include <sys/syscall.h>
#include <linux/reboot.h>

int main(int argc, char **argv)
{
	const char *arg = argc > 1 ? argv[1] : NULL;

	if (arg && (!strcmp(arg, "-h") || !strcmp(arg, "--help"))) {
		printf("usage: az0x-reboot [loader|bootloader|recovery]\n");
		return 0;
	}
	sync();
	if (arg)
		syscall(SYS_reboot, LINUX_REBOOT_MAGIC1, LINUX_REBOOT_MAGIC2,
			LINUX_REBOOT_CMD_RESTART2, arg);
	else
		reboot(RB_AUTOBOOT);
	perror("az0x-reboot");
	return 1;
}
