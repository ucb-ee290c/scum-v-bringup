#include "sim_utils.h"
#include "nfc.h"
#include "nfc_test.h"


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

