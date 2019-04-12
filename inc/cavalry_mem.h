/*******************************************************************************
 * cavalry_mem.h
 *
 * History:
 *    2018/09/18  - [Tao Wu] created for CV22
 *
 * Copyright (c) 2018 Ambarella, Inc.
 *
 * This file and its contents ( "Software" ) are protected by intellectual
 * property rights including, without limitation, U.S. and/or foreign
 * copyrights. This Software is also the confidential and proprietary
 * information of Ambarella, Inc. and its licensors. You may not use, reproduce,
 * disclose, distribute, modify, or otherwise iproare derivative works of this
 * Software or any portion thereof except pursuant to a signed license agreement
 * or nondisclosure agreement with Ambarella, Inc. or its authorized affiliates.
 * In the absence of such an agreement, you agree to promptly notify and return
 * this Software to Ambarella, Inc.
 *
 * THIS SOFTWARE IS PROVIDED "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF NON-INFRINGEMENT,
 * MERCHANTABILITY, AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL AMBARELLA, INC. OR ITS AFFILIATES BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; COMPUTER FAILURE OR MALFUNCTION; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *
******************************************************************************/

#ifndef _CAVALRY_MEM_H_
#define _CAVALRY_MEM_H_

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>

#ifndef IN
#define IN
#endif

#ifndef OUT
#define OUT
#endif

#ifndef INOUT
#define INOUT
#endif

struct cavalry_mem_version {
	uint32_t major;
	uint32_t minor;
	uint32_t patch;
	unsigned int mod_time;
	char description[64];
};

#ifndef AMBA_API
#define AMBA_API __attribute__((visibility("default")))
#endif


/* Library API */
AMBA_API int cavalry_mem_init(IN int fd_cav, IN uint8_t verbose);
AMBA_API int cavalry_mem_get_version(struct cavalry_mem_version *ver);


/* Memory API */
AMBA_API int cavalry_mem_alloc(INOUT unsigned long *psize,
	OUT unsigned long *pphys, OUT void **pvirt, IN uint8_t cache_en);
AMBA_API int cavalry_mem_free(IN unsigned long size,
	IN unsigned long phys, IN void *virt);


/* cavalry_mem_sync_cache:
  *   clean: do after arm write   (cache -> dram)
  * invalid: do before arm read (dram -> cache) */
AMBA_API int cavalry_mem_sync_cache(
	IN unsigned long size, IN unsigned long phys,
	IN uint8_t clean, IN uint8_t invalid);

#ifdef __cplusplus
}
#endif

#endif
