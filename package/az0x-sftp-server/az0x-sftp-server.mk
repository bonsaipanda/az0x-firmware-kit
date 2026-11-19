################################################################################
#
# az0x-sftp-server: OpenSSH's sftp-server alone, for dropbear's SFTP subsystem
#
################################################################################

AZ0X_SFTP_SERVER_VERSION = $(OPENSSH_VERSION)
AZ0X_SFTP_SERVER_SOURCE = openssh-$(OPENSSH_VERSION).tar.gz
AZ0X_SFTP_SERVER_SITE = $(OPENSSH_SITE)
AZ0X_SFTP_SERVER_DL_SUBDIR = openssh
AZ0X_SFTP_SERVER_LICENSE = BSD-3-Clause, BSD-2-Clause, Public Domain
AZ0X_SFTP_SERVER_LICENSE_FILES = LICENCE
AZ0X_SFTP_SERVER_CONF_OPTS = --without-openssl --with-zlib=no --without-zlib-version-check --disable-strip

define AZ0X_SFTP_SERVER_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D) sftp-server
endef

define AZ0X_SFTP_SERVER_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/sftp-server $(TARGET_DIR)/usr/libexec/sftp-server
endef

$(eval $(autotools-package))
