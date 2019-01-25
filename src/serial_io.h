#ifndef SERIAL_IO_H
#define SERIAL_IO_H


#include <avr/io.h>


void init_serial();
void sys_read_flush();
unsigned char sys_read(char *);
void sys_write(const char *, unsigned char);
void sys_pwrite(const char *, unsigned char);
void sys_send(char);


#endif

