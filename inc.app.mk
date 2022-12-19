###########################################################
## History:
##    2022/07/07 - [Jing Leng] Create
##    2022/08/08 - [Jing Leng] Update to v1.0.0
##    2022/09/09 - [Jing Leng] Update to v1.1.0
##    2022/10/26 - [Jing Leng] Update to v1.2.0
##    2022/11/10 - [Jing Leng] Add safe copy
##    2022/12/16 - [Jing Leng] Update to v2.0.0
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

################### copy from in.env.mk ###################

ifneq ($(BUILD_FOR_HOST), y)
OUT_PREFIX     := $(ENV_OUT_ROOT)
INS_PREFIX     := $(ENV_INS_ROOT)
DEP_PREFIX     := $(ENV_DEP_ROOT)
else
OUT_PREFIX     := $(ENV_OUT_HOST)
INS_PREFIX     := $(ENV_INS_HOST)
DEP_PREFIX     := $(ENV_DEP_HOST)
endif

define link_hdrs
$(addprefix  -I,$(wildcard \
	$(addprefix $(DEP_PREFIX),/include /usr/include /usr/local/include) \
	$(addprefix $(DEP_PREFIX)/include/,$(PACKAGE_DEPS)) \
	$(addprefix $(DEP_PREFIX)/usr/include/,$(PACKAGE_DEPS)) \
	$(addprefix $(DEP_PREFIX)/usr/local/include/,$(PACKAGE_DEPS)) \
))
endef

ifeq ($(KERNELRELEASE), )

comma          :=,
define link_libs
$(addprefix -L,$(wildcard $(addprefix $(DEP_PREFIX),/lib /usr/lib /usr/local/lib))) \
$(addprefix -Wl$(comma)-rpath-link=,$(wildcard $(addprefix $(DEP_PREFIX),/lib /usr/lib /usr/local/lib)))
endef

define safe_copy
$(if $(filter yocto,$(ENV_BUILD_MODE)),cp $1 $2,flock $(INS_PREFIX) -c "cp $1 $2")
endef

ifneq ($(filter y,$(EXPORT_HOST_ENV) $(BUILD_FOR_HOST)), )
export PATH:=$(shell echo $(addprefix $(ENV_DEP_HOST),/bin /usr/bin /usr/local/bin)$(if $(PATH),:$(PATH)) | sed 's/ /:/g')
export LD_LIBRARY_PATH:=$(shell echo $(addprefix $(ENV_DEP_HOST),/lib /usr/lib /usr/local/lib)$(if $(LD_LIBRARY_PATH),:$(LD_LIBRARY_PATH)) | sed 's/ /:/g')
endif

ifeq ($(ENV_BUILD_MODE), yocto)

# envs should be exported by yocto recipe.

else

ifeq ($(ENV_BUILD_MODE), external)
OUT_PATH       ?= $(patsubst $(ENV_TOP_DIR)/%,$(OUT_PREFIX)/%,$(shell pwd))
else
OUT_PATH       ?= .
endif

ifneq ($(BUILD_FOR_HOST), y)

ifneq ($(ENV_BUILD_ARCH), )
ARCH           := $(ENV_BUILD_ARCH)
export ARCH
endif

ifneq ($(ENV_BUILD_TOOL), )
ifneq ($(findstring /,$(ENV_BUILD_TOOL)), )
CROSS_TOOLPATH := $(shell dirname $(ENV_BUILD_TOOL))
CROSS_COMPILE  := $(shell basename $(ENV_BUILD_TOOL))
export PATH:=$(PATH):$(CROSS_TOOLPATH)
else
CROSS_COMPILE  := $(ENV_BUILD_TOOL)
endif
export CROSS_COMPILE
endif

CC             := $(CROSS_COMPILE)gcc
CPP            := $(CROSS_COMPILE)gcc -E
CXX            := $(CROSS_COMPILE)g++
AS             := $(CROSS_COMPILE)as
LD             := $(CROSS_COMPILE)ld
AR             := $(CROSS_COMPILE)ar
RANLIB         := $(CROSS_COMPILE)ranlib
OBJCOPY        := $(CROSS_COMPILE)objcopy
STRIP          := $(CROSS_COMPILE)strip
export CC CXX CPP AS LD AR RANLIB OBJCOPY STRIP

else

undefine ARCH CROSS_COMPILE
unexport ARCH CROSS_COMPILE

