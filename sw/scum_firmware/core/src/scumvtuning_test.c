#include "sim_utils.h"
#include "scumvtuning.h"
#include "scumvtuning_test.h"
#include "build_config.h"


#define BUF_SIZE 512
char str[512];
uint32_t status0[BUF_SIZE];

void print_scumvtuning()
{
    uint16_t tuneOut_adc_coarse = scumvtuning_get_tuneOut_adc_coarse();
    uint8_t tuneOut_dig = scumvtuning_get_tuneOut_dig();
    uint8_t sel_cpu_clk = scumvtuning_get_sel_cpu_clk();
    uint8_t sel_debug_clk = scumvtuning_get_sel_debug_clk();
    uint8_t bgr_tempCtrl = scumvtuning_get_bgr_tempCtrl();
    uint8_t bgr_vrefCtrl = scumvtuning_get_bgr_vrefCtrl();
    uint8_t clkOvrd = scumvtuning_get_clkOvrd();
    char status_str[512];
    sprintf(status_str, "tuneOut_adc_coarse: %u\n tuneOut_dig: %u\n sel_cpu_clk: %u\n sel_debug_clk: %u\n bgr_tempCtrl: %u\n bgr_vrefCtrl: %u\n clkOvrd: %u\n", tuneOut_adc_coarse, tuneOut_dig, sel_cpu_clk, sel_debug_clk, bgr_tempCtrl, bgr_vrefCtrl, clkOvrd);
    HAL_UART_transmit(UART0, (uint8_t *)status_str, strlen(status_str), 0);
}

void run_scumvtuning_test()
{
    print_scumvtuning();
    HAL_delay(100);
    uint16_t test_16 = 7;
    uint8_t test_8 = 7;
    scumvtuning_set_tuneOut_adc_coarse(test_16);
    scumvtuning_set_tuneOut_dig(test_8);
    scumvtuning_set_sel_cpu_clk(test_8);
    scumvtuning_set_sel_debug_clk(test_8);
    scumvtuning_set_bgr_tempCtrl(test_8);
    scumvtuning_set_bgr_vrefCtrl(test_8);
    scumvtuning_set_clkOvrd(test_8);
    HAL_delay(100);
    print_scumvtuning();
}

int main() 
{
  HAL_init();
  HAL_CORE_enableInterrupt(MachineExternalInterrupt);
  // HAL_CORE_enableIRQ(MachineExternal_IRQn);

  // system_init();
  
  UART_InitTypeDef UART_init_config;
  UART_init_config.baudrate = UART_BAUDRATE_DEFAULT;
  UART_init_config.mode = UART_MODE_TX_RX;
  UART_init_config.stopbits = UART_STOPBITS_DEFAULT;
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

  run_scumvtuning_test();
  sim_finish(); 
}

void __attribute__((weak, noreturn)) __main(void) {
  while (1) {
    asm volatile ("wfi");
  }
}