
#include "scum_hal_uart.h"

void HAL_UART_setTxWmLevel(UART_TypeDef *UARTx, uint32_t wm) {
  SET_BITS(UARTx->TXCTRL, (wm << UART_TXCTRL_TXCNT_POS) & UART_TXCTRL_TXCNT_MSK);
}

void HAL_UART_setRxWmLevel(UART_TypeDef *UARTx, uint32_t wm) {
  SET_BITS(UARTx->RXCTRL, (wm << UART_RXCTRL_RXCNT_POS) & UART_RXCTRL_RXCNT_MSK);
}

void HAL_UART_init(UART_TypeDef *UARTx, UART_InitTypeDef *UART_init) {
  CLEAR_BITS(UARTx->RXCTRL, UART_RXCTRL_RXEN_MSK);
  CLEAR_BITS(UARTx->TXCTRL, UART_TXCTRL_TXEN_MSK);

  if (READ_BITS((uint32_t)UART_init->mode, 0b01)) {
    SET_BITS(UARTx->RXCTRL, UART_RXCTRL_RXEN_MSK);
  }
  
  if (READ_BITS((uint32_t)UART_init->mode, 0b10)) {
    SET_BITS(UARTx->TXCTRL, UART_TXCTRL_TXEN_MSK);
  }

  CLEAR_BITS(UARTx->TXCTRL, UART_TXCTRL_NSTOP_MSK);
  CLEAR_BITS(UARTx->TXCTRL, (uint32_t)UART_init->stopbits);
  
  // baudrate setting
  // f_baud = f_sys / (div + 1)
  UARTx->DIV = (SYS_CLK_FREQ / UART_init->baudrate) - 1;
}



// ip.txwm := (txq.io.count < txwm)
// ip.rxwm := (rxq.io.count > rxwm)
uint8_t HAL_UART_checkTxWm(UART_TypeDef *UARTx) {
  return READ_BITS(UARTx->IP, UART_IP_TXWM_MSK) >> UART_IP_TXWM_POS;
}

uint8_t HAL_UART_checkRxWm(UART_TypeDef *UARTx) {
  return READ_BITS(UARTx->IP, UART_IP_RXWM_MSK) >> UART_IP_RXWM_POS;
}

void HAL_UART_finishTX(UART_TypeDef *UARTx) {
  HAL_UART_setTxWmLevel(UARTx, 1);
  while (!HAL_UART_checkTxWm(UARTx));
}

Status HAL_UART_receive(UART_TypeDef *UARTx, uint8_t *data, uint16_t size, uint32_t timeout) {
  while (size > 0) {
    while (READ_BITS(UARTx->RXDATA, UART_RXDATA_EMPTY_MSK)) {
      // return TIMEOUT;
    }
    *data = UARTx->RXDATA;
    data += sizeof(uint8_t);
    size -= 1;
  }
  return OK;
}

Status HAL_UART_transmit(UART_TypeDef *UARTx, uint8_t *data, uint16_t size, uint32_t timeout) {
  while (size > 0) {
    while (READ_BITS(UARTx->TXDATA, UART_TXDATA_FULL_MSK)) {
      // return TIMEOUT;
    }
    UARTx->TXDATA = *data;
    data += sizeof(uint8_t);
    size -= 1;
  }
  return OK;
}
