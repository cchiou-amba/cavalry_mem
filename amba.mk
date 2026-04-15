###########################################################
## History:
##    2022/08/25 - [Yan Shi] Create
##
## Copyright (c) 2022 Ambarella International LP
##
## This file and its contents ("Software") are protected by intellectual
## property rights including, without limitation, U.S. and/or foreign
## copyrights. This Software is also the confidential and proprietary
## information of Ambarella International LP and its licensors. You may not use, reproduce,
## disclose, distribute, modify, or otherwise prepare derivative works of this
## Software or any portion thereof except pursuant to a signed license agreement
## or nondisclosure agreement with Ambarella International LP or its authorized affiliates.
## In the absence of such an agreement, you agree to promptly notify and return
## this Software to Ambarella International LP
##
## This file includes sample code and is only for internal testing and evaluation.  If you
## distribute this sample code (whether in source, object, or binary code form), it will be
## without any warranty or indemnity protection from Ambarella International LP or its affiliates.
##
## THIS SOFTWARE IS PROVIDED "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
## INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF NON-INFRINGEMENT,
## MERCHANTABILITY, AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
## IN NO EVENT SHALL AMBARELLA INTERNATIONAL LP OR ITS AFFILIATES BE LIABLE FOR ANY DIRECT,
## INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
## (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
## LOSS OF USE, DATA, OR PROFITS; COMPUTER FAILURE OR MALFUNCTION; OR BUSINESS
## INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
## CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
## ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
## POSSIBILITY OF SUCH DAMAGE.
###########################################################

#DEPS(amba.mk) libcavalrymem(jobserver): AMBA_SOC!=s6lm &&??generic-header \
	&&??ambcavalry-header

PACKAGE_NAME = libcavalrymem
PACKAGE_DEPS = generic-header ambcavalry-header

CAVALRY_MEMVER_PREFIX = MEM
CAVALRY_MEMVERSION_FILE = src/mem_ver.h
CAVALRY_MEMSO_VER_MAJOR  := $(shell awk '/define $(CAVALRY_MEMVER_PREFIX)_LIB_MAJOR/{print $$3}' $(CAVALRY_MEMVERSION_FILE))
CAVALRY_MEMSO_VER_MINOR  := $(shell awk '/define $(CAVALRY_MEMVER_PREFIX)_LIB_MINOR/{print $$3}' $(CAVALRY_MEMVERSION_FILE))
CAVALRY_MEMSO_VER_PATCH  := $(shell awk '/define $(CAVALRY_MEMVER_PREFIX)_LIB_PATCH/{print $$3}' $(CAVALRY_MEMVERSION_FILE))

LIBA_NAME = libcavalry_mem.a
LIBSO_NAME = libcavalry_mem.so $(CAVALRY_MEMSO_VER_MAJOR) $(CAVALRY_MEMSO_VER_MINOR) $(CAVALRY_MEMSO_VER_PATCH)
INSTALL_HEADERS = inc/*
INSTALL_TODIR_pkgconfig = libcavalrymem.pc /usr/lib/pkgconfig

SRC_PATH = src
CFLAGS += $(shell echo -DCONFIG_ARCH_$(AMBA_SOC) | tr [:lower:] [:upper:])
CFLAGS += -Iinc -fvisibility=hidden

.PHONY: all clean install

all:
	@echo "Build $(PACKAGE_NAME) Done."

include $(ENV_MAKE_DIR)/inc.app.mk

all: $(LIB_TARGETS)

clean: clean_objs
	@-rm -f $(LIB_TARGETS)
	@echo "Clean $(PACKAGE_NAME) Done."

install: install_libs install_hdrs install_todir_pkgconfig

