
#include "scum_hal.h"
#include "scum_hal_uart.h"
#include <string.h>
#include <stdio.h>

char strr[500];

void HAL_init() {
  // for (uint16_t i=0; i<64; i+=1) {
  //   HAL_PLIC_completeIRQ(0, i);
  // }
}

uint64_t HAL_getTick() {
  return HAL_CLINT_getTime();
}

/* Busy-wait for the specified number of microseconds.
 * Timebase: CLINT mtime increments at MTIME_FREQ ticks/sec.
 * With SYS_CLK_FREQ = 200 MHz, MTIME_FREQ = 1 MHz => 1 tick = 1 us.
 * Conversion uses 64-bit math: ticks = time_us * MTIME_FREQ / 1_000_000.
 */
void HAL_delay(uint64_t time_us) {
  uint64_t current_tick = HAL_getTick();
  // sprintf(strr, "current_tick: %lu\r\n", current_tick);
  // HAL_UART_transmit(UART0, (uint8_t *)strr, strlen(strr), 0);
  uint64_t delta_ticks = (time_us * (uint64_t)MTIME_FREQ) / 1000000ULL;
  uint64_t target_tick = current_tick + delta_ticks;
  while (HAL_getTick() < target_tick) {
    asm("nop");
  }
}

/* Simple busy-wait delay using loop counter and NOPs.
 * Not cycle-accurate but provides approximate timing.
 */
void HAL_delay_cycles(uint64_t cycles) {
  volatile uint64_t i;
  for (i = 0; i < cycles; i++) {
    asm volatile ("nop");
  }
}