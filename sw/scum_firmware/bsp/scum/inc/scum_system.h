
#ifndef __SCUMSYSTEM_H
#define __SCUMSYSTEM_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>
#include <stdio.h>
#include <string.h>

enum IRQ_SOURCE {
  RX_ERROR = 10,
  RX_START = 11,
  RX_FINISH = 12,
  TX_ERROR = 13,
  TX_FINISH = 14,
  IF_COUNTER_THRESHOLD = 15
};

enum DEBUG_STATUS {
  NONE,
  DEBUG_TX_FINISH,
  DEBUG_TX_FAIL,
  DEBUG_RX_FINISH,
  DEBUG_RX_FAIL
};
extern volatile enum DEBUG_STATUS debug_status;


#ifdef __cplusplus
}
#endif

#endif /* __SCUMSYSTEM_H */