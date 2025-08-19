#include <stdint.h>
#include <scum_hal_uart.h>
#include "build_config.h"

#ifdef BUILD_MODE_SIM
#include "syscall.h"
#endif

// extern volatile uint32_t tohost;

// TODO: non 0 exit codes cause a lot of unnecessary output
// void __attribute__((noreturn)) sim_finish() {
//   // HAL_UART_finishTX(UART0);
//   _exit(0);
// }

void __attribute__((noreturn)) sim_finish() {
  HAL_UART_finishTX(UART0);
#ifdef BUILD_MODE_SIM
  _exit(0);
#else
  while(1) {
    asm volatile ("wfi");
  }
#endif
}