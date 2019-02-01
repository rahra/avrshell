#ifndef PROCESS_H
#define PROCESS_H


// maximum number of processes
#define MAX_PROCS 5
// number of bytes used per process in the process list
#define PROC_LIST_ENTRY 3
// process stack size
#define STACK_SIZE 128
// process states
#define PSTATE_UNUSED 0
#define PSTATE_RUN 1
#define PSTATE_SLEEP 2
#define PSTATE_ZOMBIE 3
// offset of pstate in process list struct
#define PSTRUCT_STATE_OFF 2


#ifndef __ASSEMBLER__


void start_proc(void (*)(void));


#endif

#endif

