###########################################################
## History:
##    2022/07/07 - [Jing Leng] Create
##    2022/08/08 - [Jing Leng] Update to v1.0.0
##    2022/09/09 - [Jing Leng] Update to v1.1.0
##    2022/10/26 - [Jing Leng] Update to v1.2.0
##    2022/11/10 - [Jing Leng] Add safe copy
##    2022/12/16 - [Jing Leng] Update to v2.0.0
##    2023/01/11 - [Jing Leng] Update to v2.1.0
##    2023/03/30 - [Jing Leng] Update to v2.2.0
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

COLORECHO      ?= $(if $(findstring dash,$(shell readlink /bin/sh)),echo,echo -e)
LOGOUTPUT      ?= 1>/dev/null

INSTALL_HDR    ?= $(PACKAGE_NAME)
SEARCH_HDRS    ?= $(PACKAGE_DEPS)

ifneq ($(BUILD_FOR_HOST), y)
PACKAGE_ID     := $(PACKAGE_NAME)
OUT_PREFIX     ?= $(ENV_OUT_ROOT)
INS_PREFIX     ?= $(ENV_INS_ROOT)
ifneq ($(PREPARE_SYSROOT), y)
DEP_PREFIX     ?= $(ENV_DEP_ROOT)
else
DEP_PREFIX     ?= $(OUT_PATH)/sysroot
endif

else

PACKAGE_ID     := $(PACKAGE_NAME)-native
OUT_PREFIX     ?= $(ENV_OUT_HOST)
INS_PREFIX     ?= $(ENV_INS_HOST)
ifneq ($(PREPARE_SYSROOT), y)
DEP_PREFIX     ?= $(ENV_DEP_HOST)
else
DEP_PREFIX     ?= $(OUT_PATH)/sysroot-native
endif
endif

ifneq ($(PREPARE_SYSROOT), y)
PATH_PREFIX    ?= $(ENV_DEP_HOST)
else
PATH_PREFIX    ?= $(OUT_PATH)/sysroot-native
endif

ifeq ($(ENV_BUILD_MODE), external)
OUT_PATH       ?= $(patsubst $(ENV_TOP_DIR)/%,$(OUT_PREFIX)/%,$(shell pwd))
else
OUT_PATH       ?= .
endif

define link_hdrs
$(addprefix  -I,$(wildcard \
	$(addprefix $(DEP_PREFIX),/include /usr/include /usr/local/include) \
	$(addprefix $(DEP_PREFIX)/include/,$(SEARCH_HDRS)) \
	$(addprefix $(DEP_PREFIX)/usr/include/,$(SEARCH_HDRS)) \
	$(addprefix $(DEP_PREFIX)/usr/local/include/,$(SEARCH_HDRS)) \
))
endef

ifeq ($(KERNELRELEASE), )

comma          :=,
define link_libs
$(addprefix -L,$(wildcard $(addprefix $(DEP_PREFIX),/lib /usr/lib /usr/local/lib))) \
$(addprefix -Wl$(comma)-rpath-link=,$(wildcard $(addprefix $(DEP_PREFIX),/lib /usr/lib /usr/local/lib)))
endef

define prepare_sysroot
	make ENV_INS_ROOT=$(OUT_PATH)/sysroot ENV_INS_HOST=$(OUT_PATH)/sysroot-native \
		-C $(ENV_TOP_DIR) $(PACKAGE_ID)_install_depends
endef

define safe_copy
$(if $(filter yocto,$(ENV_BUILD_MODE)),cp $1 $2,flock $(INS_PREFIX) -c "cp $1 $2")
endef

ifneq ($(filter y,$(EXPORT_HOST_ENV) $(BUILD_FOR_HOST)), )
export PATH:=$(shell echo $(addprefix $(PATH_PREFIX),/bin /usr/bin /usr/local/bin /sbin /usr/sbin /usr/local/sbin)$(if $(PATH),:$(PATH)) | sed 's/ /:/g')
export LD_LIBRARY_PATH:=$(shell echo $(addprefix $(PATH_PREFIX),/lib /usr/lib /usr/local/lib)$(if $(LD_LIBRARY_PATH),:$(LD_LIBRARY_PATH)) | sed 's/ /:/g')
endif

ifeq ($(EXPORT_PC_ENV), y)
export PKG_CONFIG_LIBDIR=$(DEP_PREFIX)/usr/lib/pkgconfig
export PKG_CONFIG_PATH=$(shell echo $(wildcard $(addprefix $(DEP_PREFIX),$(addsuffix /pkgconfig,/lib /usr/lib /usr/local/lib))) | sed 's@ @:@g')
endif

