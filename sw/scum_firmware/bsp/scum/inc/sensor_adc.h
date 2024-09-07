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

// 1st stage chopper clock divider
void sensor_adc_set_chop_clk_div_1(uint32_t chop_clk_div_1);

// 2nd stage chopper clock divider
void sensor_adc_set_chop_clk_div_2(uint32_t chop_clk_div_2);

// ADC_CHOP_CLK_EN<0> - Enable 1st stage chopper
// ADC_CHOP_CLK_EN<1> - Enable 2nd stage chopper
void sensor_adc_set_chop_clk_en(uint8_t chop_clk_en);

// ADC_DSP_CTRL<0> - Enable dechopper in DSP chain
// ADC_DSP_CTRL<1> - Select chopper clock used in the
// dechopper ADC_DSP_CTRL<5:2> - Dechopping clock
// delay, from 0 to 15 cycles
void sensor_adc_set_dsp_control(uint32_t dsp_control);

