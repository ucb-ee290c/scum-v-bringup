#ifndef _CHIPYARD_HTIF_H
#define _CHIPYARD_HTIF_H

#include <stdint.h>

extern volatile uint64_t tohost;
extern volatile uint64_t fromhost;

#define HTIF_DEV_SHIFT      56
#define HTIF_DEV_MASK       0xff
#define HTIF_CMD_SHIFT      48
#define HTIF_CMD_MASK       0xff
#define HTIF_PAYLOAD_MASK   ((1UL << HTIF_CMD_SHIFT) - 1)

#define HTIF_TOHOST(dev, cmd, payload) ( \
    (((uint64_t)(dev) & HTIF_DEV_MASK) << HTIF_DEV_SHIFT) | \
    (((uint64_t)(cmd) & HTIF_CMD_MASK) << HTIF_CMD_SHIFT) | \
    ((uint64_t)(payload) & HTIF_PAYLOAD_MASK))

#if __riscv_xlen == 64
extern long htif_syscall(uint64_t, uint64_t, uint64_t, unsigned long);
#else
extern long htif_syscall(uint32_t, uint32_t, uint32_t, unsigned long);
#endif

#endif /* _CHIPYARD_HTIF_H */