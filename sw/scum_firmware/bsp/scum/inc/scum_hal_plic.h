
#ifndef __SCUM_HAL_PLIC_H
#define __SCUM_HAL_PLIC_H

#ifdef __cplusplus
extern "C" {
#endif

#include "scum_hal.h"

void HAL_PLIC_disable(uint32_t hart_id, uint32_t irq_id);

void HAL_PLIC_enable(uint32_t hart_id, uint32_t irq_id);

void HAL_PLIC_setPriority(uint32_t irq_id, uint32_t priority);

void HAL_PLIC_setPriorityThreshold(uint32_t hart_id, uint32_t priority);

uint32_t HAL_PLIC_claimIRQ(uint32_t hart_id);

void HAL_PLIC_completeIRQ(uint32_t hart_id, uint32_t irq_id);


#ifdef __cplusplus
}
#endif

#endif /* __SCUM_HAL_PLIC_H */
