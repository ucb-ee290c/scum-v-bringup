#include "sensor_adc_test.h"
#include "sensor_adc.h"

char str[512];

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

void kick_oscillator()
{
  uint8_t khigh = 0b11111111;
  uint8_t klow = 0b00000000;
  uint8_t num_kicks = 100;
  for (int i = 0; i < num_kicks; i++)
  {
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
  HAL_CORE_enableInterrupt();
  HAL_CORE_enableIRQ(MachineExternal_IRQn);

  system_init();
  
  UART_InitTypeDef UART_init_config;
  UART_init_config.baudrate = 100000;
  UART_init_config.tx_wm = 1;
  
  HAL_UART_init(UART0, &UART_init_config);
  sprintf(str, "SCuM-V22 says, 'I'm alive!'\r\n");
  HAL_UART_transmit(UART0, (uint8_t *)str, strlen(str), 0);
  kick_oscillator();
  run_sensor_adc_test();
}
