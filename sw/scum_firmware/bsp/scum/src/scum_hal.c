
#include "scum_hal.h"

void HAL_init() {
  // Checked by the bootloader to confirm that the firmware 
  // is executing
  *(uint32_t*)0x8000B000 = 0xdeadbeef;
}

uint64_t HAL_getTick() {
  return HAL_CLINT_getMTime();
}

void HAL_delay(uint64_t time) {
  uint64_t target_tick = HAL_getTick() + (time * MTIME_PER_US);
  while (HAL_getTick() < target_tick) {
    asm("nop");
  }
}
