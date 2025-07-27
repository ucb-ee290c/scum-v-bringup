#include "sim_utils.h"

volatile int done_status = 0;
char str[512];


int main() {
  int result = 1 + 1;
  sim_finish(); 
}

void __attribute__((weak, noreturn)) __main(void) {
  while (1) {
    asm volatile ("wfi");
  }
}
