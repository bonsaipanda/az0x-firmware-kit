################################################################################
#
# az0x-tools: small device helpers (az0x-reboot, az0x-img, az0x-update)
#
################################################################################

AZ0X_TOOLS_VERSION = local
AZ0X_TOOLS_SITE = $(BR2_EXTERNAL_AZ0X_PATH)/package/az0x-tools/src
AZ0X_TOOLS_SITE_METHOD = local

define AZ0X_TOOLS_BUILD_CMDS
	$(TARGET_CC) $(TARGET_CFLAGS) $(TARGET_LDFLAGS) -Wall \
		-o $(@D)/az0x-reboot $(@D)/az0x-reboot.c
	$(TARGET_CC) $(TARGET_CFLAGS) $(TARGET_LDFLAGS) -Wall \
		-D_FILE_OFFSET_BITS=64 -o $(@D)/az0x-img $(@D)/az0x-img.c
endef

define AZ0X_TOOLS_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/az0x-reboot $(TARGET_DIR)/usr/sbin/az0x-reboot
	$(INSTALL) -D -m 0755 $(@D)/az0x-img $(TARGET_DIR)/usr/bin/az0x-img
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_AZ0X_PATH)/package/az0x-tools/scripts/az0x-update \
		$(TARGET_DIR)/usr/sbin/az0x-update
	for f in update-stage2; do \
		$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_AZ0X_PATH)/package/az0x-tools/scripts/$$f \
			$(TARGET_DIR)/usr/libexec/az0x/$$f || exit 1; \
	done
endef

$(eval $(generic-package))
