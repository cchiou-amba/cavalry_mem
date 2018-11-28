##
## make.inc
##
## History:
##    2018/09/18 - [Tao Wu] Created file
##
## Copyright (c) 2018 Ambarella, Inc.
##
## This file and its contents ("Software") are protected by intellectual
## property rights including, without limitation, U.S. and/or foreign
## copyrights. This Software is also the confidential and proprietary
## information of Ambarella, Inc. and its licensors. You may not use, reproduce,
## disclose, distribute, modify, or otherwise prepare derivative works of this
## Software or any portion thereof except pursuant to a signed license agreement
## or nondisclosure agreement with Ambarella, Inc. or its authorized affiliates.
## In the absence of such an agreement, you agree to promptly notify and return
## this Software to Ambarella, Inc.
##
## THIS SOFTWARE IS PROVIDED "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
## INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF NON-INFRINGEMENT,
## MERCHANTABILITY, AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
## IN NO EVENT SHALL AMBARELLA, INC. OR ITS AFFILIATES BE LIABLE FOR ANY DIRECT,
## INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
## (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
## LOSS OF USE, DATA, OR PROFITS; COMPUTER FAILURE OR MALFUNCTION; OR BUSINESS
## INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
## CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
## ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
## POSSIBILITY OF SUCH DAMAGE.
##

ifeq ($(BUILD_AMBARELLA_CAVALRY_MEM_PACKAGE), y)

LOCAL_PATH      := $(call my-dir)

###
include $(CLEAR_VARS)

LOCAL_SRCS      := $(wildcard $(LOCAL_PATH)/src/*.c)
LOCAL_CFLAGS    := -fvisibility=hidden \
	-I$(LOCAL_PATH)/inc \
	-I$(LOCAL_PATH)/src

LOCAL_LDFLAGS   :=

CAVALRY_MEM_MODULE = libcavalry_mem.so
CAVALRY_MEM_VER_PREFIX = MEM
CAVALRY_MEM_VERSION_FILE = $(LOCAL_PATH)/src/mem_ver.h
CAVALRY_MEM_SO_VER_MAJOR  := $(shell awk '/define\ $(CAVALRY_MEM_VER_PREFIX)_LIB_MAJOR/{print $$3}' $(CAVALRY_MEM_VERSION_FILE))
CAVALRY_MEM_SO_VER_MINOR  := $(shell awk '/define\ $(CAVALRY_MEM_VER_PREFIX)_LIB_MINOR/{print $$3}' $(CAVALRY_MEM_VERSION_FILE))
CAVALRY_MEM_SO_VER_PATCH  := $(shell awk '/define\ $(CAVALRY_MEM_VER_PREFIX)_LIB_PATCH/{print $$3}' $(CAVALRY_MEM_VERSION_FILE))
CAVALRY_MEM_SO_VER_STRING := $(CAVALRY_MEM_SO_VER_MAJOR).$(CAVALRY_MEM_SO_VER_MINOR).$(CAVALRY_MEM_SO_VER_PATCH)
CAVALRY_MEM_SO_NAME   = $(patsubst %.so,%.so.$(CAVALRY_MEM_SO_VER_MAJOR), $(CAVALRY_MEM_MODULE))
CAVALRY_MEM_SO_TARGET = $(patsubst %.so,%.so.$(CAVALRY_MEM_SO_VER_STRING), $(CAVALRY_MEM_MODULE))
LOCAL_SO_NAME := $(CAVALRY_MEM_SO_NAME)

LOCAL_TARGET    := $(CAVALRY_MEM_MODULE)

include $(BUILD_APP)

.PHONY: $(LOCAL_TARGET)

$(LOCAL_TARGET): $(LOCAL_MODULE)
	@mkdir -p $(FAKEROOT_DIR)/usr/lib/
	@cp -dpRf $< $(FAKEROOT_DIR)/usr/lib/$(CAVALRY_MEM_SO_TARGET)
	@ln -sf $(CAVALRY_MEM_SO_TARGET) $(FAKEROOT_DIR)/usr/lib/$(CAVALRY_MEM_SO_NAME)
	@ln -sf $(CAVALRY_MEM_SO_NAME) $(FAKEROOT_DIR)/usr/lib/$(CAVALRY_MEM_MODULE)
	@echo "Build $@ Done."

$(call add-target-into-build, $(LOCAL_TARGET))

endif
