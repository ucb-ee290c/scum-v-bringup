
#ifndef __SCUM_HAL_GPIO_H
#define __SCUM_HAL_GPIO_H

#ifdef __cplusplus
extern "C" {
#endif

#include "scum.h"

typedef enum {
  GPIO_PIN_0 = 0b0001U
} GPIO_Pin;

void HAL_GPIO_init(GPIO_TypeDef *GPIOx, GPIO_Pin pin);

uint8_t HAL_GPIO_readPin(GPIO_TypeDef *GPIOx, GPIO_Pin pin);

void HAL_GPIO_writePin(GPIO_TypeDef *GPIOx, GPIO_Pin pin, uint8_t value);

#ifdef __cplusplus
}
#endif

#endif /* __SCUM_HAL_GPIO_H */