CC             := gcc
CPP            := gcc -E
CXX            := g++
AS             := as
LD             := ld
AR             := ar
RANLIB         := ranlib
OBJCOPY        := objcopy
STRIP          := strip
export CC CXX CPP AS LD AR RANLIB OBJCOPY STRIP

endif
endif
endif

###########################################################

ifeq ($(KERNELRELEASE), )

SRC_PATH       ?= .
IGNORE_PATH    ?= .git scripts output
REG_SUFFIX     ?= c cpp S
ifeq ($(USING_CXX_BUILD_C), y)
CPP_SUFFIX     ?= c cc cp cxx cpp CPP c++ C
else
CPP_SUFFIX     ?= cc cp cxx cpp CPP c++ C
endif
ASM_SUFFIX     ?= S s asm

SRCS           ?= $(shell find $(SRC_PATH) $(patsubst %,-path '*/%' -prune -o,$(IGNORE_PATH)) \
                      $(shell echo '$(patsubst %,-o -name "*.%" -print,$(REG_SUFFIX))' | sed 's/^...//') \
                  | sed "s/^\(\.\/\)\(.*\)/\2/g" | xargs)

#### flags related to board ####
CFLAGS         += $(strip $(shell echo \
                      -DAMBA_SOC_$(AMBA_SOC) \
                      -DAMBA_DSP_ARCH_$(AMBA_DSP_ARCH) \
                      -DAMBA_IMG_ARCH_$(AMBA_IMG_ARCH) \
                      -DAMBA_CAVALRY_ARCH_$(AMBA_CAVALRY_ARCH) \
                      | tr [:lower:] [:upper:]))
CFLAGS         += -DAMBA_AMYOC_BUILD
CFLAGS         += -I$(DEP_PREFIX)/usr/include/board

CFLAGS         += -I. -I./include $(patsubst %,-I%,$(filter-out .,$(SRC_PATH))) $(patsubst %,-I%/include,$(filter-out .,$(SRC_PATH))) -I$(OUT_PATH)

ifneq ($(PACKAGE_DEPS), )
CFLAGS         += $(call link_hdrs)
LDFLAGS        += $(call link_libs)
endif

ifeq ($(STRICT), y)
CFLAGS         += -Wall # This enables all the warnings about constructions that some users consider questionable.
CFLAGS         += -Wextra # This enables some extra warning flags that are not enabled by -Wall (This option used to be called -W).
CFLAGS         += -Wlarger-than=$(if $(object_byte_size),$(object_byte_size),1024) # Warn whenever an object is defined whose size exceeds object_byte_size.
CFLAGS         += -Wframe-larger-than=$(if $(object_byte_size),$(object_byte_size),8192) # Warn if the size of a function frame exceeds byte-size.
#CFLAGS        += -Wdate-time #Warn when macros __TIME__, __DATE__ or __TIMESTAMP__ are encountered as they might prevent bit-wise-identical reproducible compilations.
endif

ifeq ($(DEBUG), y)
CFLAGS         += -O0 -g -ggdb
else
CFLAGS         += -ffunction-sections -fdata-sections -O2
LDFLAGS        += -Wl,--gc-sections
endif
#LDFLAGS       += -static

COLORECHO       = $(if $(findstring dash,$(shell readlink /bin/sh)),echo,echo -e)

define extract_obj
$(patsubst %,$(OUT_PATH)/%.o,$(basename $(1)))
endef

define set_flags
$(foreach v,$(2),$(eval $(1)_$(patsubst %,%.o,$(basename $(v))) = $(3)))
endef

define all_ver_obj
$(strip \
	$(if $(word 4,$(1)), \
		$(if $(word 4,$(1)),$(word 1,$(1)).$(word 2,$(1)).$(word 3,$(1)).$(word 4,$(1))) \
		$(if $(word 2,$(1)),$(word 1,$(1)).$(word 2,$(1))) \
		$(word 1,$(1)) \
		,\
		$(if $(word 3,$(1)),$(word 1,$(1)).$(word 2,$(1)).$(word 3,$(1))) \
		$(if $(word 2,$(1)),$(word 1,$(1)).$(word 2,$(1))) \
		$(word 1,$(1)) \
	)
)
endef

define compile_tool
$(if $(filter $(patsubst %,\%.%,$(CPP_SUFFIX)),$(1)),$(CXX),$(CC))
endef

