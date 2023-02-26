
#ifndef __SCUM_HAL_CLINT_H
#define __SCUM_HAL_CLINT_H

#ifdef __cplusplus
extern "C" {
#endif

#include "scum.h"

uint64_t HAL_CLINT_getMTime();

void HAL_CLINT_setMTimeCmp(uint64_t time);

#ifdef __cplusplus
}
#endif

#endif /* __SCUM_HAL_CLINT_H */
