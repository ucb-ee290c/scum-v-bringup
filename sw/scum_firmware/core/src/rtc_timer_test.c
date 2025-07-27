#include "sim_utils.h"
#include "rtc_timer.h"
#include "rtc_timer_test.h"


int main() {
  HAL_init();
  // system_init();
  int result = 1;
  for (result = 0; result < 500000; result++) asm("nop");
  sim_finish();
}

void __attribute__((weak, noreturn)) __main(void) {
  while (1) {
    asm volatile ("wfi");
  }
}

