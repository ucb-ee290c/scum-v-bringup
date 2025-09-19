#include "scumvtuning.h"

void scumvtuning_set_adc_tune_out_coarse(uint16_t value) {
    reg_write16(SCUMVTUNING_ADC_TUNE_OUT_COARSE, value);
}

void scumvtuning_set_ramp_generator_idac_control(uint8_t value) {
    reg_write8(SCUMVTUNING_RAMP_GENERATOR_IDAC_CONTROL, value);
}

void scumvtuning_set_dig_tune_out(uint8_t value) {
    reg_write8(SCUMVTUNING_DIG_TUNE_OUT, value);
}

void scumvtuning_set_cpu_sel(uint8_t value) {
    reg_write8(SCUMVTUNING_CPU_SEL, value);
}

void scumvtuning_set_bgr_temp_ctrl(uint8_t value) {
    reg_write8(SCUMVTUNING_BGR_TEMP_CTRL, value);
}

void scumvtuning_set_bgr_vref_ctrl(uint8_t value) {
    reg_write8(SCUMVTUNING_BGR_VREF_CTRL, value);
}

void scumvtuning_set_clk_ovrd(uint8_t value) {
    reg_write8(SCUMVTUNING_CLK_OVRD, value);
}
