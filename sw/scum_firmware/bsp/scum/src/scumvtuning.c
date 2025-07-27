#include "scumvtuning.h"

void scumvtuning_set_tuneOut_adc_coarse(int16_t tuneOut_adc_coarse) {
    reg_write16(SCUMVTUNING_TUNEOUT_ADC_COARSE, tuneOut_adc_coarse);
}

void scumvtuning_set_tuneOut_dig(int8_t tuneOut_dig) {
    reg_write8(SCUMVTUNING_TUNEOUT_DIG, tuneOut_dig);
}

void scumvtuning_set_sel_cpu_clk(int8_t sel_cpu_clk) {
    reg_write8(SCUMVTUNING_SEL_CPU_CLK, sel_cpu_clk);
}

void scumvtuning_set_sel_debug_clk(int8_t sel_debug_clk) {
    reg_write8(SCUMVTUNING_SEL_DEBUG_CLK, sel_debug_clk);
}

void scumvtuning_set_bgr_tempCtrl(int8_t bgr_tempCtrl) {
    reg_write8(SCUMVTUNING_BGR_TEMP_CTRL, bgr_tempCtrl);
}

void scumvtuning_set_bgr_vrefCtrl(int8_t bgr_vrefCtrl) {
    reg_write8(SCUMVTUNING_BGT_VREF_CTRL, bgr_vrefCtrl);
}

void scumvtuning_set_clkOvrd(int8_t clkOvrd) {
    reg_write8(SCUMVTUNING_CLK_OVRD, clkOvrd);
}

