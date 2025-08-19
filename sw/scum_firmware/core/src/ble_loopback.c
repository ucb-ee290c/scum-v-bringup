
#include "ble_loopback.h"
// #include "sim_utils.h"
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

void run_ble_loopback()
{
  int i;
  baseband_configure(BASEBAND_CONFIG_RADIO_MODE, BASEBAND_MODE_BLE);

  // This should be correct by default, but set the Access Address to 0x8E89BED6 and 
  // CRC seed to 0x555555 and BLE channel index to 37, 38, or 39.
  baseband_configure(BASEBAND_CONFIG_ACCESS_ADDRESS, 0x8E89BED6);
  baseband_configure(BASEBAND_CONFIG_CRC_SEED, 0x555555);
  baseband_configure(BASEBAND_CONFIG_BLE_CHANNEL_INDEX, 37);

  // Generate a packet in memory. 
  // The packet length is automatically prepended, so no worries there.
  #define NUM_BYTES 32
  volatile uint8_t packet[NUM_BYTES*3];
  packet[0] = 30;
  packet[1] = 30;
  for (i = 2; i < NUM_BYTES; i++) {
    packet[i] = i;
  }

  // Send the packet using a debug command.
  baseband_debug(packet, NUM_BYTES);
  // Note: typically locks up the core here
  sprintf(str, "-----BLE Loopback Test-----\r\n");
  HAL_UART_transmit(UART0, (uint8_t *)str, strlen(str), 0);

  // Check that an interrupt was generated and/or
  // that the interrupt message is correct.
  #define TIMEOUT_MS 3000
  uint32_t ms_count = 0, bytes_read;
  uint8_t *rx_packet = packet + NUM_BYTES + 4;

  while (1) {
    ms_count++;
    HAL_delay(1);
    // sprintf(str, "ms_count: %u\r\n", ms_count);
    // HAL_UART_transmit(UART0, (uint8_t *)str, strlen(str), 0);
    // HAL_UART_finishTX(UART0);
    if (ms_count > TIMEOUT_MS) {
      sprintf(str, "Timeout!\r\n");
      HAL_UART_transmit(UART0, (uint8_t *)str, strlen(str), 0);
      HAL_UART_finishTX(UART0);
      //sim_finish();
      return;
    }
    switch (debug_status) {
      case DEBUG_TX_FAIL:
      case DEBUG_RX_FAIL:
        // TODO: Exit with error code
        //sim_finish();
        return;

      case DEBUG_RX_FINISH:
        bytes_read = baseband_rxfinish_message();
        for (i = 0; i < bytes_read; i++) {
          sprintf(str, "%u ", rx_packet[i]);
          HAL_UART_transmit(UART0, (uint8_t *)str, strlen(str), 0);
        }
        sprintf(str, "\r\n");
        HAL_UART_transmit(UART0, (uint8_t *)str, strlen(str), 0);
        //sim_finish();
        return;
      
      default:
        break;
    };
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
  
  // Set the channel tuning LUTs for BLE operation
  int i;
  for (i = 0; i < 40; i++) {
    baseband_set_lut(LUT_VCO_CT_BLE, i, i*1638);
  }

  while(1) {
    run_ble_loopback();
  }
}

void __attribute__((weak, noreturn)) __main(void) {
  while (1) {
   asm volatile ("wfi");
  }
}
