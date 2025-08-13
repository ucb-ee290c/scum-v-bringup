#include "sim_utils.h"
#include "sensor_adc.h"
#include "sensor_adc_test.h"


#define BUF_SIZE 512
char str[512];
uint32_t status0[BUF_SIZE];

void print_sensor_adc_status0()
{
  uint32_t status0 = sensor_adc_get_status0();
  char status_str[512];
  uint8_t counter_n = (status0 & 0x3F);
  uint8_t counter_p = ((status0 >> 6) & 0x3F);
  sprintf(status_str, "CNT_N: %u\tCNT_P: %u\r\n", counter_n, counter_p);
  HAL_UART_transmit(UART0, (uint8_t *)status_str, strlen(status_str), 0);
}

void print_sensor_adc_data()
{
  int32_t data = sensor_adc_get_data();
  char data_str[512];
  sprintf(data_str, "DATA: %d\r\n", data);
  HAL_UART_transmit(UART0, (uint8_t *)data_str, strlen(data_str), 0);
}

void log_counters()
{
  uint8_t idac_val = 16;
  uint8_t bias_p = 0;
  uint8_t bias_n = 0;
  uint8_t adc_tuning_0 = (bias_p << 7) | (bias_n << 6) | idac_val;
  sensor_adc_set_tuning0(adc_tuning_0);
  // Verify status registers after new IDAC config
  print_sensor_adc_status0();

  while(1) {
    //idac_val = (idac_val + 1) % 64;
    adc_tuning_0 = (bias_p << 7) | (bias_n << 6) | idac_val;
    sensor_adc_set_tuning0(adc_tuning_0);
    sprintf(str, "Logging counters, IDAC: %u\r\n", idac_val);
    //kick_oscillator();
    HAL_UART_transmit(UART0, (uint8_t *)str, strlen(str), 0);

    for(int i = 0; i < BUF_SIZE; i++)
    {
      status0[i] = reg_read32(SENSOR_ADC_STATUS0);
    }

    for(int i = 0; i < BUF_SIZE; i++)
    {
      char counter_str[512];
      uint8_t buffer_p = (uint8_t)(status0[i] & 0x3F);
      uint8_t buffer_n = (uint8_t)((status0[i] >> 6) & 0x3F);
      sprintf(str, "CNT_N: %u\tCNT_P: %u\r\n", buffer_n, buffer_p);
      HAL_UART_transmit(UART0, (uint8_t *)str, strlen(str), 0);
    }
  }
}

void kick_oscillator()
{
  uint8_t khigh = 0b11111111;
  uint8_t klow = 0b00000000;
  uint8_t num_kicks = 100;
  for (int i = 0; i < num_kicks; i++)
  {
    if (i % 5 == 0) {
      sprintf(str, "Oscillator kick %d\r\n", i);
      HAL_UART_transmit(UART0, (uint8_t *)str, strlen(str), 0);
    }
    sensor_adc_set_tuning0(khigh);
    HAL_delay(10);
    sensor_adc_set_tuning0(klow);
    HAL_delay(10);
  }

}

void run_sensor_adc_test()
{
  uint8_t idac_val = 0b001010;
  uint8_t bias_p = 0;
  uint8_t bias_n = 0;
  uint8_t adc_tuning_0 = (bias_p << 7) | (bias_n << 6) | idac_val;
  sensor_adc_set_tuning0(adc_tuning_0);
  // Verify status registers after new IDAC config
  print_sensor_adc_status0();

  while(1)
  {
    print_sensor_adc_data();
    HAL_delay(100);
    print_sensor_adc_status0();
    HAL_delay(100);
  }
}

int main() 
{
  HAL_init();
  HAL_CORE_enableInterrupt(MachineExternalInterrupt);
  // HAL_CORE_enableIRQ(MachineExternal_IRQn);

  // system_init();
  
  UART_InitTypeDef UART_init_config;
  UART_init_config.baudrate = 921600;
  UART_init_config.mode = UART_MODE_TX_RX;
  UART_init_config.stopbits = UART_STOPBITS_2;
  HAL_UART_init(UART0, &UART_init_config);
  
  sprintf(str, "SCuM-V24B says, 'I'm alive!'\r\n");
  HAL_UART_transmit(UART0, (uint8_t *)str, strlen(str), 0);

  uint16_t idle_count = 0;
  for(idle_count = 0; idle_count < 10; idle_count++)
  {
    sprintf(str, "Idling on startup: %d\r\n", idle_count);
    HAL_UART_transmit(UART0, (uint8_t *)str, strlen(str), 0);
    HAL_delay(10);
  }

  kick_oscillator();
  //log_counters();
  run_sensor_adc_test();
  sim_finish(); 
}

void __attribute__((weak, noreturn)) __main(void) {
  while (1) {
    asm volatile ("wfi");
  }
}


