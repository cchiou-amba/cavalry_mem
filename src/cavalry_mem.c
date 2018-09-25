/*******************************************************************************
 * cavalry_mem.c
 *
 * History:
 *    2018/09/18  - [Tao Wu] created
 *
 * Copyright (c) 2018 Ambarella, Inc.
 *
 * This file and its contents ( "Software" ) are protected by intellectual
 * property rights including, without limitation, U.S. and/or foreign
 * copyrights. This Software is also the confidential and proprietary
 * information of Ambarella, Inc. and its licensors. You may not use, reproduce,
 * disclose, distribute, modify, or otherwise prepare derivative works of this
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

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/mman.h>

#include <cavalry_ioctl.h>
#include <cavalry_mem.h>

#include "mem_priv.h"
#include "mem_ver.h"

static struct cavalry_mem_version G_version = {
	.major = MEM_LIB_MAJOR,
	.minor = MEM_LIB_MINOR,
	.patch = MEM_LIB_PATCH,
	.mod_time = 0x20180918,
	.description = "Cavalry Memory Allocator Library",
};

static struct cavalry_mem_info G_mem_priv;

int cavalry_mem_init(int fd_cav, uint8_t verbose)
{
	struct cavalry_mem_info *priv = &G_mem_priv;
	struct cavalry_mem_version *pver = &G_version;

	if (fd_cav < 0) {
		printf("Invalid fd_cavalry: %d param\n", fd_cav);
		return -1;
	}

	if (priv->init_done) {
		printf("Library is inited already, do not do it again\n");
		return -1;
	} else {
		priv->fd_cav = fd_cav;
		priv->verbose = !!verbose;
	}

	printf("%s: %u.%u.%u, mod-time: 0x%x, built-time: %s - %s\n",
		pver->description, pver->major, pver->minor, pver->patch, pver->mod_time,
		__DATE__, __TIME__);
	priv->init_done = 1;

	return 0;
}

int cavalry_mem_get_version(struct cavalry_mem_version *ver)
{
	struct cavalry_mem_version *pver = &G_version;

	if (ver == NULL) {
		printf("Version pointer is NULL\n");
		return -1;
	}

	memcpy(ver, pver, sizeof(struct cavalry_mem_version));
	return 0;
}

int cavalry_mem_alloc(unsigned long *psize, unsigned long *pphys,
	void **pvirt, uint8_t cache_en)
{
	struct cavalry_mem_info *priv = &G_mem_priv;
	struct cavalry_mem cv_mem;
	uint8_t *virt = NULL;
	int rval = 0;

	if (!priv->init_done) {
		printf("Library is not inited for alloc\n");
		return -1;
	}
	if ((psize == NULL) || (pphys == NULL) || (pvirt == NULL)) {
		printf("Invalid mem alloc param\n");
		return -1;
	}
	if (*psize == 0) {
		printf("Invalid mem alloc size: %lu\n", *psize);
		return -1;
	}

	memset(&cv_mem, 0, sizeof(cv_mem));
	cv_mem.length = *psize;
	cv_mem.cache_en = !!cache_en;

	do {
		if (ioctl(priv->fd_cav, CAVALRY_ALLOC_MEM, &cv_mem) < 0) {
			perror("CAVALRY_ALLOC_MEM");
			rval = -1;
			break;
		}

		virt = mmap(NULL, cv_mem.length, PROT_WRITE, MAP_SHARED, priv->fd_cav,
			cv_mem.offset);
		if (virt == MAP_FAILED) {
			perror("mmap cavalry mem err");
			printf("mem free since mmap err: phys: 0x%lx, size: 0x%lx\n",
				cv_mem.offset, cv_mem.length);
			if (ioctl(priv->fd_cav, CAVALRY_FREE_MEM, &cv_mem) < 0) {
				perror("CAVALRY_ALLOC_MEM");
			}
			rval = -1;
			break;
		}
		*pvirt = virt;
		*pphys = cv_mem.offset;

		if (priv->verbose) {
			printf("mem alloc: phys: 0x%lx, size: %lu, virt: %p.\n",
				cv_mem.offset, cv_mem.length, virt);
		}
	}while (0);

	return rval;
}

int cavalry_mem_free(unsigned long size, unsigned long phys, void *virt)
{
	struct cavalry_mem_info *priv = &G_mem_priv;
	struct cavalry_mem cv_mem;
	int rval = 0;

	if (!priv->init_done) {
		printf("Library is not inited for alloc\n");
		return -1;
	}
	if ((size == 0) || (phys == 0) || (virt == NULL)) {
		printf("Invalid mem free size, phys, virt param\n");
		return -1;
	}

	munmap(virt, size);
	memset(&cv_mem, 0, sizeof(cv_mem));
	cv_mem.offset = phys;
	if (ioctl(priv->fd_cav, CAVALRY_FREE_MEM, &cv_mem) < 0) {
		perror("CAVALRY_FREE_MEM");
		rval = -1;
	}

	if (priv->verbose) {
		printf("mem free: phys: 0x%lx, size: %lu, virt: %p.\n",
			cv_mem.offset, cv_mem.length, virt);
	}

	return rval;
}

int cavalry_mem_sync_cache(unsigned long size, unsigned long phys,
	uint8_t clean, uint8_t invalid)
{
	struct cavalry_mem_info *priv = &G_mem_priv;
	struct cavalry_cache_mem cache;
	int rval = 0;

	if (!priv->init_done) {
		printf("Library is not inited for alloc\n");
		return -1;
	}
	if ((size == 0) || (phys == 0)) {
		printf("Invalid sync cache size and phys param\n");
		return -1;
	}

	memset(&cache, 0, sizeof(cache));
	cache.offset = phys;
	cache.length = size;
	cache.clean = !!clean;
	cache.invalid = !!invalid;
	if (ioctl(priv->fd_cav, CAVALRY_SYNC_CACHE_MEM, &cache) < 0) {
		perror("CAVALRY_SYNC_CACHE_MEM");
		rval = -1;
	}

	return rval;
}
