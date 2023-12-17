#include <stdint.h>
#include <scum_hal_uart.h>

extern volatile uint32_t tohost;

// TODO: non 0 exit codes cause a lot of unnecessary output
void __attribute__((noreturn)) sim_finish() {
  HAL_UART_finishTX(UART0);
  uint32_t code = 0;
  tohost = (code << 1) | 1;
  while (1);
}
