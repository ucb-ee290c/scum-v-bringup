
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
#include "build_config.h"

/* CLINT mtime timebase
 * Design intent: at SYS_CLK_FREQ = 200 MHz, mtime advances every 1 microsecond.
 * This corresponds to a prescale of 200, so mtime ticks per second are:
 *   MTIME_FREQ = SYS_CLK_FREQ / 200
 * Therefore, with SYS_CLK_FREQ = 200e6, MTIME_FREQ = 1e6 ticks/sec (1 tick = 1 us).
 * If SYS_CLK_FREQ is changed on the bench, update SYS_CLK_FREQ here and recompile.
 */
#define MTIME_FREQ    (SYS_CLK_FREQ / 200)      // mtime ticks per second
#define MTIME_PER_US  (MTIME_FREQ / 1000000)    // mtime ticks per microsecond (integer division)

void HAL_init();

/* Read CLINT mtime (monotonic tick counter).
 * Units: ticks at MTIME_FREQ ticks/sec. At 200 MHz system clock, 1 tick = 1 us.
 */
uint64_t HAL_getTick();

/* Busy-wait for the specified number of microseconds.
 * Units: microseconds. Example (at 200 MHz -> 1 tick/us):
 *   HAL_delay(1)   ~ 1 us
 *   HAL_delay(100) ~ 100 us
 */
void HAL_delay(uint64_t time_us);

/* Busy-wait for the specified number of CPU clock cycles.
 * Uses CPU cycle counter directly instead of CLINT mtime.
 * Units: CPU clock cycles. Example (at 200 MHz):
 *   HAL_delay_cycles(200)     ~ 1 us
 *   HAL_delay_cycles(20000)   ~ 100 us
 */
void HAL_delay_cycles(uint64_t cycles);

#ifdef __cplusplus
}
#endif

#endif /* __SCUM_HAL_H */
