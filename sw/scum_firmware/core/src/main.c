
#include "main.h"

volatile int done_status = 0;
char str[512];


typedef struct plic_context_control
{
  uint32_t priority_threshold;
  uint32_t claim_complete;
} plic_context_control_t __attribute__ ((aligned (0x1000)));


uint32_t *const plic_enables      =               (uint32_t* const) 0xc002000; // Context [0..15871], sources bitmap registers [0..31]
uint32_t *const plic_priorities   =               (uint32_t* const) 0xc000000; // priorities [0..1023]
plic_context_control_t *const plic_ctx_controls = (plic_context_control_t* const) 0xc200000; // Priority threshold & claim / complete for context [0..15871]

void plic_set_bit(uint32_t* const target, uint32_t index)
{
  uint32_t reg_index = index >> 5;
  uint32_t bit_index = index & 0x1F;
  *target |= (1 << bit_index);
}

void plic_enable_for_hart(uint32_t hart_id, uint32_t irq_id) {
  uint32_t* base = plic_enables + 32 * hart_id;
  plic_set_bit(base, irq_id);
}

void plic_set_priority(uint32_t irq_id, uint32_t priority) {
  plic_priorities[irq_id] = priority;
}

uint32_t plic_claim_irq(uint32_t hart_id) {
  return plic_ctx_controls[hart_id].claim_complete;
}

void plic_complete_irq(uint32_t hart_id, uint32_t irq_id){
  plic_ctx_controls[hart_id].claim_complete = irq_id;
}


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
  // Switch mode to LRWPAN
  baseband_configure(BASEBAND_CONFIG_RADIO_MODE, BASEBAND_MODE_LRWPAN);


  // Set the SHR to 0xA700 and CRC seed to 0x0000. 
  // The LR-WPAN channel index doesn’t matter, so perhaps start with 0.
  baseband_configure(BASEBAND_CONFIG_SHR, 0xA700);
  baseband_configure(BASEBAND_CONFIG_CRC_SEED, 0x0000);


  // Generate a packet in memory. 
  // The packet length is automatically prepended, so no worries there.
  #define NUM_BYTES 32
  uint8_t packet[NUM_BYTES];
  for (int i = 0; i < NUM_BYTES; i++) {
    packet[i] = i;
  }

  // Send the packet using a debug command.
  baseband_debug(packet, NUM_BYTES);
  // Note: typically locks up the core here
  sprintf(str, "-----LRWPAN Loopback Test-----\r\n");
  HAL_UART_transmit(UART0, (uint8_t *)str, strlen(str), 0);
  HAL_delay(1000);

  // Check that an interrupt was generated and/or
  // that the interrupt message is correct.
  #define TIMEOUT_MS 5000
  uint32_t ms_count = 0;
  uint8_t loop_cont = 1;
  uint32_t msg;
  while (1) {
    HAL_delay(1);
    ms_count++;
    if (ms_count < TIMEOUT_MS) {
      // print TX error message
      msg = baseband_txerror_message();
      sprintf(str, "TXEM: %u\r\n", msg);
      HAL_UART_transmit(UART0, (uint8_t *)str, strlen(str), 0);
      // print RX error message
      msg = baseband_rxerror_message();
      sprintf(str, "RXEM: %u\r\n", msg);
      HAL_UART_transmit(UART0, (uint8_t *)str, strlen(str), 0);
      // print RX finish message
      msg = baseband_rxfinish_message();
      sprintf(str, "RXFM: %u\r\n", msg);
      HAL_UART_transmit(UART0, (uint8_t *)str, strlen(str), 0);
    }
    else {
      break;
    }
  }
}

void run_ble_loopback()
{
  // Switch mode to LRWPAN
  baseband_configure(BASEBAND_CONFIG_RADIO_MODE, BASEBAND_MODE_BLE);


  // This should be correct by default, but set the Access Address to 0x8E89BED6 and 
  // CRC seed to 0x555555 and BLE channel index to 37, 38, or 39.
  baseband_configure(BASEBAND_CONFIG_ACCESS_ADDRESS, 0x8E89BED6);
  baseband_configure(BASEBAND_CONFIG_CRC_SEED, 0x555555);
  baseband_configure(BASEBAND_CONFIG_BLE_CHANNEL_INDEX, 37);


  // Generate a packet in memory. 
  // The packet length is automatically prepended, so no worries there.
  #define NUM_BYTES 32
  uint8_t packet[NUM_BYTES];
  packet[0] = 0;
  packet[1] = 0;
  for (int i = 2; i < NUM_BYTES; i++) {
    packet[i] = i;
  }

  // Send the packet using a debug command.
  baseband_debug(packet, NUM_BYTES);
  // Note: typically locks up the core here
  sprintf(str, "-----BLE Loopback Test-----\r\n");
  HAL_UART_transmit(UART0, (uint8_t *)str, strlen(str), 0);
  HAL_delay(1000);

  // Check that an interrupt was generated and/or
  // that the interrupt message is correct.
  #define TIMEOUT_MS 5000
  uint32_t ms_count = 0;
  uint8_t loop_cont = 1;
  uint32_t msg;
  while (1) {
    HAL_delay(1);
    ms_count++;
    if (ms_count < TIMEOUT_MS) {
      /*
      // print TX error message
      msg = baseband_txerror_message();
      sprintf(str, "TXEM: %u\r\n", msg);
      HAL_UART_transmit(UART0, (uint8_t *)str, strlen(str), 0);
      // print RX error message
      msg = baseband_rxerror_message();
      sprintf(str, "RXEM: %u\r\n", msg);
      HAL_UART_transmit(UART0, (uint8_t *)str, strlen(str), 0);
      // print RX finish message
      msg = baseband_rxfinish_message();
      sprintf(str, "RXFM: %u\r\n", msg);
      HAL_UART_transmit(UART0, (uint8_t *)str, strlen(str), 0);
      */
    }
    else {
      break;
    }
  }
}


int main() {
    
  HAL_init();
  
  //HAL_GPIO_init(GPIOA, GPIO_PIN_0);
  //HAL_GPIO_writePin(GPIOA, GPIO_PIN_0, 0);

  UART_InitTypeDef UART_init_config;
  UART_init_config.baudrate = 100000;
  

  HAL_UART_init(UART0, &UART_init_config);
  print_baseband_status0();
  sprintf(str, "SCuM-V23 says, 'I'm alive!'\r\n");
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
  while (1) {
    HAL_delay(50);
    
    print_baseband_status0();
  }
}
