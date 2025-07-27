#include "sensor_adc.h"

void sensor_adc_set_tuning0(uint32_t tuning0)
{
    reg_write32(SENSOR_ADC_TUNING0, tuning0);
}

void sensor_adc_set_tuning1(uint32_t tuning1)
{
    reg_write32(SENSOR_ADC_TUNING1, tuning1);
}

void sensor_adc_set_tuning2(uint32_t tuning2)
{
    reg_write32(SENSOR_ADC_TUNING2, tuning2);
}

void sensor_adc_set_tuning3(uint32_t tuning3)
{
    reg_write32(SENSOR_ADC_TUNING3, tuning3);
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

void sensor_adc_set_dsp_control(uint8_t dsp_control) {
    reg_write8(SENSOR_ADC_DSP_CONTROL, dsp_control);
}

void sensor_adc_set_auto_mux(uint8_t auto_mux) {
    reg_write8(SENSOR_ADC_AUTO_MUX, auto_mux);
}
