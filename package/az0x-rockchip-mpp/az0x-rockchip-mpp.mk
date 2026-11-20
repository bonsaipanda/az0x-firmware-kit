################################################################################
#
# az0x-rockchip-mpp: Rockchip's MPP library (user side of the video codecs)
#
################################################################################

AZ0X_ROCKCHIP_MPP_VERSION = 9b56348cc61393c84662e6d6dd78feae67773a36
AZ0X_ROCKCHIP_MPP_SITE = https://github.com/rockchip-linux/mpp.git
AZ0X_ROCKCHIP_MPP_SITE_METHOD = git
AZ0X_ROCKCHIP_MPP_LICENSE = Apache-2.0, MIT
AZ0X_ROCKCHIP_MPP_LICENSE_FILES = LICENSES/Apache-2.0 LICENSES/MIT
AZ0X_ROCKCHIP_MPP_INSTALL_STAGING = YES
AZ0X_ROCKCHIP_MPP_CONF_OPTS = \
	-DRKPLATFORM=ON \
	-DHAVE_DRM=ON \
	-DBUILD_TEST=ON

# Only the library and the encoder test program go on the device.
define AZ0X_ROCKCHIP_MPP_INSTALL_TARGET_CMDS
	cp -a $(AZ0X_ROCKCHIP_MPP_BUILDDIR)/mpp/librockchip_mpp.so* $(TARGET_DIR)/usr/lib/
	$(INSTALL) -D -m 0755 $(AZ0X_ROCKCHIP_MPP_BUILDDIR)/test/mpi_enc_test $(TARGET_DIR)/usr/bin/mpi_enc_test
endef

$(eval $(cmake-package))
