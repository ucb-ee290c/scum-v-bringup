#include "sensor_adc.h"



void sensor_adc_set_tuning0(uint32_t tuning0)
{
    reg_write32(SENSOR_ADC_TUNING0, tuning0);
}

void sensor_adc_set_chop_clk_div_1(uint32_t chop_clk_div_1)
{
    reg_write32(SENSOR_ADC_CHOP_CLK_DIV_1, chop_clk_div_1);
}

void sensor_adc_set_chop_clk_div_2(uint32_t chop_clk_div_2)
{
    reg_write32(SENSOR_ADC_CHOP_CLK_DIV_2, chop_clk_div_2);
}

void sensor_adc_set_chop_clk_en(uint8_t chop_clk_en)
{
    reg_write8(SENSOR_ADC_CHOP_CLK_EN, chop_clk_en);
}
