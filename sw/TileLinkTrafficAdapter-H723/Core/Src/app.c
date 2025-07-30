/*
 * app.c
 *
 *  Created on: Aug 22, 2022
 *      Author: TK
 */

#include "app.h"
#include <string.h>

#define BOOT_SELECT_ADDR            0x00002000
#define BOOTROM_BASE_ADDR           0x00010000

#define CLINT_MSIP_ADDR             0x02000000
#define CLINT_MTIME_ADDR            0x0200BFF8

#define UART_TXDATA_ADDR            0x54000000
#define UART_RXDATA_ADDR            0x54000004
#define UART_TXCTRL_ADDR            0x54000008
#define UART_RXCTRL_ADDR            0x5400000C
#define UART_IE_ADDR                0x54000010
#define UART_IP_ADDR                0x54000014
#define UART_DIV_ADDR               0x54000018

#define DTIM_BASE_ADDR              0x80000000

#define GPIO_BASE_ADDR              0x10012000


extern TIM_HandleTypeDef htim1;
extern UART_HandleTypeDef huart3;

TileLinkController tl;

char str[128];

#define SERIAL_BUFFER_SIZE 64

uint8_t serial_rx_buffer[SERIAL_BUFFER_SIZE];
uint8_t serial_tx_buffer[SERIAL_BUFFER_SIZE];

GPIO_PinState tl_clk_prev_state = GPIO_PIN_RESET;

typedef enum {
  APP_STATE_INVALID = -1,
  APP_STATE_IDLE = 0,
  APP_STATE_FRAME_PENDING = 1,
  APP_STATE_WAITING_FOR_RX = 2,
} AppState;

AppState app_state = APP_STATE_INVALID;

GPIO_PinState tl_in_ready_prev_state = GPIO_PIN_RESET;
GPIO_PinState tl_in_ready_state = GPIO_PIN_RESET;

void HAL_UARTEx_RxEventCallback(UART_HandleTypeDef *huart, uint16_t size) {
  if (app_state != APP_STATE_IDLE) {
    return;
  }

  if (huart == &huart3) {
    // Zero out the entire frame to prevent stale data from previous transactions.
    memset(&tl.tx_frame, 0, sizeof(TileLinkFrame));

    // Unpack the incoming packet byte-by-byte to avoid struct padding/alignment issues.
    uint32_t address;
    uint64_t data;

    // Use memcpy from the serial buffer into local, correctly-sized variables.
    memcpy(&address, serial_rx_buffer + 4, sizeof(uint32_t));
    memcpy(&data,    serial_rx_buffer + 8, sizeof(uint64_t));

    // Now, assign the unpacked values to the struct members.
    // The C compiler will handle placing them correctly in the padded struct.
    tl.tx_frame.chanid   = serial_rx_buffer[0];
    tl.tx_frame.opcode   = serial_rx_buffer[1] & 0b111;
    tl.tx_frame.param    = (serial_rx_buffer[1] >> 4) & 0b111;
    tl.tx_frame.corrupt  = (serial_rx_buffer[1] >> 7) & 0b1;
    tl.tx_frame.size     = serial_rx_buffer[2];
    tl.tx_frame.tl_union = serial_rx_buffer[3];
    tl.tx_frame.address  = address; // This is now a 64-bit value, as the struct expects
    tl.tx_frame.data     = data;
    
    // Hardcode fields not sent from the host
    tl.tx_frame.source   = 0;
    tl.tx_frame.last     = 1;

    app_state = APP_STATE_FRAME_PENDING;
  }

  HAL_UARTEx_ReceiveToIdle_DMA(&huart3, serial_rx_buffer, 32);
}

uint8_t APP_getUsrButton() {
  return HAL_GPIO_ReadPin(GPIOC, GPIO_PIN_13) ? 0 : 1;
}

void APP_setLED(uint8_t state) {
  HAL_GPIO_WritePin(GPIOA, GPIO_PIN_5, state);
}

void APP_init() {
  HAL_TIM_PWM_Start(&htim1, TIM_CHANNEL_1);
  app_state = APP_STATE_IDLE;

  HAL_UARTEx_ReceiveToIdle_DMA(&huart3, serial_rx_buffer, 32);
}


void APP_main() {
  // Poll the TL clock.
  GPIO_PinState tl_clk_state = HAL_GPIO_ReadPin(TL_CLK_GPIO_Port, TL_CLK_Pin);


  // Process TL transactions on the positive clock edge.
  if (tl_clk_state == GPIO_PIN_SET && tl_clk_prev_state == GPIO_PIN_RESET) {
    tl_in_ready_state = HAL_GPIO_ReadPin(TL_IN_READY_GPIO_Port, TL_IN_READY_Pin);
    
    // Pass the current IN_READY state to the controller, not the previous cycle's state.
    tl.tl_in_ready_prev_state = (uint16_t)tl_in_ready_state;
    TL_update(&tl);
    tl_in_ready_prev_state = tl_in_ready_state;
  }

  if (tl_clk_state != tl_clk_prev_state) {
    tl_clk_prev_state = tl_clk_state;
  }

  // Process any pending TL frames.
  switch (app_state) {
    case APP_STATE_FRAME_PENDING: {
      TL_transmit(&tl);
      app_state = APP_STATE_WAITING_FOR_RX;
      break;
    }
    case APP_STATE_WAITING_FOR_RX: {
      if (tl.rx_finished) {
        TL_deserialize(&tl.rx_frame);
        *(serial_tx_buffer) = tl.rx_frame.chanid;
        *(serial_tx_buffer + 1) = (tl.rx_frame.corrupt << 7) | (tl.rx_frame.param << 4) | tl.rx_frame.opcode;
        *(serial_tx_buffer + 2) = tl.rx_frame.size;
        *(serial_tx_buffer + 3) = tl.rx_frame.tl_union;
        // Use memcpy to avoid unaligned access issues
        uint32_t address_32 = (uint32_t)tl.rx_frame.address;
        memcpy(serial_tx_buffer + 4, &address_32, sizeof(address_32));
        memcpy(serial_tx_buffer + 8, &tl.rx_frame.data, sizeof(tl.rx_frame.data));

        HAL_UART_Transmit(&huart3, serial_tx_buffer, 16, 1000);
        app_state = APP_STATE_IDLE;
      }
      break;
    }
    case APP_STATE_IDLE:
    default: {
      break;
    }
  }
}
