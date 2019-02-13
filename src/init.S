/*! \file init.S
 * System initialization.
 * @author Bernhard R. Fischer, 4096R/8E24F29D bf@abenteuerland.at
 */

.file "init.S"

#include <avr/io.h>

#include "avrshell.h"

.section .vectors

; reset vector
.org 0
   cli
   rjmp  __ctors_start

.org 0x04
   rcall default_handler

.org 0x08
   rcall default_handler

.org 0x0c
   rcall default_handler

.org 0x10
   rcall default_handler

.org 0x14
   rcall default_handler

.org 0x18
   rcall default_handler

.org 0x1c
   rcall default_handler

.org 0x20
   rcall default_handler

.org 0x24
   rcall default_handler

.org 0x28
   rcall default_handler

.org 0x2c
   rcall default_handler

.org 0x30
   rcall default_handler

.org 0x34
   rcall default_handler

.org 0x38
   rcall default_handler

.org 0x3c
   rcall default_handler

; timer 0 overflow
.org 0x40
   rjmp  t0_handler

.org 0x44
   rcall default_handler

; serial input buffer vector
.org 0x48
   rjmp  serial_rx_handler

.org 0x4c
   rjmp  serial_tx_handler

.org 0x50
   rcall default_handler

.org 0x54
   rcall default_handler

.org 0x58
   rcall default_handler

.org 0x5c
   rcall default_handler

.org 0x60
   rcall default_handler

.org 0x64
   rcall default_handler


; "ConstrucTORS"
;__ctors_start:
.section .ctors
   ldi   r16,0                   ; clear system status register
   out   _SFR_IO_ADDR(SREG),r16
   ldi   r16,lo8(RAMEND)         ; init stack
   out   _SFR_IO_ADDR(SPL),r16
   ldi   r16,hi8(RAMEND)
   out   _SFR_IO_ADDR(SPH),r16

   rcall init_procs              ; init thread structures
   rcall init_timer              ; init time slice timer
   rcall init_int_vectors        ; init interrupt memory vectors

   clr   r1                      ; put address 0x0000 (reset vector) on stack
   push  r1                      ; ...in case main returns...
   push  r1                      ; ...and make sure that r1 contains 0

   ldi   r16,pm_lo8(main)           ; start first process (main)
   ldi   r17,pm_hi8(main)
   push  r16
   push  r17
   reti

.section .text


init_int_vectors:
   ldi   YL,lo8(int_vec)            ; get memory int vector table
   ldi   YH,hi8(int_vec)

   ldi   XL,pm_lo8(std_handler)     ; get address of standard handler
   ldi   XH,pm_hi8(std_handler)

   ldi   r16,NUM_INT_VECTS          ; get number of vectors
.Liivloop:
   st    Y+,XL                      ; write standard handler address to table
   st    Y+,XH
   dec   r16
   brne  .Liivloop

   ret


default_handler:
   push  r16
   in    r16,_SFR_IO_ADDR(SREG)
   push  r16
   push  XL
   push  XH
   push  YL
   push  YH

   ; stack layout:
   ; +1: YH
   ; +2: YL
   ; +3: XH
   ; +4: XL
   ; +5: r16 (SREG)
   ; +6: r16
   ; +7: hi8(rcall default_handler)
   ; +8: lo8(rcall default_handler)

   in    YL,_SFR_IO_ADDR(SPL)
   in    YH,_SFR_IO_ADDR(SPH)

   ldd   r16,Y+8           ; get interrupt programm address of rcall in vector table
   dec   r16

   mov   r26,r16           ; calculate int vector number
   lsr   r26
   inc   r26
   sts   int_nr,r26        ; save int vector number to memory

   ldi   XL,lo8(int_vec)   ; get vector table address
   ldi   XH,hi8(int_vec)
   add   XL,r16            ; add offset
   clr   r16
   adc   XH,r16

   ld    r16,X+            ; get lower address of vector
   std   Y+8,r16           ; write to stack
   ld    r16,X+            ; get higher address of vector
   std   Y+7,r16           ; write to stack

   pop   YH
   pop   YL
   pop   XH
   pop   XL
   pop   r16
   out   _SFR_IO_ADDR(SREG),r16
   pop   r16

   ret                     ; -> this actually calls the interrupt handler


std_handler:
   push  r22
   in    r22,_SFR_IO_ADDR(SREG)
   push  r22
   push  r24
   push  r25

   ldi   r24,lo8(.Lm_int_)
   ldi   r25,hi8(.Lm_int_)
   ldi   r22,3
   rcall sys_pwrite

;   lds   r24,int_nr       ; probably not int safe
;   rcall write_hexbyte
   ldi   r24,'\n'
   rcall sys_send

   pop   r25
   pop   r24
   pop   r22
   out   _SFR_IO_ADDR(SREG),r22
   pop   r22
   reti


; register interrupt routine
; @param r24 interrupt vector number (1-26)
; @param r23:r22 function address
.global register_int
register_int:
   dec   r24               ; check if interrupt number is within range
   brmi  .Lri_err
   cpi   r24,NUM_INT_VECTS
   brpl  .Lri_err

   push  YL
   push  YH

   lsl   r24               ; calculate table offset from int number

   ldi   YL,lo8(int_vec)   ; get int vector table address
   ldi   YH,hi8(int_vec)

   add   YL,r24            ; add offset
   ldi   r24,0
   adc   YH,r24

   st    Y+,r22            ; write function address to table
   st    Y,r23

   pop   YH
   pop   YL

   ret

.Lri_err:
   ldi   r24,0xff
   ret


.Lm_int_:
.string "INT"

.section .data
; number of current interrupt
int_nr:
.space 1
; interrupt vectors
int_vec:
.space NUM_INT_VECTS * 2

