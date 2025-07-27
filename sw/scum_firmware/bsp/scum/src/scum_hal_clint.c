
#include "scum_hal_clint.h"


uint64_t HAL_CLINT_getTime() {
  uint32_t time_lo;
  uint32_t time_hi;

  do {
    time_hi = *((uint32_t *)(&CLINT->MTIME) + 1);
    time_lo = *((uint32_t *)(&CLINT->MTIME));
  } while (*((uint32_t *)(&CLINT->MTIME) + 1) != time_hi);

  return (((uint64_t)time_hi) << 32U) | time_lo;
}

void HAL_CLINT_setTimerInterruptTarget(uint32_t hartid, uint64_t time) {
  *((uint32_t *)(&CLINT->MTIMECMP0) + 4 * hartid + 1) = 0xffffffff;
  *((uint32_t *)(&CLINT->MTIMECMP0) + 4 * hartid) = (uint32_t)time;
  *((uint32_t *)(&CLINT->MTIMECMP0) + 4 * hartid + 1) = (uint32_t)(time >> 32);
}
