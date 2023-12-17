
#include "scum_hal_uart.h"

void HAL_UART_init(UART_TypeDef *UARTx, UART_InitTypeDef *UART_init) {
  SET_BITS(UARTx->RXCTRL, UART_RXCTRL_RXEN_MSK);
  SET_BITS(UARTx->TXCTRL, UART_TXCTRL_TXEN_MSK);
  HAL_UART_setRxWmLevel(UARTx, UART_init->rx_wm);
  HAL_UART_setTxWmLevel(UARTx, UART_init->tx_wm);

  UARTx->DIV = (SYS_CLK_FREQ / UART_init->baudrate) - 1;

  // baudrate setting
  // f_baud = f_sys / (div + 1)
}

void HAL_UART_setTxWmLevel(UART_TypeDef *UARTx, uint32_t wm) {
  SET_BITS(UARTx->TXCTRL, (wm << UART_TXCTRL_TXCNT_POS) & UART_TXCTRL_TXCNT_MSK);
}

void HAL_UART_setRxWmLevel(UART_TypeDef *UARTx, uint32_t wm) {
  SET_BITS(UARTx->RXCTRL, (wm << UART_RXCTRL_RXCNT_POS) & UART_RXCTRL_RXCNT_MSK);
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
    while (!HAL_UART_checkRxWm(UARTx));
    *data = UARTx->RXDATA;
    data += sizeof(uint8_t);
    size -= 1;
  }
  return OK;
}

Status HAL_UART_transmit(UART_TypeDef *UARTx, uint8_t *data, uint16_t size, uint32_t timeout) {
  while (size > 0) {
    while (!HAL_UART_checkTxWm(UARTx));
    UARTx->TXDATA = *data;
    data += sizeof(uint8_t);
    size -= 1;
  }
  return OK;
}

