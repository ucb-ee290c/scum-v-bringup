#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include "mmio.h"

 #define AFE_BASE                    0x6000
// #define AFE_ADC_OUTPUT_REG          (AFE_BASE + 0x00)
// // #define AFE_DIVIDER_REF_CONFIG      (AFE_BASE + 0x02)
// // #define AFE_DIVIDER_SAMPLE_CONFIG   (AFE_BASE + 0x08)
// #define AFE_I_SEL                   (AFE_BASE + 0x0C)
// #define AFE_ADC_DIV_SWITCH          (AFE_BASE + 0x10)
// #define AFE_R2R_DAC_INPUT           (AFE_BASE + 0x14)
// #define AFE_SENSOR_SEL              (AFE_BASE + 0x18)
// #define AFE_SENSOR_NET_CONFIG       (AFE_BASE + 0x1C)
// #define AFE_FEEDBACK_CONFIG         (AFE_BASE + 0x20)
// #define AFE_ADC_INPUT_SEL           (AFE_BASE + 0x24)
// #define AFE_VGA_CONFIG              (AFE_BASE + 0x28)
// #define AFE_SWCAP_CLOCK1            (AFE_BASE + 0x2C)
// #define AFE_SWCAP_CLOCK2            (AFE_BASE + 0x30)
// #define AFE_GENERAL_TRIM_AFE_IN     (AFE_BASE + 0x34)
// // #define AFE_MODE                    (AFE_BASE + 0x38)
// #define AFE_TRIGGER                 (AFE_BASE + 0x40)


// static inline int16_t afe_get_adc_output_reg()
// {
//     int16_t data = (int16_t)(reg_read16(AFE_ADC_OUTPUT_REG));
//     return data;
// }

// // void afe_set_divider_ref_config(int32_t divider_ref_config);
// // void afe_set_divider_sample_config(int32_t divider_sample_config);
// void afe_set_i_sel(int8_t i_sel);
// void afe_set_adc_div_switch(int8_t adc_div_switch);
// void afe_set_r2r_dac_input(int16_t r2r_dac_input);
// void afe_set_sensor_sel(int8_t sensor_sel);
// void afe_set_sensor_net_config(int8_t sensor_net_config);
// void afe_set_feedback_config(int8_t feedback_config);
// void afe_set_adc_input_sel(int8_t adc_input_sel);
// void afe_set_vga_config(int8_t vga_config);
// void afe_set_swcap_clock1(int8_t swcap_clock1);
// void afe_set_swcap_clock2(int8_t swcap_clock2);
// void afe_set_general_trim_afe_in(int16_t general_trim_afe_in);
// // void afe_set_mode(int8_t mode);

// static inline int8_t afe_get_trigger()
// {
//     int8_t data = (int8_t)(reg_read8(AFE_TRIGGER));
//     return data;
// }

// void afe_set_trigger(int8_t trigger);
