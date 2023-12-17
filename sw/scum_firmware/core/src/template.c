
#include "template.h"

#define SCUM_TUNING 0xA000

char str[512];

void print_baseband_status0() {
  baseband_status0_t status;
  baseband_get_status0(&status);
  char status_str[512];
  sprintf(status_str, "Assembler State: %u\r\n", status.assembler_state);
  HAL_UART_transmit(UART0, (uint8_t *)status_str, strlen(status_str), 0);
  sprintf(status_str, "Disassembler State: %u\r\n", status.disassembler_state);
  HAL_UART_transmit(UART0, (uint8_t *)status_str, strlen(status_str), 0);
  sprintf(status_str, "TX State: %u\r\n", status.tx_state);
  HAL_UART_transmit(UART0, (uint8_t *)status_str, strlen(status_str), 0);
  sprintf(status_str, "RX Controller State: %u\r\n",
          status.rx_controller_state);
  HAL_UART_transmit(UART0, (uint8_t *)status_str, strlen(status_str), 0);
  sprintf(status_str, "TX Controller State: %u\r\n",
          status.tx_controller_state);
  HAL_UART_transmit(UART0, (uint8_t *)status_str, strlen(status_str), 0);
  sprintf(status_str, "Controller State: %u\r\n", status.controller_state);
  HAL_UART_transmit(UART0, (uint8_t *)status_str, strlen(status_str), 0);
  sprintf(status_str, "ADC I data: %u\r\n", status.adc_i_data);
  HAL_UART_transmit(UART0, (uint8_t *)status_str, strlen(status_str), 0);
  sprintf(status_str, "ADC Q data: %u\r\n", status.adc_q_data);
  HAL_UART_transmit(UART0, (uint8_t *)status_str, strlen(status_str), 0);
}

int main() {
  HAL_init();
  system_init();

  UART_InitTypeDef UART_init_config;
  UART_init_config.baudrate = 115200;

  HAL_UART_init(UART0, &UART_init_config);
  print_baseband_status0();
  sprintf(str, "SCuM-V23 says, 'I'm alive!'\r\n");
  HAL_UART_transmit(UART0, (uint8_t *)str, strlen(str), 0);

  // Set SCuM-V tuning registers.
  // rtc_tune_in<3> CPU oscillator - 1 exterior / 0 interior
  // rtc_tune_in<2> ADC/RTC oscillator - 1 exterior / 0 interior
  // rtc_tune_in<1:0> MUX_CLK_OUT - 00 CPU / 01 RTC / 11 ADC
  uint16_t rtc_tune_in = 0b1000;
  reg_write16(SCUM_TUNING + 0x04, rtc_tune_in);

  while (1) {
    HAL_delay(200);
    print_baseband_status0();
  }
}
