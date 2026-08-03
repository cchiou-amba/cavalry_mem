###########################################################
## History:
##    2022/08/25 - [Yan Shi] Create
##
## Copyright (c) 2026 Ambarella International LP
##
## License Identifier: AMBARELLA-2-Clause
###########################################################

PACKAGE_NAME = libcavalrymem
PACKAGE_DEPS = generic-header ambcavalry-header
PACKAGE_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)

CAVALRY_MEMVER_PREFIX = MEM
CAVALRY_MEMVERSION_FILE = $(PACKAGE_DIR)/src/mem_ver.h
CAVALRY_MEMSO_VER_MAJOR  := $(shell awk '/define $(CAVALRY_MEMVER_PREFIX)_LIB_MAJOR/{print $$3}' $(CAVALRY_MEMVERSION_FILE))
CAVALRY_MEMSO_VER_MINOR  := $(shell awk '/define $(CAVALRY_MEMVER_PREFIX)_LIB_MINOR/{print $$3}' $(CAVALRY_MEMVERSION_FILE))
CAVALRY_MEMSO_VER_PATCH  := $(shell awk '/define $(CAVALRY_MEMVER_PREFIX)_LIB_PATCH/{print $$3}' $(CAVALRY_MEMVERSION_FILE))

LIBA_NAME = libcavalry_mem.a
LIBSO_NAME = libcavalry_mem.so $(CAVALRY_MEMSO_VER_MAJOR) $(CAVALRY_MEMSO_VER_MINOR) $(CAVALRY_MEMSO_VER_PATCH)
INSTALL_HEADERS = $(PACKAGE_DIR)/inc/*
INSTALL_TODIR_pkgconfig = $(PACKAGE_DIR)/libcavalrymem.pc /usr/lib/pkgconfig

SRC_PATH = $(PACKAGE_DIR)/src
CFLAGS += $(shell echo -DCONFIG_ARCH_$(AMBA_SOC) | tr [:lower:] [:upper:])
CFLAGS += -I$(PACKAGE_DIR)/inc -fvisibility=hidden

.PHONY: all clean install

all:
	@echo "Build $(PACKAGE_NAME) Done."

include $(ENV_MAKE_DIR)/inc.app.mk

all: $(LIB_TARGETS)

clean: clean_objs
	@-rm -f $(LIB_TARGETS)
	@echo "Clean $(PACKAGE_NAME) Done."

install: install_libs install_hdrs install_todir_pkgconfig