# yocto envs should be exported by yocto recipe.

ifneq ($(ENV_BUILD_MODE), yocto)

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

# Defines the GNU standard installation directories
# Note: base_*dir and hdrdir are not defined in the GNUInstallDirs
# GNUInstallDirs/Autotools: https://www.gnu.org/prep/standards/html_node/Directory-Variables.html
# CMake: https://cmake.org/cmake/help/latest/module/GNUInstallDirs.html
# Meson: https://mesonbuild.com/Builtin-options.html#directories
# Yocto: https://git.yoctoproject.org/poky/tree/meta/conf/bitbake.conf

base_bindir     = /bin
base_sbindir    = /sbin
base_libdir     = /lib
bindir          = /usr/bin
sbindir         = /usr/sbin
libdir          = /usr/lib
libexecdir      = /usr/libexec
hdrdir          = /usr/include/$(INSTALL_HDR)
includedir      = /usr/include
datarootdir     = /usr/share
datadir         = $(datarootdir)
infodir         = $(datadir)/info
localedir       = $(datadir)/locale
mandir          = $(datadir)/man
docdir          = $(datadir)/doc
sysconfdir      = /etc
servicedir      = /srv
sharedstatedir  = /com
localstatedir   = /var
runstatedir     = /run

endif

###########################################################

ifeq ($(KERNELRELEASE), )

SRC_PATH       ?= .
IGNORE_PATH    ?= .git .pc scripts output
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

ifneq ($(SEARCH_HDRS), )
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

# For more description, refer to https://gcc.gnu.org/onlinedocs/gcc-12.3.0/gcc/Instrumentation-Options.html
ifeq ($(ENV_FSANITIZE_OPTION), 1)
# Enable AddressSanitizer, a fast memory error detector to detect out-of-bounds and use-after-free bugs.
FSANITIZE_FLAG ?= -fsanitize=address
else ifeq ($(ENV_FSANITIZE_OPTION), 2)
# Enable ThreadSanitizer, a fast data race detector.
# Memory access instructions are instrumented to detect data race bugs.
FSANITIZE_FLAG ?= -fsanitize=thread
else ifeq ($(ENV_FSANITIZE_OPTION), 3)
# Enable LeakSanitizer, a memory leak detector. This option only matters for linking of executables,
# and the executable is linked against a library that overrides malloc and other allocator functions.
FSANITIZE_FLAG ?= -fsanitize=leak
else ifeq ($(ENV_FSANITIZE_OPTION), 4)
# Enable UndefinedBehaviorSanitizer, a fast undefined behavior detector.
# Various computations are instrumented to detect undefined behavior at runtime.
FSANITIZE_FLAG ?= -fsanitize=undefined
endif
CFLAGS         += $(FSANITIZE_FLAG)
LDFLAGS        += $(FSANITIZE_FLAG)

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
	@$$(if $$(filter-out $$(patsubst %,\%.%,$$(ASM_SUFFIX)),$$<), \
		$(2) -c $$(CFLAGS) $$(CFLAGS_$$(patsubst %.$(1),%.o,$$<)) -MM -MT $$@ -MF $$(patsubst %.o,%.d,$$@) $$<; \
		cat $$(patsubst %.o,%.d,$$@) \
			| sed -e 's/#.*//' -e 's/^[^:]*:\s*//' -e 's/\s*\\$$$$//' -e 's/[ \t\v][ \t\v]*/\n/g' \
			| sed -e '/^$$$$/ d' -e 's/$$$$/:/g' >> $$(patsubst %.o,%.d,$$@))
	@$(COLORECHO) "\033[032m$(2)\033[0m	$$<" $(LOGOUTPUT)
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
	@$$(AR) r $$@ $$(call extract_obj,$(2)) -c
endef

define add-libso-build
libso_names := $(call all_ver_obj,$(1))
LIB_TARGETS += $(patsubst %,$(OUT_PATH)/%,$(call all_ver_obj,$(1)))

$$(OUT_PATH)/$$(firstword $$(libso_names)): $$(call extract_obj,$(2))
	@$(COLORECHO) "\033[032mlib:\033[0m	\033[44m$$@\033[0m"
	@$$(call compile_tool,$(2)) -shared -fPIC -o $$@ $$(call extract_obj,$(2)) $$(LDFLAGS) $(3) \
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
	@$$(call compile_tool,$(2)) -o $$@ $$(call extract_obj,$(2)) $$(LDFLAGS) $(3)
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

