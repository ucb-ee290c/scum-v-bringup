#include "sensor_adc.h"

inline int32_t sensor_adc_get_data()
{
    int32_t data = (int32_t)(reg_read32(SENSOR_ADC_DATA));
    return data;
}

inline uint32_t sensor_adc_get_status0()
{
    uint32_t status0 = reg_read32(SENSOR_ADC_STATUS0);
    return status0;
}

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
