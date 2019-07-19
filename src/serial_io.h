#ifndef SERIAL_IO_H
#define SERIAL_IO_H


#include <avr/io.h>


void init_serial();
void sys_read_flush();
uint8_t sys_read(char *, uint8_t);
uint8_t sys_write(const char *, uint8_t);
uint8_t sys_pwrite(const char *, uint8_t);
void sys_send(char);
uint8_t sys_peek_serial(void);


#endif

