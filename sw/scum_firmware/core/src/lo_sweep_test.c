#include "lo_sweep_test.h"
#include "sim_utils.h"
#include "scum_hal_plic.h"
#include "build_config.h"

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

void run_lo_sweep_test()
{
  baseband_configure(BASEBAND_CONFIG_RADIO_MODE, BASEBAND_MODE_BLE);

  sprintf(str, "-----LO Sweep Test-----\r\n");
  HAL_UART_transmit(UART0, (uint8_t *)str, strlen(str), 0);

  int i;
  // Set the channel tuning LUTs
  for (i = 0; i < 40; i++) {
    baseband_set_lut(LUT_VCO_CT_BLE, i, i*25);
  }

  int j = 0;
  while(1){
    baseband_configure(BASEBAND_CONFIG_BLE_CHANNEL_INDEX, j++);
    if (j >= 40) {
      j = 0;
    }
    HAL_delay(1000000); // 1 microsecond
    sprintf(str, "Channel %d\r\n", j);
    HAL_UART_transmit(UART0, (uint8_t *)str, strlen(str), 0);
  }
}

int main() {
  HAL_init();
  HAL_CORE_enableGlobalInterrupt();
  HAL_CORE_enableInterrupt(MachineExternalInterrupt);
  
  UART_InitTypeDef UART_init_config;
  UART_init_config.baudrate = UART_BAUDRATE_DEFAULT;
  UART_init_config.mode = UART_MODE_TX_RX;
  UART_init_config.stopbits = UART_STOPBITS_DEFAULT;
  HAL_UART_init(UART0, &UART_init_config);  

  sprintf(str, "SCuM-V24B says, 'I'm alive!'\r\n");
  HAL_UART_transmit(UART0, (uint8_t *)str, strlen(str), 0);

  print_baseband_status0();

  // Set scum-v tuning registers
  // rtc_tune_in<3> CPU oscillator - 1 exterior / 0 interior
  // rtc_tune_in<2> ADC/RTC oscillator - 1 exterior / 0 interior
  // rtc_tune_in<1:0> MUX_CLK_OUT - 00 CPU / 01 RTC / 11 ADC
  #define SCUM_TUNING 0xA000
  // uint16_t rtc_tune_in = 0b1000;
  // reg_write16(SCUM_TUNING + 0x04, rtc_tune_in);
  
  run_lo_sweep_test();
}

void __attribute__((weak, noreturn)) __main(void) {
  while (1) {
   asm volatile ("wfi");
  }
}