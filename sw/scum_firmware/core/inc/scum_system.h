
#ifndef __SCUMSYSTEM_H
#define __SCUMSYSTEM_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>
#include <stdio.h>
#include <string.h>

//#include "baseband.h"


void enable_fpu(void);
void print_fcsr();

#ifdef __cplusplus
}
#endif

#endif /* __SCUMSYSTEM_H */