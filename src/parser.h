/* Copyright 2019-2020 Bernhard R. Fischer, 4096R/8E24F29D <bf@abenteuerland.at>
 *
 * This file is part of AVRshell.
 *
 * Smrender is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3 of the License.
 *
 * Smrender is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with smrender. If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef PARSER_H
#define PARSER_H

#include <avr/io.h>

#define E_OK 0
#define E_NULL -1
#define E_NOPARM -2
#define E_CONVERR -3
#define E_TRUNC -4

char nibble_to_ascx(char a);
int8_t is_eos(char a);
int8_t is_xdigit(char a);
int8_t asc_to_nibble(int8_t a);
int asctoi(const char *s);
char *next_token(char *s);
int8_t get_int_param(char **cmd, int *parm);
int8_t get_command(const char *cmd, uint8_t rlen);
int8_t lint_to_str(long int n, char *buf, int len);
int strlen(const char *s);


enum {C_IN, C_OUT, C_DUMP, C_PDUMP, C_SBI, C_CBI, C_LDS, C_STS, C_HELP,
   C_EDUMP, C_STE, C_CPU, C_UPTIME, C_RUN, C_STOP, C_NEW, C_PS};

#endif

