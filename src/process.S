/*! \file process.S
 * This file contains the routines for the process management.
 *
 * @author Bernhard R. Fischer, 4096R/8E24F29D bf@abenteuerland.at
 */

.file "process.S"

.include "macro.i"

#include <avr/io.h>

#include "process.h"

.section .text

; Initialize default values at kernel startup.
.global init_procs
init_procs:
   clr   r16               ; Set the current PID to 0.
   sts   current_proc,r16
   sts   .Lsys_event_,r16  ; clear events

   out   _SFR_IO_ADDR(GPIOR0),r16; clear GPIOR0 which is used for kernel semaphores

   ldi   YL,lo8(proc_list)       ; zero process list
   ldi   YH,hi8(proc_list)
   ldi   r17,MAX_PROCS * PROC_LIST_ENTRY
.Liploop:
   st    Y+,r16
   dec   r17
   brne  .Liploop

   ldi   r16,PSTATE_RUN          ; set state of initial process to RUN
   ldi   YL,lo8(proc_list)
   ldi   YH,hi8(proc_list)
   std   Y+PSTRUCT_STATE_OFF,r16
   ret


; check if context switch is necessary
; @return returns in r16 the number of the new process to switch to, 0 if it should
; not switch, and -1 if no process available (i.e. all are waiting)
.global check_ctx_switch
check_ctx_switch:
   push  r22

   ; determine next process to schedule
   lds   r16,current_proc
   ldi   r22,PSTATE_RUN
   rcall get_next_proc
   cpi   r16,NEXT_PROC_UNAVAIL   ; test if no process is available
   breq  .Lccs_exit              ; exit in case
   lds   r22,current_proc
   cp    r16,r22                 ; test if no switch necessary (i.e. same process)
   brne  .Lccs_exit              ; exit if different process
   ldi   r16,NEXT_PROC_SAME      ; return 0 meaning no switch
.Lccs_exit:
   pop   r22
   ret


; Function saves stack pointer and returns new stack pointer
; @param r16 pid to switch to
; @param stack pointer to save in Y
; @return new stack pointer returned in Y

.global context_switch
context_switch:
   mov   r24,r16
   lds   r16,current_proc
   rcall proc_list_address

   ; save current SP (Y) to proc_list
   st    Z+,YL
   st    Z,YH

   ; determine next process to schedule
   mov   r16,r24
   sts   current_proc,r16

   ; calculate process list address of new process
   rcall proc_list_address
   ; ...and store its stack address to Y
   ld    YL,Z+
   ld    YH,Z

   ret


; Calculate address of proc_list entry
; @param r16 number of process
; @return Z contains address of proc_list entry
proc_list_address:
   push  r0
   push  r1
   push  r17

   ; calculate process list offset:
   ; multiply process number with size per entry
   ldi   r17,PROC_LIST_ENTRY
   mul   r17,r16

   ; get start address of process list
   ldi   ZL,lo8(proc_list)
   ldi   ZH,hi8(proc_list)
   ; and add offset
   add   ZL,r0
   adc   ZH,r1
   
   pop   r17
   pop   r1
   pop   r0
   ret


; get number of next process with specific state
; This actually is the (most simple round robin) scheduler ;)
; @param r16 current process
; @param r22 process state to look for
; @return r16 number of next process or -1 if no process available
get_next_proc:
   push  r17
   push  r18
   push  ZL
   push  ZH

   mov   r18,r16
.Lgnpinc:
   ; increase current PID
   inc   r16
   ; and start at the first process if the last one is reached
   cpi   r16,MAX_PROCS
   brne  .Lgnpstate
   clr   r16
.Lgnpstate:
   rcall proc_list_address
   ldd   r17,Z+PSTRUCT_STATE_OFF ; get process state
   cp    r17,r22           ; check if we found a process in the state we look for
   breq  .Lgnpexit
   cp    r16,r18           ; check if we found the same process again which means the loop restarts
   brne  .Lgnpinc          ; if not, continue loop

   ldi   r16,NEXT_PROC_UNAVAIL   ; no process available
