
#include "main.h"

char str[64];

int main() {

  uint32_t mhartid;
  asm volatile("csrr %0, mhartid" : "=r"(mhartid));
  HAL_init();

  GPIO_InitTypeDef init = {GPIO_MODE_OUTPUT, GPIO_PULL_NONE, GPIO_DS_STRONG};

  while (1) {
    //sprintf(str, "%d: %d\n", mhartid, CLINT->MSIP0);
    
    uint8_t pinVal = (uint8_t)(HAL_getTick() % 2);
    HAL_GPIO_init(GPIOA, &init, GPIO_PIN_0);
    HAL_GPIO_writePin(GPIOA, GPIO_PIN_0, pinVal);
    HAL_GPIO_init(GPIOA, &init, GPIO_PIN_1);
    HAL_GPIO_writePin(GPIOA, GPIO_PIN_1, ((pinVal==0b1u)?0b0u:0b1u));
    

    volatile uint32_t* ret = (uint32_t*)0x80004000;
    *ret = mhartid+1;
    HAL_delay(1000);
  }
}
