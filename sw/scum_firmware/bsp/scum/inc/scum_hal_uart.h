
#ifndef __SCUM_HAL_UART_H
#define __SCUM_HAL_UART_H

#ifdef __cplusplus
extern "C" {
#endif

#include "scum.h"
#include "scum_hal.h"

typedef struct {
  uint32_t baudrate;
  uint32_t tx_wm;
  uint32_t rx_wm;
} UART_InitTypeDef;

// the default baudrate divisor is 0xAD, 173

void HAL_UART_init(UART_TypeDef *UARTx, UART_InitTypeDef *UART_init);

void wait_for_tx(UART_TypeDef *UARTx);

Status HAL_UART_receive(UART_TypeDef *UARTx, uint8_t *data, uint16_t size, uint32_t timeout);

Status HAL_UART_transmit(UART_TypeDef *UARTx, uint8_t *data, uint16_t size, uint32_t timeout);

#ifdef __cplusplus
}
#endif

#endif /* __SCUM_HAL_UART_H */