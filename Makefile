# az0x-firmware-kit: thin wrapper around Buildroot.
#
#   make force                 configure (first time) and build gen1/force
#   make mpc-live              configure (first time) and build gen1/mpc-live
#   make force-menuconfig      any Buildroot target, for that device
#   make force-linux-menuconfig, force-savedefconfig, force-clean, ...
#
# Buildroot itself is cloned (pinned) into .buildroot/ on first use.
# Each device builds into output/<device>/; images land in output/<device>/images/.

BR_VERSION ?= 2026.02.3
BR_URL     ?= https://gitlab.com/buildroot.org/buildroot.git
BR_DIR     ?= $(CURDIR)/.buildroot/$(BR_VERSION)
OUT_ROOT   ?= $(CURDIR)/output

# device name -> folder holding its buildroot.defconfig
DEVICES      := force mpc-live mixstream-pro
DIR_force    := gen1/force
DIR_mpc-live := gen1/mpc-live
DIR_mixstream-pro := gen1/mixstream-pro

.PHONY: all help buildroot test $(DEVICES)
all: help

help:
	@echo "Devices: $(DEVICES)"
	@echo "  make <device>              configure (first time) and build"
	@echo "  make <device>-<target>     run a Buildroot target, e.g. force-menuconfig"
	@echo "  make test                  run the host-side tool tests"
	@echo "Images: $(OUT_ROOT)/<device>/images/"

$(BR_DIR)/Makefile:
	git clone --depth 1 -b $(BR_VERSION) $(BR_URL) $(BR_DIR)

buildroot: $(BR_DIR)/Makefile

test:
	python3 -I tools/test_az0x_img.py

define device_rules
# Re-run defconfig whenever the device's defconfig changes, so edits to it
# always reach an existing output dir (menuconfig changes are then replaced;
# save them with <device>-savedefconfig first).
$(OUT_ROOT)/$(1)/.config: $(CURDIR)/$(DIR_$(1))/buildroot.defconfig | $(BR_DIR)/Makefile
	$$(MAKE) -C $(BR_DIR) O=$(OUT_ROOT)/$(1) BR2_EXTERNAL=$(CURDIR) \
		BR2_DEFCONFIG=$(CURDIR)/$(DIR_$(1))/buildroot.defconfig defconfig

$(1): $(OUT_ROOT)/$(1)/.config
	$$(MAKE) -C $(OUT_ROOT)/$(1)

$(1)-%: $(OUT_ROOT)/$(1)/.config
	$$(MAKE) -C $(OUT_ROOT)/$(1) $$*
endef
$(foreach d,$(DEVICES),$(eval $(call device_rules,$(d))))
