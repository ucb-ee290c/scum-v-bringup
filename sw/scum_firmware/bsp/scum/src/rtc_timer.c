#include "rtc_timer.h"

void rtc_timer_set_task_start(int8_t task_start) {
    reg_write8(RTC_TIMER_TASK_START, task_start);
}

void rtc_timer_set_task_clear(int8_t task_clear) {
    reg_write8(RTC_TIMER_TASK_CLEAR, task_clear);    
}

void rtc_timer_set_task_trigovrflw(int8_t task_trigovrflw) {
    reg_write8(RTC_TIMER_TASK_TRIGOVRFLW, task_trigovrflw);
}

void rtc_timer_set_interrupt_set(int8_t interrupt_set) {
    reg_write8(RTC_TIMER_INTERRUPT_SET, interrupt_set);
}

void rtc_timer_set_prescaler(int16_t prescaler) {
    reg_write16(RTC_TIMER_PRESCALAR, prescaler);
}

void rtc_timer_set_cc0(int32_t cc0) {
    reg_write32(RTC_TIMER_CC0, cc0);
}

void rtc_timer_set_cc1(int32_t cc1) {
    reg_write32(RTC_TIMER_CC1, cc1);
}

void rtc_timer_set_cc2(int32_t cc2) {
    reg_write32(RTC_TIMER_CC2, cc2);
}

void rtc_timer_set_cc3(int32_t cc3) {
    reg_write32(RTC_TIMER_CC3, cc3);
}
