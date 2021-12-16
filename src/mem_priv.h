/*******************************************************************************
 * mem_priv.h
 *
 * History:
 *    2018/09/18  - [Tao Wu] created
 *
 * Copyright [2020] Ambarella International LP.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
******************************************************************************/

#ifndef _MEM_PRIV_H_
#define _MEM_PRIV_H_

#include "list.h"

struct cavalry_mem_node {
	struct list_head list;

	uint32_t is_mem_fd : 1;
	uint32_t reservied_0 : 31;

	/* mem fd */
	uint32_t mem_fd;
	unsigned long offset;

	/* absoluate physical */
	unsigned long base_phys;

	/* common */
	void *base_virt;
	unsigned long size;

	/* attr */
	struct cavalry_mem_attr attr;
};

static inline void LIST_LOCK(pthread_mutex_t *lock)
{
	if (pthread_mutex_lock(lock) < 0) {
		perror("mutex_lock");
	}
}

static inline void LIST_UNLOCK(pthread_mutex_t *lock)
{
	if (pthread_mutex_unlock(lock) < 0) {
		perror("mutex_unlock");
	}
}

struct cavalry_mem_ctx {
	int fd_cav;

	uint32_t verbose : 1;
	uint32_t init_done : 1;
	uint32_t reserved_0 : 30;

	pthread_mutex_t list_lock; /* lock for mem_list */
	struct list_head head;
};

#endif
