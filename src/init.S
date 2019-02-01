/*! \file init.S
 * System initialization.
 * @author Bernhard R. Fischer, 4096R/8E24F29D bf@abenteuerland.at
 */

.file "init.S"

#include <avr/io.h>


.section .vectors

; reset vector
.org 0
   cli
   rjmp  __ctors_start

.org 0x04
   rcall .
   rjmp  default_handler
   rcall .
   rjmp  default_handler
   rcall .
   rjmp  default_handler
   rcall .
   rjmp  default_handler
   rcall .
   rjmp  default_handler
   rcall .
   rjmp  default_handler
   rcall .
   rjmp  default_handler
   rcall .
   rjmp  default_handler
   rcall .
   rjmp  default_handler
   rcall .
   rjmp  default_handler
   rcall .
   rjmp  default_handler
   rcall .
   rjmp  default_handler
   rcall .
   rjmp  default_handler
   rcall .
   rjmp  default_handler
   rcall .
   rjmp  default_handler

; timer 0 overflow
.org 0x40
   rjmp  t0_handler

.org 0x44
   rcall .
   rjmp  default_handler

; serial input buffer vector
.org 0x48
   rjmp  serial_rx_handler

.org 0x4c
   rjmp  serial_tx_handler

.org 0x50
   rcall .
   rjmp  default_handler
   rcall .
   rjmp  default_handler
   rcall .
   rjmp  default_handler
   rcall .
   rjmp  default_handler
   rcall .
   rjmp  default_handler
   rcall .
   rjmp  default_handler


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

   ldi   r16,0x00                ; put address 0x0000 (reset vector) on stack
   push  r16
   push  r16

   ldi   r16,lo8(main)           ; start first process (main)
   ldi   r17,hi8(main)
   lsr   r17
   ror   r16
   push  r16
   push  r17
   reti

.section .text

default_handler:
   push  r16
   in    r16,_SFR_IO_ADDR(SREG)
   push  r16
   push  r24
   push  r25
   push  YL
   push  YH

   in    YL,_SFR_IO_ADDR(SPL)
   in    YH,_SFR_IO_ADDR(SPH)

   ; stack layout:
   ; +1: YH
   ; +2: YL
   ; +3  r25
   ; +4: r24
   ; +5: r16 (SREG)
   ; +6: r16
   ; +7: lo8(rcall .)
   ; +8: hi8(rcall .)

   ldi   r24,lo8(.Lm_int_)
   ldi   r25,hi8(.Lm_int_)
   ldi   r22,3
   rcall sys_pwrite

   ldd   r24,Y+8
   dec   r24
   rcall write_hexbyte
   ldi   r24,'\n'
   rcall sys_send

   ldd   r16,Y+5           ; move saved val of r16 2 bytes back for final stack restore
   std   Y+8,r16

   pop   YH
   pop   YL
   pop   r25
   pop   r24
   pop   r16
   out   _SFR_IO_ADDR(SREG),r16
   pop   r16

   pop   r16               ;restore stack
   pop   r16

   reti

.Lm_int_:
.string "INT"

