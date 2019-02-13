/*! \file timer.S
 * This file contains all timer related functions. This is an uptime counter
 * and the context switching for the multi-tasking.
 *
 * @author Bernhard R. Fischer, 4096R/8E24F29D bf@abenteuerland.at
 */

.file "timer.S"

.include "macro.i"

#include <avr/io.h>

#include "process.h"

.section .text


/*! Initialize the timer 0 to simple overflow mode with a clock divider of
 * 1024. Thus, the timer interrupt is triggered all 16.384 ms on an 16 MHz
 * Arduino board (1 / 16000000 * 1024 * 256 = 0.016384 s). This is the chosen
 * time slice for this multi-tasking operating system.
 */
.global init_timer
init_timer:
   clr   r16                     ; set timer normal mode
   out   _SFR_IO_ADDR(TCCR0A),r16
   ldi   r16,0x05                ; set clock divider 1024
   out   _SFR_IO_ADDR(TCCR0B),r16
   clr   r16                     ; counter register auf 0 (=256)
   out   _SFR_IO_ADDR(TCNT0),r16

   ldi   r16,1                   ; timer interrupt enable
   sts   TIMSK0,r16

   ldi   XL,lo8(uptime)          ; init uptime to 0
   ldi   XH,hi8(uptime)

   clr   r16
   st    X+,r16
   st    X+,r16
   st    X+,r16
   st    X+,r16

   ret


/*! This is the interrupt handler for the timer 0 interrupt. It invokes the
 * context switch and it increases the uptime counter.
 */
.global t0_handler
t0_handler:
#if 1
   push  r16
   in    r16,_SFR_IO_ADDR(SREG)
   push  r16

   rcall t0_count                ; increase uptime counter

   rcall check_ctx_switch        ; determine next process to schedule
   cpi   r16,NEXT_PROC_SAME      ; dont switch if same process
   breq  .Lt0_exit
   cpi   r16,NEXT_PROC_UNAVAIL   ; do idle
   breq  .Lt0_exit

   sts   .Lnext_proc_,r16
   pop   r16                     ; restore registers
   out   _SFR_IO_ADDR(SREG),r16
   pop   r16

   rjmp  .Lt0_fullsave           ; jump to full context switch

.Lt0_exit:
   pop   r16
   out   _SFR_IO_ADDR(SREG),r16
   pop   r16
   reti

.Lt0_fullsave:
   pushm 0,31
   in    r16,_SFR_IO_ADDR(SREG)
   push  r16

   ; copy SP to Y
   in    YL,_SFR_IO_ADDR(SPL)
   in    YH,_SFR_IO_ADDR(SPH)

   lds   r16,.Lnext_proc_
   rcall context_switch

   ; copy new stack address in Y to SP
   out   _SFR_IO_ADDR(SPL),YL
   out   _SFR_IO_ADDR(SPH),YH

   pop   r16
   out   _SFR_IO_ADDR(SREG),r16
   popm  0,31
   reti
#else
   ; save full context to (current) stack
   pushm 0,31
   in    r16,_SFR_IO_ADDR(SREG)
   push  r16

   ; call uptime counter
   rcall t0_count

   ; copy SP to Y
   in    YL,_SFR_IO_ADDR(SPL)
   in    YH,_SFR_IO_ADDR(SPH)

   ; determine next process to schedule
   rcall check_ctx_switch
   cpi   r16,NEXT_PROC_SAME
   breq  .Lt0_noswitch
   cpi   r16,NEXT_PROC_UNAVAIL
   breq  .Lt0_noswitch
   rcall context_switch
.Lt0_noswitch:
   ; copy new stack address in Y to SP
   out   _SFR_IO_ADDR(SPL),YL
   out   _SFR_IO_ADDR(SPH),YH

   ; restore full context
   pop   r16
   out   _SFR_IO_ADDR(SREG),r16
   popm  0,31
   reti
#endif

/*! This function increases to system uptime by 1.
 */
t0_count:
   pushm 26,29

   ldi   YL,lo8(uptime)    ; load address of uptime variable to Y
   ldi   YH,hi8(uptime)

   ld    r26,Y             ; get lower 16 bit
   ldd   r27,Y+1
   adiw  r26,1             ; add 1
   st    Y+,r26            ; write back to mem
   st    Y+,r27
   brcc  .Lt0c_exit

   ld    r26,Y             ; get higher 16 bit
   ldd   r27,Y+1
   adiw  r26,1             ; add 1
   st    Y+,r26            ; write back to mem
   st    Y+,r27

.Lt0c_exit:
   popm  26,29
   ret


/*! This function returns the current uptime.
 *  @prototype long get_uptime(void)
 *  @return 32 bit uptime in r22-r25.
 */
.global get_uptime
get_uptime:
   ldi   XL,lo8(uptime)
   ldi   XH,hi8(uptime)

   cli
   ld    r22,X+
   ld    r23,X+
   ld    r24,X+
   sei
   ld    r25,X+

   ret

.section .data
; 32 bit uptime counter
uptime:
.space 4
.Lnext_proc_:
.space 1

