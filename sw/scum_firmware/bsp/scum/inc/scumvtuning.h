#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include "mmio.h"

#define SCUMVTUNING_BASE                    0xA000
#define SCUMVTUNING_TUNEOUT_ADC_COARSE      (SCUMVTUNING_BASE + 0x00)
#define SCUMVTUNING_TUNEOUT_DIG             (SCUMVTUNING_BASE + 0x02)
#define SCUMVTUNING_SEL_CPU_CLK             (SCUMVTUNING_BASE + 0x03)
#define SCUMVTUNING_SEL_DEBUG_CLK           (SCUMVTUNING_BASE + 0x04)
#define SCUMVTUNING_BGR_TEMP_CTRL           (SCUMVTUNING_BASE + 0x05)
#define SCUMVTUNING_BGT_VREF_CTRL           (SCUMVTUNING_BASE + 0x06)
#define SCUMVTUNING_CLK_OVRD                (SCUMVTUNING_BASE + 0x07)


static inline int16_t scumvtuning_get_tuneOut_adc_coarse()
{
    int16_t data = (int16_t)(reg_read16(SCUMVTUNING_TUNEOUT_ADC_COARSE));
    return data;
}

static inline int8_t scumvtuning_get_tuneOut_dig()
{
    int8_t data = (int8_t)(reg_read8(SCUMVTUNING_TUNEOUT_DIG));
    return data;
}

static inline int8_t scumvtuning_get_sel_cpu_clk()
{
    int8_t data = (int8_t)(reg_read8(SCUMVTUNING_SEL_CPU_CLK));
    return data;
}

static inline int8_t scumvtuning_get_sel_debug_clk()
{
    int8_t data = (int8_t)(reg_read8(SCUMVTUNING_SEL_DEBUG_CLK));
    return data;
}

static inline int8_t scumvtuning_get_bgr_tempCtrl()
{
    int8_t data = (int8_t)(reg_read8(SCUMVTUNING_BGR_TEMP_CTRL));
    return data;
}

static inline int8_t scumvtuning_get_bgr_vrefCtrl()
{
    int8_t data = (int8_t)(reg_read8(SCUMVTUNING_BGT_VREF_CTRL));
    return data;
}

static inline int8_t scumvtuning_get_clkOvrd()
{
    int8_t data = (int8_t)(reg_read8(SCUMVTUNING_CLK_OVRD));
    return data;
}

void scumvtuning_set_tuneOut_adc_coarse(int16_t tuneOut_adc_coarse);
void scumvtuning_set_tuneOut_dig(int8_t tuneOut_dig);
void scumvtuning_set_sel_cpu_clk(int8_t sel_cpu_clk);
void scumvtuning_set_sel_debug_clk(int8_t sel_debug_clk);
void scumvtuning_set_bgr_tempCtrl(int8_t bgr_tempCtrl);
void scumvtuning_set_bgr_vrefCtrl(int8_t bgr_vrefCtrl);
void scumvtuning_set_clkOvrd(int8_t clkOvrd);
