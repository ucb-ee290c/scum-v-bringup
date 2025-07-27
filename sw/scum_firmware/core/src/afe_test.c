#include "sim_utils.h"
#include "afe.h"
#include "afe_test.h"

#define BUF_SIZE 512
char str[BUF_SIZE];

#define AFE_BASE                    0x6000
#define AFE_ADC_OUTPUT_REG          (AFE_BASE + 0x00)
// #define AFE_DIVIDER_REF_CONFIG      (AFE_BASE + 0x02)
// #define AFE_DIVIDER_SAMPLE_CONFIG   (AFE_BASE + 0x08)
#define AFE_I_SEL                   (AFE_BASE + 0x0C)
#define AFE_ADC_DIV_SWITCH          (AFE_BASE + 0x10)
#define AFE_R2R_DAC_INPUT           (AFE_BASE + 0x14)
#define AFE_SENSOR_SEL              (AFE_BASE + 0x18)
#define AFE_SENSOR_NET_CONFIG       (AFE_BASE + 0x1C)
#define AFE_FEEDBACK_CONFIG         (AFE_BASE + 0x20)
#define AFE_ADC_INPUT_SEL           (AFE_BASE + 0x24)
#define AFE_VGA_CONFIG              (AFE_BASE + 0x28)
#define AFE_SWCAP_CLOCK1            (AFE_BASE + 0x2C)
#define AFE_SWCAP_CLOCK2            (AFE_BASE + 0x30)
#define AFE_GENERAL_TRIM_AFE_IN     (AFE_BASE + 0x34)
// #define AFE_MODE                    (AFE_BASE + 0x38)
#define AFE_TRIGGER                 (AFE_BASE + 0x40)

// int main() {
//   HAL_init();
//   system_init();
//   int result = 1;
//   for (result = 0; result < 1000000; result++) asm("nop");
//   sim_finish();
// }


void print_afetuning_status() {

    // int16_t adc_out       = afe_get_adc_output_reg();
    int16_t adc_out = reg_read16(AFE_ADC_OUTPUT_REG);
    // int32_t div_ref       = reg_read32(AFE_DIVIDER_REF_CONFIG);
    // int32_t div_sample    = reg_read32(AFE_DIVIDER_SAMPLE_CONFIG);
    uint8_t i_sel         = reg_read8 (AFE_I_SEL);
    uint8_t adc_div_sw    = reg_read8 (AFE_ADC_DIV_SWITCH);
    int16_t r2r_dac       = reg_read16(AFE_R2R_DAC_INPUT);
    uint8_t sensor_sel    = reg_read8 (AFE_SENSOR_SEL);
    uint8_t sensor_net    = reg_read8 (AFE_SENSOR_NET_CONFIG);
    uint8_t feedback_cfg  = reg_read8 (AFE_FEEDBACK_CONFIG);
    uint8_t adc_in_sel    = reg_read8 (AFE_ADC_INPUT_SEL);
    uint8_t vga_cfg       = reg_read8 (AFE_VGA_CONFIG);
    uint8_t swcap1        = reg_read8 (AFE_SWCAP_CLOCK1);
    uint8_t swcap2        = reg_read8 (AFE_SWCAP_CLOCK2);
    int16_t trim_afe_in   = reg_read16(AFE_GENERAL_TRIM_AFE_IN);
    // uint8_t mode          = reg_read8 (AFE_MODE);
    uint8_t trigger       = reg_read8 (AFE_TRIGGER);

    sprintf(str,
        // "ADC_OUT: %d\n"
        // "DIV_REF: %ld\n"
        // "DIV_CFG: %ld\n"
        "I_SEL: %u\n"
        "ADC_DIV_SW: %u\n"
        "R2R_DAC: %d\n"
        "SENSOR_SEL: %u\n"
        "SENSOR_NET: %u\n"
        "FEEDBACK: %u\n"
        "ADC_IN_SEL: %u\n"
        "VGA_CFG: %u\n"
        "SWCAP1: %u\n"
        "SWCAP2: %u\n"
        "TRIM_AFE_IN: %d\n\n"
        // "MODE: %u\n"
        "TRIGGER: %u\n",
        adc_out,
        // div_ref,
        // div_sample,
        i_sel,
        adc_div_sw,
        r2r_dac,
        sensor_sel,
        sensor_net,
        feedback_cfg,
        adc_in_sel,
        vga_cfg,
        swcap1,
        swcap2,
        trim_afe_in,
        // mode,
        trigger
    );
    HAL_UART_transmit(UART0, (uint8_t*)str, strlen(str), 0);
}

void run_afetuning_test() {

    print_afetuning_status();
    HAL_delay(100);

    int32_t  test32   = 7;
    int16_t  test16   = 7;
    uint8_t  test8    = 7;
    // uint8_t  testbool = 1;

    /* write it into every AFE register: */
    // afe_set_divider_ref_config(test32);
    // afe_set_divider_sample_config(test32);
    reg_write8(AFE_I_SEL, test8);
    reg_write16(AFE_R2R_DAC_INPUT, test16);
    reg_write8(AFE_SENSOR_SEL, test8);
    reg_write8(AFE_SENSOR_NET_CONFIG, test8);
    reg_write8(AFE_FEEDBACK_CONFIG, test8);
    reg_write8(AFE_ADC_INPUT_SEL, test8);
    reg_write8(AFE_VGA_CONFIG, test8);
    reg_write8(AFE_SWCAP_CLOCK1, test8);
    reg_write8(AFE_SWCAP_CLOCK2, test8);
    reg_write16(AFE_GENERAL_TRIM_AFE_IN, test16);
    reg_write8(AFE_TRIGGER, test8);

    // afe_set_mode(test8);

    HAL_delay(100);
    print_afetuning_status();
}

int main()
{
    HAL_init();
    HAL_CORE_enableInterrupt();
    HAL_CORE_enableIRQ(MachineExternal_IRQn);

    system_init();

    UART_InitTypeDef uart_cfg = {
        .baudrate = 921600,
        .mode     = UART_MODE_TX_RX,
        .stopbits = UART_STOPBITS_2
    };
    HAL_UART_init(UART0, &uart_cfg);

    sprintf(str, "AFE-Tuning Test Alive!\r\n");
    HAL_UART_transmit(UART0, (uint8_t*)str, strlen(str), 0);

    for (uint16_t i = 0; i < 10; i++) {
        sprintf(str, "Idling: %u\r\n", i);
        HAL_UART_transmit(UART0, (uint8_t*)str, strlen(str), 0);
        HAL_delay(10);
    }

    run_afetuning_test();
    sim_finish();
    return 0;
}
