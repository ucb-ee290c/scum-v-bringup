
#ifndef __SCUM_HAL_H
#define __SCUM_HAL_H


#ifdef __cplusplus
extern "C" {
#endif

#include "rv_arch.h"
#include "rv_common.h"
#include "scum.h"
#include "scum_hal_core.h"
#include "scum_hal_clint.h"
#include "scum_hal_gpio.h"
#include "scum_hal_plic.h"
#include "scum_hal_rcc.h"
#include "scum_hal_uart.h"


#define SYS_CLK_FREQ  1000000                 // Hz
// Division of 100
#define MTIME_FREQ    (SYS_CLK_FREQ / 100)
#define MTIME_PER_US  (MTIME_FREQ / 1000000)

void HAL_init();

uint64_t HAL_getTick();

void HAL_delay(uint64_t time);

#ifdef __cplusplus
}
#endif

#endif /* __SCUM_HAL_H */
