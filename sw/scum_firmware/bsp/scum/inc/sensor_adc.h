#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include "mmio.h"

#define SENSOR_ADC_BASE             0xB000
#define SENSOR_ADC_STATUS0          (SENSOR_ADC_BASE + 0x00)
#define SENSOR_ADC_DATA             (SENSOR_ADC_BASE + 0x04)
#define SENSOR_ADC_TUNING0          (SENSOR_ADC_BASE + 0x08)
#define SENSOR_ADC_CHOP_CLK_DIV_1   (SENSOR_ADC_BASE + 0x0C)
#define SENSOR_ADC_CHOP_CLK_DIV_2   (SENSOR_ADC_BASE + 0x10)
#define SENSOR_ADC_CHOP_CLK_EN      (SENSOR_ADC_BASE + 0x14)
#define SENSOR_ADC_DSP_CONTROL      (SENSOR_ADC_BASE + 0x18)


static inline int32_t sensor_adc_get_data()
{
    int32_t data = (int32_t)(reg_read32(SENSOR_ADC_DATA));
    return data;
}

/*
* Bottom 6 bits - COUNTER_N
* Next 6 bits   - COUNTER_P
*/
static inline uint32_t sensor_adc_get_status0()
{
    uint32_t status0 = reg_read32(SENSOR_ADC_STATUS0);
    return status0;
}


void sensor_adc_set_tuning0(uint32_t tuning0);
void sensor_adc_set_chop_clk_div_1(uint32_t chop_clk_div_1);
void sensor_adc_set_chop_clk_div_2(uint32_t chop_clk_div_2);
void sensor_adc_set_chop_clk_en(uint8_t chop_clk_en);
void sensor_adc_set_dsp_control(uint32_t dsp_control);

