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

#ifndef PROCESS_H
#define PROCESS_H

#ifndef __ASSEMBLER__
#include <stdint.h>
#endif

// maximum number of processes
#define MAX_PROCS 5
// number of bytes used per process in the process list
#define PROC_LIST_ENTRY 4
// process stack size
#define STACK_SIZE 128
// process states
#define PSTATE_UNUSED 0
#define PSTATE_RUN 1
#define PSTATE_WAIT 2
#define PSTATE_ZOMBIE 3
#define PSTATE_NEW 4
#define PSTATE_STOP 5
#define PSTATE_IDLE 7
// offset of pstate in process list struct
#define PSTRUCT_STATE_OFF 2
#define PSTRUCT_EVENT_OFF 3

#define NEXT_PROC_UNAVAIL 0xff
#define NEXT_PROC_SAME 0xfe

#define SYS_SEM_READ 0

#ifndef __ASSEMBLER__

#include <stdint.h>

typedef int8_t pid_t;

struct plist_entry
{
   char *sp;
   int8_t pstate;
   int8_t event;
};

pid_t start_proc(void (*)(void));
pid_t new_proc(void (*)(void));
void run_proc(pid_t);
void stop_proc(pid_t);
void sys_schedule();
void sys_set_event(uint8_t);
struct plist_entry *get_proc_list(void);

#endif

#endif

