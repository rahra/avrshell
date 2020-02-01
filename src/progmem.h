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

#ifndef PROGMEM_H
#define PROGMEM_H


#include <stdint.h>


int pstrncmp(const char *ram, const char *pmem, int);
int8_t pstrlen(const char *pmem);

int pgm_word(const void*);
void *pgm_ptr(const void*);
int8_t pgm_byte(const void*);

int8_t read_eeprom(const void*);
void write_eeprom(const void*, int8_t);

int8_t read_fuse(int addr);
int8_t read_sig(int addr);

#endif

