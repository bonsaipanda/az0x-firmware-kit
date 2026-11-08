################################################################################
#
# az0x-tools: small device helpers (az0x-reboot)
#
################################################################################

AZ0X_TOOLS_VERSION = local
AZ0X_TOOLS_SITE = $(BR2_EXTERNAL_AZ0X_PATH)/package/az0x-tools/src
AZ0X_TOOLS_SITE_METHOD = local

define AZ0X_TOOLS_BUILD_CMDS
	$(TARGET_CC) $(TARGET_CFLAGS) $(TARGET_LDFLAGS) -Wall \
		-o $(@D)/az0x-reboot $(@D)/az0x-reboot.c
endef

define AZ0X_TOOLS_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/az0x-reboot $(TARGET_DIR)/usr/sbin/az0x-reboot
endef

$(eval $(generic-package))