define compile_obj
ifeq ($(filter $(1),$(REG_SUFFIX)),$(1))
ifneq ($(filter %.$(1),$(SRCS)), )
$$(patsubst %.$(1),$$(OUT_PATH)/%.o,$$(filter %.$(1),$$(SRCS))): $$(OUT_PATH)/%.o: %.$(1)
	@mkdir -p $$(dir $$@)
	@$$(if $$(filter-out $$(patsubst %,\%.%,$$(ASM_SUFFIX)),$$<),$(2) -c $$(CFLAGS) $$(CFLAGS_$$(patsubst %.$(1),%.o,$$<)) -MM -MT $$@ -MF $$(patsubst %.o,%.d,$$@) $$<)
	@#$(COLORECHO) "\033[032m$(2)\033[0m	$$<"
	@$$(if $$(filter-out $$(AS),$(2)),$(2) -c $$(CFLAGS) $$(CFLAGS_$$(patsubst %.$(1),%.o,$$<)) -fPIC -o $$@ $$<,$(AS) $$(AFLAGS) $$(AFLAGS_$$(patsubst %.$(1),%.o,$$<)) -o $$@ $$<)
endif
endif
endef

ifeq ($(USING_CXX_BUILD_C), y)
$(eval $(call compile_obj,c,$$(CXX)))
else
$(eval $(call compile_obj,c,$$(CC)))
endif
$(eval $(call compile_obj,cc,$$(CXX)))
$(eval $(call compile_obj,cp,$$(CXX)))
$(eval $(call compile_obj,cxx,$$(CXX)))
$(eval $(call compile_obj,cpp,$$(CXX)))
$(eval $(call compile_obj,CPP,$$(CXX)))
$(eval $(call compile_obj,c++,$$(CXX)))
$(eval $(call compile_obj,C,$$(CXX)))
$(eval $(call compile_obj,S,$$(CC)))
$(eval $(call compile_obj,s,$$(AS)))
$(eval $(call compile_obj,asm,$$(AS)))

OBJS            = $(call extract_obj,$(SRCS))
DEPS            = $(patsubst %.o,%.d,$(OBJS))
$(OBJS): $(MAKEFILE_LIST)
-include $(DEPS)

.PHONY: clean_objs

clean_objs:
	@-rm -rf $(OBJS) $(DEPS)

define add-liba-build
LIB_TARGETS += $$(OUT_PATH)/$(1)
$$(OUT_PATH)/$(1): $$(call extract_obj,$(2))
	@$(COLORECHO) "\033[032mlib:\033[0m	\033[44m$$@\033[0m"
	@$$(AR) r $$@ $$^ -c
endef

define add-libso-build
libso_names := $(call all_ver_obj,$(1))
LIB_TARGETS += $(patsubst %,$(OUT_PATH)/%,$(call all_ver_obj,$(1)))

$$(OUT_PATH)/$$(firstword $$(libso_names)): $$(call extract_obj,$(2))
	@$(COLORECHO) "\033[032mlib:\033[0m	\033[44m$$@\033[0m"
	@$$(call compile_tool,$(2)) -shared -fPIC -o $$@ $$^ $$(LDFLAGS) $(3) \
		$$(if $$(findstring -soname=,$(3)),,-Wl$$(comma)-soname=$$(if $$(word 2,$(1)),$$(firstword $(1)).$$(word 2,$(1)),$(1)))

ifneq ($$(word 2,$$(libso_names)), )
$$(OUT_PATH)/$$(word 2,$$(libso_names)): $$(OUT_PATH)/$$(word 1,$$(libso_names))
	@cd $$(OUT_PATH) && ln -sf $$(patsubst $$(OUT_PATH)/%,%,$$<) $$(patsubst $$(OUT_PATH)/%,%,$$@)
endif

ifneq ($$(word 3,$$(libso_names)), )
$$(OUT_PATH)/$$(word 3,$$(libso_names)): $$(OUT_PATH)/$$(word 2,$$(libso_names))
	@cd $$(OUT_PATH) && ln -sf $$(patsubst $$(OUT_PATH)/%,%,$$<) $$(patsubst $$(OUT_PATH)/%,%,$$@)
endif

ifneq ($$(word 4,$$(libso_names)), )
$$(OUT_PATH)/$$(word 4,$$(libso_names)): $$(OUT_PATH)/$$(word 3,$$(libso_names))
	@cd $$(OUT_PATH) && ln -sf $$(patsubst $$(OUT_PATH)/%,%,$$<) $$(patsubst $$(OUT_PATH)/%,%,$$@)
endif

endef

