################################################################################
#
# az0x-rk-vcodec: Rockchip's MPP encoder driver (RK3288 VEPU1) as a kernel module
#
################################################################################

AZ0X_RK_VCODEC_VERSION = 1.0
AZ0X_RK_VCODEC_SITE = $(AZ0X_RK_VCODEC_PKGDIR)/src
AZ0X_RK_VCODEC_SITE_METHOD = local
AZ0X_RK_VCODEC_LICENSE = GPL-2.0+ or MIT

$(eval $(kernel-module))
$(eval $(generic-package))
