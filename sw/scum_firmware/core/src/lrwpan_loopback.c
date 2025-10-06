
#include "lrwpan_loopback.h"
#include "sim_utils.h"
#include "build_config.h"

char str[512];


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

  #define TIMEOUT_MS 10
  uint32_t ms_count = 0, bytes_read;
  uint8_t *rx_packet = packet + NUM_BYTES + 4;

  while (1) {
    ms_count += 1;
    HAL_delay(1);
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
        // sim_finish();
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
        // sim_finish();
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
  HAL_PLIC_enable(0, TX_FINISH);
  HAL_PLIC_enable(0, RX_FINISH);
  HAL_PLIC_enable(0, TX_ERROR);
  HAL_PLIC_enable(0, RX_ERROR);
  HAL_PLIC_enable(0, RX_START);


  UART_InitTypeDef UART_init_config;
  UART_init_config.baudrate = UART_BAUDRATE_DEFAULT;
  UART_init_config.mode = UART_MODE_TX_RX;
  UART_init_config.stopbits = UART_STOPBITS_DEFAULT;
  HAL_UART_init(UART0, &UART_init_config);  

  sprintf(str, "SCuM-V24B says, 'I'm alive!'\r\n");
  HAL_UART_transmit(UART0, (uint8_t *)str, strlen(str), 0);

  while(1) {
    run_lrwpan_loopback();
  }
}

void __attribute__((weak, noreturn)) __main(void) {
  while (1) {
   asm volatile ("wfi");
  }
}