/*******************************************************************************
 * @file cavalry_mem.h
 * @brief This file defines cavalry_mem API specification
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

/*! @addtogroup cavalry_mem-helper
 *  @{
 */

/*!
 * @brief The version of cavalry_mem library
 */
struct cavalry_mem_version {
	uint32_t major;  /*!< Version major number */
	uint32_t minor;  /*!< Version minor number */
	uint32_t patch;  /*!< Version patch number */
	unsigned int mod_time;  /*!< Version modification time */
	char description[64];  /*!< Version change description */
};

/*! @macros AMBA_API
 *  @brief API function attribute */
#ifndef AMBA_API
#define AMBA_API __attribute__((visibility("default")))
#endif
/*! @} */ /* End of cavalry_mem-helper */


/*!
 * @addtogroup cavalry_mem-api-details
 * @{
 */

/*!
 * This API initializes the library with the cavalry driver and library verbose configuration.
 * It must be called before all other functions
 *
 * @param fd_cav the fd to open cavalry driver
 * @param verbose the flag to show verbose info in library
 * @return 0 = success, -1 = error.
 */
AMBA_API int cavalry_mem_init(IN int fd_cav, IN uint8_t verbose);

/*!
 * This API get the version of library.
 *
 * @param ver the pointer to version
 * @return 0 = success, -1 = error.
 */
AMBA_API int cavalry_mem_get_version(struct cavalry_mem_version *ver);

/*!
 * This API exit the library.
 * It must be called after all other functions
 */
AMBA_API void cavalry_mem_exit(void);

/*!
 * This API allocates the memory from the CV user memory.
 * Cache memory exist between ARM and DRAM.
 * Turn on @param cache_en can boost ARM process speed.
 *
 * @param psize the pointer to total size want allocate
 * @param pphys the pointer to physical address that return
 * @param pvirt the pointer to virtual address that return
 * @param cache_en the flag to enable cached memory. 0: non-cache; 1: cache
 * @return 0 = success, -1 = error.
 */
AMBA_API int cavalry_mem_alloc(INOUT unsigned long *psize,
	OUT unsigned long *pphys, OUT void **pvirt, IN uint8_t cache_en);

/*!
 * This API frees the memory from the CV user memory.
 *
 * @param size total size
 * @param phys physical address
 * @param virt virtual address
 * @return 0 = success, -1 = error.
 */
AMBA_API int cavalry_mem_free(IN unsigned long size,
	IN unsigned long phys, IN void *virt);

/*!
* This API syncs the cached memory when cache_en is set in @ref cavalry_mem_alloc.
* It will return an error if it is used with non-cached memory.
* Can sync one slice of total memory. At the begin need sync network's dvi memory after nnctrl_load_net,
* then most of time sync Network's Input/Ouput memory.
*
* @param size size of memory
* @param phys physical address
* @param virt virtual address
* @param clean the flag to clean cache.  0: turn off; 1: turn on.
*                        Program Flow: 1.ARM write -> 2.clean cache -> 3.VP read
* @param invalid the flag to invalid cache.  0: turn off; 1: turn on.
*                        Program Flow: 1.VP write -> 2.invalid cache -> 3.ARM read
* @return 0 = success, -1 = error.
*/
AMBA_API int cavalry_mem_sync_cache(
	IN unsigned long size, IN unsigned long phys,
	IN uint8_t clean, IN uint8_t invalid);

/*! @} */ /* End of cavalry_mem-api-details */

#ifdef __cplusplus
}
#endif

#endif
