
#include "ble_loopback.h"
//#include "sim_utils.h"

char str[512];
char status_str[512];

void print_baseband_status0()
{
  baseband_status0_t status;
  baseband_get_status0(&status);
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

void print_baseband_status1()
{
  baseband_status1_t status;
  baseband_get_status1(&status);
  sprintf(status_str, "Modulation LUT index: %u\r\n", status.modulation_lut_index);
  HAL_UART_transmit(UART0, (uint8_t *)status_str, strlen(status_str), 0);
  sprintf(status_str, "I AGC LUT index: %u\r\n", status.i_agc_lut_index);
  HAL_UART_transmit(UART0, (uint8_t *)status_str, strlen(status_str), 0);
  sprintf(status_str, "I DCOC LUT index: %u\r\n", status.i_dcoc_lut_index);
  HAL_UART_transmit(UART0, (uint8_t *)status_str, strlen(status_str), 0);
  sprintf(status_str, "Q AGC LUT index: %u\r\n", status.q_agc_lut_index);
  HAL_UART_transmit(UART0, (uint8_t *)status_str, strlen(status_str), 0);
  sprintf(status_str, "Q DCOC LUT index: %u\r\n", status.q_dcoc_lut_index);
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
  //baseband_send(packet, NUM_BYTES);
  // Note: typically locks up the core here
  sprintf(str, "-----BLE Loopback Test-----\r\n");
  HAL_UART_transmit(UART0, (uint8_t *)str, strlen(str), 0);

  // Check that an interrupt was generated and/or
  // that the interrupt message is correct.
  #define TIMEOUT_US 5000000
  uint32_t us_count = 0, bytes_read;
  uint8_t *rx_packet = packet + NUM_BYTES + 4;

  while (1) {

    HAL_delay(10);
    //print_baseband_status0();
    //print_baseband_status1();
    us_count++;
    if (us_count > TIMEOUT_US) {
      sprintf(str, "Timeout!\r\n");
      HAL_UART_transmit(UART0, (uint8_t *)str, strlen(str), 0);
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
        sprintf(str, "Received %u bytes: ", bytes_read);
        HAL_UART_transmit(UART0, (uint8_t *)str, strlen(str), 0);
        for (i = 0; i < bytes_read; i++) {
          sprintf(str, "%x ", rx_packet[i]);
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
  HAL_CORE_enableInterrupt();
  HAL_CORE_enableIRQ(MachineExternal_IRQn);

  system_init();
  
  //HAL_GPIO_init(GPIOA, GPIO_PIN_0);
  //HAL_GPIO_writePin(GPIOA, GPIO_PIN_0, 0);

  UART_InitTypeDef UART_init_config;
  UART_init_config.baudrate = 10000;
  UART_init_config.tx_wm = 1;

  HAL_UART_init(UART0, &UART_init_config);
  sprintf(str, "SCuM-V23B says, 'I'm alive!'\r\n");
  HAL_UART_transmit(UART0, (uint8_t *)str, strlen(str), 0);

  print_baseband_status0();

  run_ble_loopback();
}
