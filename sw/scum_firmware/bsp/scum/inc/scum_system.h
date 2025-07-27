
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
  RX_START = 29,
  RX_FINISH = 26,
  TX_ERROR = 8,
  TX_FINISH = 28
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