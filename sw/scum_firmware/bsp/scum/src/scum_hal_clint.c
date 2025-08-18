
#include "scum_hal_clint.h"


uint64_t HAL_CLINT_getTime() {
  uint32_t time_lo;
  uint32_t time_hi;

  do {
    // MTIME is 64-bit; read high then low then verify high did not change
    time_hi = *((uint32_t *)(&CLINT->MTIME) + 1);
    time_lo = *((uint32_t *)(&CLINT->MTIME) + 0);
  } while (*((uint32_t *)(&CLINT->MTIME) + 1) != time_hi);

  return (((uint64_t)time_hi) << 32U) | time_lo;
}

void HAL_CLINT_setTimerInterruptTarget(uint32_t hartid, uint64_t time) {
  // Each hart's MTIMECMP is 64-bit and contiguous; stride is 2 x 32-bit words per hart
  *((uint32_t *)(&CLINT->MTIMECMP0) + hartid * 2 + 1) = 0xffffffff;
  *((uint32_t *)(&CLINT->MTIMECMP0) + hartid * 2 + 0) = (uint32_t)time;
  *((uint32_t *)(&CLINT->MTIMECMP0) + hartid * 2 + 1) = (uint32_t)(time >> 32);
}
