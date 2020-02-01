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

