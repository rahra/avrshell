#ifndef PROGMEM_H
#define PROGMEM_H


#include <avr/io.h>


int pstrncmp(const char *ram, const char *pmem, int);
int8_t pstrlen(const char *pmem);

int pgm_word(const void*);
void *pgm_ptr(const void*);
int8_t pgm_byte(const void*);


#endif

