################################################################################
#
# az0x-app: the single application the firmware boots into
#
################################################################################

AZ0X_APP_VERSION = local
AZ0X_APP_SITE = $(call qstrip,$(BR2_PACKAGE_AZ0X_APP_SOURCE_DIR))
AZ0X_APP_SITE_METHOD = local
AZ0X_APP_DEPENDENCIES = alsa-lib

define AZ0X_APP_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) $(TARGET_CONFIGURE_OPTS) -C $(@D)
endef

define AZ0X_APP_INSTALL_TARGET_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) $(TARGET_CONFIGURE_OPTS) -C $(@D) \
		DESTDIR=$(TARGET_DIR) install
	test -x $(TARGET_DIR)/opt/app/start || \
		{ echo "az0x-app: the app must install an executable /opt/app/start"; exit 1; }
endef

$(eval $(generic-package))
