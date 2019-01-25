#ifndef PARSER_H
#define PARSER_H

#include <avr/io.h>

#ifndef NULL
#define NULL ((void*) 0)
#endif

#define E_OK 0
#define E_NULL -1
#define E_NOPARM -2
#define E_CONVERR -3

char nibble_to_ascx(char a);
int8_t is_eos(char a);
int8_t is_xdigit(char a);
int8_t asc_to_nibble(int8_t a);
int asctoi(const char *s);
char *next_token(char *s);
int8_t get_int_param(char **cmd, int *parm);

#endif

