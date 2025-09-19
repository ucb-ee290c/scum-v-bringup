#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include "mmio.h"

#define SCUMVTUNING_BASE                              0xA000
#define SCUMVTUNING_ADC_TUNE_OUT_COARSE              (SCUMVTUNING_BASE + 0x00)
#define SCUMVTUNING_RAMP_GENERATOR_IDAC_CONTROL      (SCUMVTUNING_BASE + 0x02)
#define SCUMVTUNING_RAMP_GENERATOR_RX_OUT_SEL        (SCUMVTUNING_BASE + 0x03)
#define SCUMVTUNING_DIG_TUNE_OUT                     (SCUMVTUNING_BASE + 0x04)
#define SCUMVTUNING_CPU_SEL                          (SCUMVTUNING_BASE + 0x05)
#define SCUMVTUNING_ADC_RESET                        (SCUMVTUNING_BASE + 0x06)
#define SCUMVTUNING_DIG_RESET                        (SCUMVTUNING_BASE + 0x07)
#define SCUMVTUNING_BGR_TEMP_CTRL                    (SCUMVTUNING_BASE + 0x08)
#define SCUMVTUNING_BGR_VREF_CTRL                    (SCUMVTUNING_BASE + 0x09)
#define SCUMVTUNING_CURRENT_SRC_LEFT_CTRL            (SCUMVTUNING_BASE + 0x0A)
#define SCUMVTUNING_CURRENT_SRC_RIGHT_CTRL           (SCUMVTUNING_BASE + 0x0B)
#define SCUMVTUNING_CLK_OVRD                         (SCUMVTUNING_BASE + 0x0C)
#define SCUMVTUNING_RAMP_GENERATOR_CLK_MUX_SEL       (SCUMVTUNING_BASE + 0x0D)
#define SCUMVTUNING_RAMP_GENERATOR_ENABLE            (SCUMVTUNING_BASE + 0x0E)
#define SCUMVTUNING_RAMP_GENERATOR_FREQ_STEP_START   (SCUMVTUNING_BASE + 0x0F)
#define SCUMVTUNING_RAMP_GENERATOR_NUM_FREQ_STEPS    (SCUMVTUNING_BASE + 0x10)
#define SCUMVTUNING_RAMP_GENERATOR_NUM_CYCLES_PER_FREQ (SCUMVTUNING_BASE + 0x11)
#define SCUMVTUNING_RAMP_GENERATOR_NUM_IDLE_CYCLES   (SCUMVTUNING_BASE + 0x14)
#define SCUMVTUNING_RAMP_GENERATOR_RST               (SCUMVTUNING_BASE + 0x18)
#define SCUMVTUNING_VCO_CAP_TUNING                   (SCUMVTUNING_BASE + 0x19)
#define SCUMVTUNING_VCO_ENABLE                       (SCUMVTUNING_BASE + 0x1A)
#define SCUMVTUNING_VCO_DIV_ENABLE                   (SCUMVTUNING_BASE + 0x1B)
#define SCUMVTUNING_PA_ENABLE                        (SCUMVTUNING_BASE + 0x1C)
#define SCUMVTUNING_PA_BYPASS                        (SCUMVTUNING_BASE + 0x1D)
#define SCUMVTUNING_PA_INPUT_MUX_SEL                 (SCUMVTUNING_BASE + 0x1E)


static inline uint16_t scumvtuning_get_adc_tune_out_coarse(void)
{
    return (uint16_t)reg_read16(SCUMVTUNING_ADC_TUNE_OUT_COARSE);
}

static inline uint8_t scumvtuning_get_ramp_generator_idac_control(void)
{
    return (uint8_t)reg_read8(SCUMVTUNING_RAMP_GENERATOR_IDAC_CONTROL);
}

static inline uint8_t scumvtuning_get_dig_tune_out(void)
{
    return (uint8_t)reg_read8(SCUMVTUNING_DIG_TUNE_OUT);
}

static inline uint8_t scumvtuning_get_cpu_sel(void)
{
    return (uint8_t)reg_read8(SCUMVTUNING_CPU_SEL);
}

static inline uint8_t scumvtuning_get_bgr_temp_ctrl(void)
{
    return (uint8_t)reg_read8(SCUMVTUNING_BGR_TEMP_CTRL);
}

static inline uint8_t scumvtuning_get_bgr_vref_ctrl(void)
{
    return (uint8_t)reg_read8(SCUMVTUNING_BGR_VREF_CTRL);
}

static inline uint8_t scumvtuning_get_clk_ovrd(void)
{
    return (uint8_t)reg_read8(SCUMVTUNING_CLK_OVRD);
}

void scumvtuning_set_adc_tune_out_coarse(uint16_t value);
void scumvtuning_set_ramp_generator_idac_control(uint8_t value);
void scumvtuning_set_dig_tune_out(uint8_t value);
void scumvtuning_set_cpu_sel(uint8_t value);
void scumvtuning_set_bgr_temp_ctrl(uint8_t value);
void scumvtuning_set_bgr_vref_ctrl(uint8_t value);
void scumvtuning_set_clk_ovrd(uint8_t value);
