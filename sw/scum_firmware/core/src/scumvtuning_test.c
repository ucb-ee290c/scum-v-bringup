#include "sim_utils.h"
#include "scumvtuning.h"
#include "scumvtuning_test.h"
#include "build_config.h"


#define BUF_SIZE 512
char str[512];
uint32_t status0[BUF_SIZE];

void print_scumvtuning()
{
    uint16_t adc_tune = scumvtuning_get_adc_tune_out_coarse();
    uint8_t idac = scumvtuning_get_ramp_generator_idac_control();
    uint8_t dig_tune = scumvtuning_get_dig_tune_out();
    uint8_t cpu_sel = scumvtuning_get_cpu_sel();
    uint8_t bgr_temp = scumvtuning_get_bgr_temp_ctrl();
    uint8_t bgr_vref = scumvtuning_get_bgr_vref_ctrl();
    uint8_t clk_ovrd = scumvtuning_get_clk_ovrd();
    char status_str[512];
    sprintf(status_str,
            "adc_tune: %u\n idac: %u\n dig_tune: %u\n cpu_sel: %u\n bgr_temp: %u\n bgr_vref: %u\n clk_ovrd: %u\n",
            adc_tune,
            idac,
            dig_tune,
            cpu_sel,
            bgr_temp,
            bgr_vref,
            clk_ovrd);
    HAL_UART_transmit(UART0, (uint8_t *)status_str, strlen(status_str), 0);
}

void run_scumvtuning_test()
{
    print_scumvtuning();
    HAL_delay(100);
    uint16_t test_16 = 7;
    uint8_t test_8 = 7;
    scumvtuning_set_adc_tune_out_coarse(test_16);
    scumvtuning_set_ramp_generator_idac_control(test_8);
    scumvtuning_set_dig_tune_out(test_8);
    scumvtuning_set_cpu_sel(test_8);
    scumvtuning_set_bgr_temp_ctrl(test_8);
    scumvtuning_set_bgr_vref_ctrl(test_8);
    scumvtuning_set_clk_ovrd(test_8);
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
