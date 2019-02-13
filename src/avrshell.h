#ifndef AVRSHELL_H
#define AVRSHELL_H

#ifndef NULL
#define NULL ((void*) 0)
#endif

#ifndef PROGMEM
#define PROGMEM __attribute__((__progmem__))
#endif

#define NUM_INT_VECTS 26

#ifndef __ASSEMBLER__
#include <stdint.h>

int8_t register_int(int8_t, void (*)(void));

#endif

#endif

