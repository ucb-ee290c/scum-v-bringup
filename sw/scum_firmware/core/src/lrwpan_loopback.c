
#include "lrwpan_loopback.h"
#include "sim_utils.h"
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

void run_lrwpan_loopback()
{
  int i;
  // Switch mode to LRWPAN
  baseband_configure(BASEBAND_CONFIG_RADIO_MODE, BASEBAND_MODE_LRWPAN);


  // Set the SHR to 0xA700 and CRC seed to 0x0000. 
  // The LR-WPAN channel index doesn’t matter, so perhaps start with 0.
  baseband_configure(BASEBAND_CONFIG_SHR, 0xA700);
  baseband_configure(BASEBAND_CONFIG_CRC_SEED, 0x0000);


  // Generate a packet in memory. 
  // The packet length is automatically prepended, so no worries there.
  #define NUM_BYTES 32
  volatile uint8_t packet[3 * NUM_BYTES];
  for (i = 0; i < NUM_BYTES; i++) {
    packet[i] = i;
  }

  sprintf(str, "packet: %x\r\n", packet);
  HAL_UART_transmit(UART0, (uint8_t *)str, strlen(str), 0);
  sprintf(str, "rx_packet: %x\r\n", packet + NUM_BYTES);
  HAL_UART_transmit(UART0, (uint8_t *)str, strlen(str), 0);

  sprintf(str, "Packet: ");
  HAL_UART_transmit(UART0, (uint8_t *)str, strlen(str), 0);
  for (i = 0; i < NUM_BYTES; i++) {
    sprintf(str, "%x ", packet[i]);
    HAL_UART_transmit(UART0, (uint8_t *)str, strlen(str), 0);
  }
  sprintf(str, "\r\n");
  HAL_UART_transmit(UART0, (uint8_t *)str, strlen(str), 0);

  // Send the packet using a debug command.
  baseband_debug(packet, NUM_BYTES);
  sprintf(str, "-----LRWPAN Loopback Test-----\r\n");
  HAL_UART_transmit(UART0, (uint8_t *)str, strlen(str), 0);

  #define TIMEOUT_US 3
  uint32_t us_count = 0, bytes_read;
  uint8_t *rx_packet = packet + NUM_BYTES + 4;

  while (1) {
    us_count += 1;
    if (us_count > TIMEOUT_US) {
      sprintf(str, "Timeout after %u us!\r\n", us_count);
      HAL_UART_transmit(UART0, (uint8_t *)str, strlen(str), 0);
      sim_finish();
      return;
    }
    if ((us_count % (TIMEOUT_US / 10)) == 0) {
      sprintf(str, "us_count: %u\r\n", us_count);
      HAL_UART_transmit(UART0, (uint8_t *)str, strlen(str), 0);
    }
    
    switch (debug_status) {
      case DEBUG_TX_FAIL:
      case DEBUG_RX_FAIL:
        // TODO: Exit with error code
        sim_finish();
        return;

      case DEBUG_RX_FINISH:
        bytes_read = baseband_rxfinish_message();
        sprintf(str, "%u bytes\r\n", bytes_read);
        HAL_UART_transmit(UART0, (uint8_t *)str, strlen(str), 0);
        for (i = 0; i < bytes_read; i++) {
          sprintf(str, "%x ", rx_packet[i]);
          HAL_UART_transmit(UART0, (uint8_t *)str, strlen(str), 0);
        }
        sprintf(str, "\r\n");
        HAL_UART_transmit(UART0, (uint8_t *)str, strlen(str), 0);
        sim_finish();
        return;
      
      default:
        break;
    };
  }
}

int main() {
  HAL_init();
  HAL_CORE_enableInterrupt(MachineExternalInterrupt);
  HAL_CORE_enableInterrupt(MachineExternalInterrupt);
  // HAL_CORE_enableIRQ(MachineExternal_IRQn);

  // system_init();
  
  //HAL_GPIO_init(GPIOA, GPIO_PIN_0);
  //HAL_GPIO_writePin(GPIOA, GPIO_PIN_0, 0);

  UART_InitTypeDef UART_init_config;
  UART_init_config.baudrate = UART_BAUDRATE_DEFAULT;
  UART_init_config.mode = UART_MODE_TX_RX;
  UART_init_config.stopbits = UART_STOPBITS_DEFAULT;
  HAL_UART_init(UART0, &UART_init_config);

  sprintf(str, "SCuM-V24B says, 'I'm alive!'\r\n");
  HAL_UART_transmit(UART0, (uint8_t *)str, strlen(str), 0);

  // Set scum-v tuning registers
  // rtc_tune_in<3> CPU oscillator - 1 exterior / 0 interior
  // rtc_tune_in<2> ADC/RTC oscillator - 1 exterior / 0 interior
  // rtc_tune_in<1:0> MUX_CLK_OUT - 00 CPU / 01 RTC / 11 ADC
  #define SCUM_TUNING 0xA000
  uint16_t rtc_tune_in = 0b1000;
  reg_write16(SCUM_TUNING + 0x04, rtc_tune_in);
  
  uint8_t counter = 0;
  uint8_t adc_i_data = 0;
  run_lrwpan_loopback();
}

void __attribute__((weak, noreturn)) __main(void) {
  while (1) {
   asm volatile ("wfi");
  }
}