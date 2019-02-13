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
#define PSTATE_NEW 4
#define PSTATE_STOP 5
// offset of pstate in process list struct
#define PSTRUCT_STATE_OFF 2

#define NEXT_PROC_UNAVAIL 0xff
#define NEXT_PROC_SAME 0xfe

#ifndef __ASSEMBLER__

typedef int8_t pid_t;

pid_t start_proc(void (*)(void));
pid_t new_proc(void (*)(void));
void run_proc(pid_t);
void stop_proc(pid_t);

#endif

#endif

