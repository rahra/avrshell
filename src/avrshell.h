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