.Lgnpexit:
   pop   ZH
   pop   ZL
   pop   r18
   pop   r17
   ret


; Start a new process
; @param r25:r24 Start address of new process (word address)
; @return r24 pid of new process
.global new_proc
new_proc:
   push  r16
   push  r22
   push  YL
   push  YH
   push  ZL
   push  ZH

   ; disable all interrupts
   cli

   ; get new PID and calculate stack (top) address
   clr   r16
   ldi   r22,PSTATE_UNUSED
   rcall get_next_proc
   cpi   r16,NEXT_PROC_UNAVAIL
   breq  .Lnp_noslot
   mov   r22,r16
   rcall stack_address

   ldi   ZL,pm_lo8(exit_proc)    ; get address of process exit handler
   ldi   ZH,pm_hi8(exit_proc)

   st    Y,ZL     ; and put it on new process's stack 1st
   st    -Y,ZH

   st    -Y,r24   ; save entry point to the stack of the new process
   st    -Y,r25

   sbiw  YL,32 ; subtract 32 from Y (stack) which is the register space
               ; of the context switcher

   clr   r16   ; store 0 to Y (stack) which is the SREG
   st    -Y,r16

   sbiw  YL,1

   std   Y+32,r16          ; make sure that r1 will be pop with 0 from stack

   ; store final stack address to the process list
   mov   r16,r22
   rcall proc_list_address

   st    Z+,YL   ; store new stack pointer to proc_list
   st    Z+,YH

   ldi   r16,PSTATE_NEW    ; set process state to RUN
   st    Z,r16

.Lnp_exit:
   ; enable interrupts again
   sei

   mov   r24,r22           ; move pid to return register

   pop   ZH
   pop   ZL
   pop   YH
   pop   YL
   pop   r22
   pop   r16

   ret

.Lnp_noslot:
   mov   r22,r16
   rjmp  .Lnp_exit


; Change state of process.
; @param r24 Pid of process to change state.
; @param r22 Process state to set.
; @return r24 pid of new process
.global proc_state
proc_state:
   push  r16
   push  ZL
   push  ZH

   mov   r16,r24
   rcall proc_list_address
   std   Z+PSTRUCT_STATE_OFF,r22

   pop   ZH
   pop   ZL
   pop   r16
   ret


; Run process.
; @param r24 Pid of process to run.
.global run_proc
run_proc:
   push  r22

   ldi   r22,PSTATE_RUN
   rcall proc_state

   pop   r22
   ret


; Stop process.
; @param r24 Pid of process to stop.
.global stop_proc
stop_proc:
   push  r22

   ldi   r22,PSTATE_STOP
   rcall proc_state

   pop   r22
   ret


; Start a new process
; @param r25:r24 Start address of new process (word address)
; @return r24 pid of new process
.global start_proc
start_proc:
   rcall new_proc
   rcall run_proc
   ret
 

; Calculate address of stack in memory
; @param r16 Number of process (PID)
; @return Y address of stack
stack_address:
   push  r0
   push  r1

   mov   r0,r16
   ldi   r16,STACK_SIZE
   mul   r16,r0

   ldi   YL,lo8(RAMEND)
   ldi   YH,hi8(RAMEND)
   sub   YL,r0
   sbc   YH,r1
   clr   r1

   pop   r1
   pop   r0
   ret


; Process exit handler removes process from process list.
exit_proc:
   lds   r16,current_proc
   rcall proc_list_address       ; get proc_list address of current process

   ldi   r16,PSTATE_ZOMBIE       ; set process state to ZOMBIE
   std   Z+PSTRUCT_STATE_OFF,r16

.global sys_schedule
.global sys_schedule0
sys_schedule:
   cli                           ; clear interrupts and immediately force context switch
sys_schedule0:
   rjmp  scheduler               ; jump to scheduler


.global sys_sleep
sys_sleep:
   sleep
   ret


