
#include "power_test.h"

volatile int done_status = 0;
char str[512];


void print_baseband_status0()
{
  baseband_status0_t status;
  baseband_get_status0(&status);
  char status_str[512];
  sprintf(status_str, "Assembler State: %u\r\n", status.assembler_state);
  HAL_UART_transmit(UART0, (uint8_t *)status_str, strlen(status_str), 0);
  sprintf(status_str, "Disassembler State: %u\r\n", status.disassembler_state);
  HAL_UART_transmit(UART0, (uint8_t *)status_str, strlen(status_str), 0);
  sprintf(status_str, "TX State: %u\r\n", status.tx_state);
  HAL_UART_transmit(UART0, (uint8_t *)status_str, strlen(status_str), 0);
  sprintf(status_str, "RX Controller State: %u\r\n", status.rx_controller_state);
  HAL_UART_transmit(UART0, (uint8_t *)status_str, strlen(status_str), 0);
  sprintf(status_str, "TX Controller State: %u\r\n", status.tx_controller_state);
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
  HAL_CORE_enableInterrupt();
  HAL_CORE_enableIRQ(MachineExternal_IRQn);
  
  //HAL_GPIO_init(GPIOA, GPIO_PIN_0);
  //HAL_GPIO_writePin(GPIOA, GPIO_PIN_0, 0);

  UART_InitTypeDef UART_init_config;
  UART_init_config.baudrate = 10000;
  

  HAL_UART_init(UART0, &UART_init_config);
  print_baseband_status0();
  sprintf(str, "SCuM-V23B says, 'I'm alive!'\r\n");
  HAL_UART_transmit(UART0, (uint8_t *)str, strlen(str), 0);
  
  uint8_t adc_i_data = 0;
  while (1) {
    HAL_delay(100);
    
    print_baseband_status0();
  }
}
