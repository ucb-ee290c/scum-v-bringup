#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include "mmio.h"

#define SENSOR_ADC_BASE             0xB000
#define SENSOR_ADC_DATA             (SENSOR_ADC_BASE + 0x00)
#define SENSOR_ADC_STATUS0          (SENSOR_ADC_BASE + 0x04)
#define SENSOR_ADC_STATUS1          (SENSOR_ADC_BASE + 0x08)
#define SENSOR_ADC_STATUS2          (SENSOR_ADC_BASE + 0x0C)
#define SENSOR_ADC_STATUS3          (SENSOR_ADC_BASE + 0x10)
#define SENSOR_ADC_STATUS4          (SENSOR_ADC_BASE + 0x14)
#define SENSOR_ADC_STATUS5          (SENSOR_ADC_BASE + 0x18)
#define SENSOR_ADC_TUNING0          (SENSOR_ADC_BASE + 0x1C)
#define SENSOR_ADC_TUNING1          (SENSOR_ADC_BASE + 0x1D)
#define SENSOR_ADC_TUNING2          (SENSOR_ADC_BASE + 0x1E)
#define SENSOR_ADC_TUNING3          (SENSOR_ADC_BASE + 0x1F)
#define SENSOR_ADC_CHOP_CLK_DIV_1   (SENSOR_ADC_BASE + 0x20)
#define SENSOR_ADC_CHOP_CLK_DIV_2   (SENSOR_ADC_BASE + 0x24)
#define SENSOR_ADC_CHOP_CLK_EN      (SENSOR_ADC_BASE + 0x28)
#define SENSOR_ADC_DSP_CONTROL      (SENSOR_ADC_BASE + 0x2C)
#define SENSOR_ADC_AUTO_MUX         (SENSOR_ADC_BASE + 0x30) // Is this read only?
#define SENSOR_ADC_CDC_MUX          (SENSOR_ADC_BASE + 0x31)


static inline int32_t sensor_adc_get_data()
{
    int32_t data = (int32_t)(reg_read32(SENSOR_ADC_DATA));
    return data;
}

/*
* Bottom 6 bits - COUNTER_N
* Next 6 bits   - COUNTER_P
*/
// static inline uint32_t sensor_adc_get_status()
// {
//     uint32_t status0 = sensor_adc_get_status0();
//     uint32_t status1 = sensor_adc_get_status1();
//     uint32_t status2 = sensor_adc_get_status2();
//     uint32_t status3 = sensor_adc_get_status3();
//     uint32_t status4 = sensor_adc_get_status4();
//     uint32_t status5 = sensor_adc_get_status5();
//     return status0;
// }

static inline uint32_t sensor_adc_get_status0()
{
    uint32_t status0 = reg_read32(SENSOR_ADC_STATUS0);
    return status0;
}

static inline uint32_t sensor_adc_get_status1()
{
    uint32_t status1 = reg_read32(SENSOR_ADC_STATUS1);
    return status1;
}

static inline uint32_t sensor_adc_get_status2()
{
    uint32_t status2 = reg_read32(SENSOR_ADC_STATUS2);
    return status2;
}

static inline uint32_t sensor_adc_get_status3()
{
    uint32_t status3 = reg_read32(SENSOR_ADC_STATUS3);
    return status3;
}

static inline uint32_t sensor_adc_get_status4()
{
    uint32_t status4 = reg_read32(SENSOR_ADC_STATUS4);
    return status4;
}

static inline uint32_t sensor_adc_get_status5()
{
    uint32_t status5 = reg_read32(SENSOR_ADC_STATUS5);
    return status5;
}

static inline uint8_t sensor_adc_get_cdc_mux()
{
    uint8_t cdc_mux = reg_read8(SENSOR_ADC_CDC_MUX);
    return cdc_mux;
}

void sensor_adc_set_tuning0(uint32_t tuning0);
void sensor_adc_set_tuning1(uint32_t tuning1);
void sensor_adc_set_tuning2(uint32_t tuning2);
void sensor_adc_set_tuning3(uint32_t tuning3);
void sensor_adc_set_chop_clk_div_1(uint32_t chop_clk_div_1);
void sensor_adc_set_chop_clk_div_2(uint32_t chop_clk_div_2);
void sensor_adc_set_chop_clk_en(uint8_t chop_clk_en);
void sensor_adc_set_dsp_control(uint8_t dsp_control);
void sensor_adc_set_auto_mux(uint8_t auto_mux);