; idle process
.global idle
idle:
   ldi   YL,lo8(proc_list)
   ldi   YH,hi8(proc_list)
   ldi   r24,PSTATE_IDLE
   std   Y+PSTRUCT_STATE_OFF,r24

   ldi   r24,pm_lo8(main)
   ldi   r25,pm_hi8(main)
   rcall start_proc

.Lidle_loop:
   sleep
   rjmp  .Lidle_loop


; create bitmask from number, e.g. 0x03 -> 0x08
; @param r24 number
; @return r24 bitmask
mk_bitmask:
   push  r25

   ldi   r25,1          ; create bitmask from number
   tst   r24
.Lsw_loop:
   breq  .Lmkb_exit
   lsl   r25
   dec   r24
   rjmp  .Lsw_loop

.Lmkb_exit:
   mov   r24,r25
   pop   r25
   ret


; wait for specific system semaphore to become ready (=1)
; @param r24 number of semaphore (currently 0-7)
.global sys_sem_wait
sys_sem_wait:
   push  r22
   push  r25

   andi  r24,7          ; make sure that param is between 0 and 7
   mov   r22,r24        ; safe semaphore number
   rcall mk_bitmask
   mov   r25,r24

.Lsw_sem_check:
   cli
   in    r24,_SFR_IO_ADDR(GPIOR0)     ; test if bit is set
   and   r24,r25
   brne  .Lsw_sem_ready ; if 1, semaphore is ready

   push  r16            ; otherwise set current process into wait and re-schedule
   push  ZL
   push  ZH

   lds   r16,current_proc
   rcall proc_list_address

   ldi   r16,PSTATE_WAIT
   std   Z+PSTRUCT_STATE_OFF,r16
   std   Z+PSTRUCT_EVENT_OFF,r22 ; store semaphore number

   pop   ZH
   pop   ZL
   pop   r16

   rcall sys_schedule0
   rjmp  .Lsw_sem_check

.Lsw_sem_ready:
   in    r24,_SFR_IO_ADDR(GPIOR0)     ; clear semaphore bit
   com   r25
   and   r24,r25
   out   _SFR_IO_ADDR(GPIOR0),r24

   sei
   pop   r25
   pop   r22

   ret


; raise semaphore and unlock waiting process
; @param r24 number of semaphore (0-7)
.global sys_sem_post
sys_sem_post:
   push  r16
   push  r22
   push  ZL
   push  ZH

   andi  r24,7          ; make sure that param is between 0 and 7
   mov   r16,r24        ; temporary safe semaphore number
   rcall mk_bitmask

   in    r22,_SFR_IO_ADDR(SREG)  ; save SREG (because of I)
   push  r22
   cli                           ; and disable interrupts

   in    r22,_SFR_IO_ADDR(GPIOR0); set semphore bit
   or    r22,r24
   out   _SFR_IO_ADDR(GPIOR0),r22

   mov   r24,r16

   lds   r16,current_proc
.Lsp_loop:
   ldi   r22,PSTATE_WAIT         ; find next process with state WAIT
   rcall get_next_proc
   cpi   r16,NEXT_PROC_UNAVAIL   ; exit if there is none
   breq  .Lsp_exit

   rcall proc_list_address       ; check if process is waiting for this semaphore
   ldd   r22,Z+PSTRUCT_EVENT_OFF
   cp    r22,r24
   brne  .Lsp_loop               ; if not, continue loop

   ldi   r22,PSTATE_RUN          ; state state of process to RUN
   std   Z+PSTRUCT_STATE_OFF,r22

.Lsp_exit:
   pop   r22
   out   _SFR_IO_ADDR(SREG),r22

   pop   ZH
   pop   ZL
   pop   r22
   pop   r16

   ret


.global get_proc_list
get_proc_list:
   ldi   r24,lo8(proc_list)
   ldi   r25,hi8(proc_list)
   ret


.section .data
; currently active process
current_proc:
.space 1
.Lsys_event_:
.space 1
; process list
proc_list:
.space MAX_PROCS * PROC_LIST_ENTRY

