#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include "mmio.h"

#define RTC_TIMER_BASE                  0x5000
#define RTC_TIMER_TASK_START            (RTC_TIMER_BASE + 0x00)
#define RTC_TIMER_TASK_CLEAR            (RTC_TIMER_BASE + 0x04)
#define RTC_TIMER_TASK_TRIGOVRFLW       (RTC_TIMER_BASE + 0x08)
#define RTC_TIMER_INTERRUPT_SET         (RTC_TIMER_BASE + 0x0C)
#define RTC_TIMER_COUNTER               (RTC_TIMER_BASE + 0x10)
#define RTC_TIMER_PRESCALAR             (RTC_TIMER_BASE + 0x14)
#define RTC_TIMER_CC0                   (RTC_TIMER_BASE + 0x18)
#define RTC_TIMER_CC1                   (RTC_TIMER_BASE + 0x1C)
#define RTC_TIMER_CC2                   (RTC_TIMER_BASE + 0x20)
#define RTC_TIMER_CC3                   (RTC_TIMER_BASE + 0x24)


static inline int32_t rtc_timer_get_coutner()
{
    int32_t data = (int32_t)(reg_read32(RTC_TIMER_COUNTER));
    return data;
}

void rtc_timer_set_task_start(int8_t task_start);
void rtc_timer_set_task_clear(int8_t task_clear);
void rtc_timer_set_task_trigovrflw(int8_t task_trigovrflw);
void rtc_timer_set_interrupt_set(int8_t interrupt_set);
void rtc_timer_set_prescaler(int16_t prescaler);
void rtc_timer_set_cc0(int32_t cc0);
void rtc_timer_set_cc1(int32_t cc1);
void rtc_timer_set_cc2(int32_t cc2);
void rtc_timer_set_cc3(int32_t cc3);