# Defines the compatible variables with previous inc.ins.mk

INSTALL_BASE_BINARIES  ?= $(INSTALL_BINARIES)
INSTALL_BASE_BINS      ?= $(INSTALL_BASE_BINARIES)
INSTALL_BINS           ?= $(INSTALL_BINARIES)
INSTALL_BASE_LIBRARIES ?= $(INSTALL_LIBRARIES)
INSTALL_BASE_LIBS      ?= $(INSTALL_BASE_LIBRARIES)
INSTALL_LIBS           ?= $(INSTALL_LIBRARIES)
INSTALL_HDRS           ?= $(INSTALL_HEADERS)

# Defines the installation functions and targets

define install_obj
.PHONY: install_$(1)s
install_$(1)s:
	@install -d $$(INS_PREFIX)$$($(1)dir)
	@$$(call safe_copy,$(2),$$($(shell echo install_$(1)s | tr 'a-z' 'A-Z')) $$(INS_PREFIX)$$($(1)dir))
endef

define install_ext
install_$(1)s_%:
	@ivar="$$($(shell echo install_$(1)s | tr 'a-z' 'A-Z')$$(patsubst install_$(1)s%,%,$$@))"; \
	isrc="$$$$(echo $$$${ivar} | sed -E 's/\s+[a-zA-Z0-9/@_\.\-]+$$$$//g')"; \
	idst="$$(INS_PREFIX)$$($(1)dir)$$$$(echo $$$${ivar} | sed -E 's/.*\s+([a-zA-Z0-9/@_\.\-]+)$$$$/\1/g')"; \
	install -d $$$${idst} && $$(call safe_copy,$(2),$$$${isrc} $$$${idst})
endef

$(eval $(call install_obj,base_bin,-drf))
$(eval $(call install_obj,base_sbin,-drf))
$(eval $(call install_obj,base_lib,-drf))
$(eval $(call install_obj,bin,-drf))
$(eval $(call install_obj,sbin,-drf))
$(eval $(call install_obj,lib,-drf))
$(eval $(call install_obj,libexec,-drf))
$(eval $(call install_obj,hdr,-drfp))
$(eval $(call install_obj,include,-drfp))
$(eval $(call install_obj,data,-drf))
$(eval $(call install_obj,info,-drf))
$(eval $(call install_obj,locale,-drf))
$(eval $(call install_obj,man,-drf))
$(eval $(call install_obj,doc,-drf))
$(eval $(call install_obj,sysconf,-drf))
$(eval $(call install_obj,service,-drf))
$(eval $(call install_obj,sharedstate,-drf))
$(eval $(call install_obj,localstate,-drf))
$(eval $(call install_obj,runstate,-drf))

$(eval $(call install_ext,include,-drfp))
$(eval $(call install_ext,data,-drf))
$(eval $(call install_ext,sysconf,-drf))

install_todir_%:
	@ivar="$($(shell echo install_todir | tr 'a-z' 'A-Z')$(patsubst install_todir%,%,$@))"; \
	isrc="$$(echo $${ivar} | sed -E 's/\s+[a-zA-Z0-9/@_\.\-]+$$//g')"; \
	idst="$(INS_PREFIX)$$(echo $${ivar} | sed -E 's/.*\s+([a-zA-Z0-9/@_\.\-]+)$$/\1/g')"; \
	iopt="-drf"; \
	if [ $$(echo $${ivar} | sed -E 's/.*\s+([a-zA-Z0-9/@_\.\-]+)$$/\1/g' | grep -c '/include') -eq 1 ]; then \
		iopt="-drfp"; \
	fi; \
	install -d $${idst} && $(call safe_copy,$${iopt},$${isrc} $${idst})

install_tofile_%:
	@ivar="$($(shell echo install_tofile | tr 'a-z' 'A-Z')$(patsubst install_tofile%,%,$@))"; \
	isrc="$$(echo $${ivar} | sed -E 's/\s+[a-zA-Z0-9/@_\.\-]+$$//g')"; \
	idst="$(INS_PREFIX)$$(echo $${ivar} | sed -E 's/.*\s+([a-zA-Z0-9/@_\.\-]+)$$/\1/g')"; \
	iopt="-drf"; \
	if [ $$(echo $${ivar} | sed -E 's/.*\s+([a-zA-Z0-9/@_\.\-]+)$$/\1/g' | grep -c '/include') -eq 1 ]; then \
		iopt="-drfp"; \
	fi; \
	install -d $$(dirname $${idst}) && $(call safe_copy,$${iopt},$${isrc} $${idst})

endif

###########################################################
