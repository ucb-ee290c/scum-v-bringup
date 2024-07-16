
#ifndef __SCUMSYSTEM_H
#define __SCUMSYSTEM_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>
#include <stdio.h>
#include <string.h>

enum IRQ_SOURCE {
  RX_ERROR = 5,
  RX_START = 6,
  RX_FINISH = 7,
  TX_ERROR = 8,
  TX_FINISH = 9,
  IF_THRESHOLD = 10
};

enum DEBUG_STATUS {
  NONE,
  DEBUG_TX_FINISH,
  DEBUG_TX_FAIL,
  DEBUG_RX_FINISH,
  DEBUG_RX_FAIL
};
extern volatile enum DEBUG_STATUS debug_status;

void system_init(void);
void enable_fpu(void);
void print_fcsr();

#ifdef __cplusplus
}
#endif

#endif /* __SCUMSYSTEM_H */