define add-bin-build
BIN_TARGETS += $$(OUT_PATH)/$(1)
$$(OUT_PATH)/$(1): $$(call extract_obj,$(2))
	@$(COLORECHO) "\033[032mbin:\033[0m	\033[44m$$@\033[0m"
	@$$(call compile_tool,$(2)) -o $$@ $$^ $$(LDFLAGS) $(3)
endef

ifneq ($(LIBA_NAME), )
$(eval $(call add-liba-build,$(LIBA_NAME),$(SRCS)))
endif

ifneq ($(LIBSO_NAME), )
$(eval $(call add-libso-build,$(LIBSO_NAME),$(SRCS)))
endif

ifneq ($(BIN_NAME), )
$(eval $(call add-bin-build,$(BIN_NAME),$(SRCS)))
endif

INSTALL_LIBRARIES ?= $(LIB_TARGETS)
INSTALL_BINARIES  ?= $(BIN_TARGETS)

endif

################### copy from in.ins.mk ###################

ifeq ($(KERNELRELEASE), )

.PHONY: install_libs install_base_libs install_bins install_base_bins install_hdrs install_datas

install_libs:
	@install -d $(INS_PREFIX)/usr/lib
	@$(call safe_copy,-drf,$(INSTALL_LIBRARIES) $(INS_PREFIX)/usr/lib)

INSTALL_BASE_LIBRARIES ?= $(INSTALL_LIBRARIES)
install_base_libs:
	@install -d $(INS_PREFIX)/lib
	@$(call safe_copy,-drf,$(INSTALL_BASE_LIBRARIES) $(INS_PREFIX)/lib)

install_bins:
	@install -d $(INS_PREFIX)/usr/bin
	@$(call safe_copy,-drf,$(INSTALL_BINARIES) $(INS_PREFIX)/usr/bin)

INSTALL_BASE_BINARIES ?= $(INSTALL_BINARIES)
install_base_bins:
	@install -d $(INS_PREFIX)/bin
	@$(call safe_copy,-drf,$(INSTALL_BASE_BINARIES) $(INS_PREFIX)/bin)

install_hdrs:
	@install -d $(INS_PREFIX)/usr/include/$(PACKAGE_NAME)
	@$(call safe_copy,-drfp,$(INSTALL_HEADERS) $(INS_PREFIX)/usr/include/$(PACKAGE_NAME))

install_datas:
	@install -d $(INS_PREFIX)/usr/share/$(PACKAGE_NAME)
	@$(call safe_copy,-drf,$(INSTALL_DATAS) $(INS_PREFIX)/usr/share/$(PACKAGE_NAME))

install_datas_%:
	@icp="$(if $(findstring /include,$(lastword $(INSTALL_DATAS_$(patsubst install_datas_%,%,$@)))),-drfp,-drf)"; \
		isrc="$(patsubst $(lastword $(INSTALL_DATAS_$(patsubst install_datas_%,%,$@))),,$(INSTALL_DATAS_$(patsubst install_datas_%,%,$@)))"; \
		idst="$(INS_PREFIX)/usr/share$(lastword $(INSTALL_DATAS_$(patsubst install_datas_%,%,$@)))"; \
		install -d $${idst} && $(call safe_copy,$${icp},$${isrc} $${idst})

install_todir_%:
	@icp="$(if $(findstring /include,$(lastword $(INSTALL_TODIR_$(patsubst install_todir_%,%,$@)))),-drfp,-drf)"; \
		isrc="$(patsubst $(lastword $(INSTALL_TODIR_$(patsubst install_todir_%,%,$@))),,$(INSTALL_TODIR_$(patsubst install_todir_%,%,$@)))"; \
		idst="$(INS_PREFIX)$(lastword $(INSTALL_TODIR_$(patsubst install_todir_%,%,$@)))"; \
		install -d $${idst} && $(call safe_copy,$${icp},$${isrc} $${idst})

install_tofile_%:
	@icp="$(if $(findstring /include,$(lastword $(INSTALL_TOFILE_$(patsubst install_tofile_%,%,$@)))),-dfp,-df)"; \
		isrc="$(word 1,$(INSTALL_TOFILE_$(patsubst install_tofile_%,%,$@)))"; \
		idst="$(INS_PREFIX)$(lastword $(INSTALL_TOFILE_$(patsubst install_tofile_%,%,$@)))"; \
		install -d $(dir $(INS_PREFIX)$(lastword $(INSTALL_TOFILE_$(patsubst install_tofile_%,%,$@)))) && $(call safe_copy,$${icp},$${isrc} $${idst})

endif

###########################################################
