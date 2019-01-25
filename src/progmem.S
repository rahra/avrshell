#include <avr/io.h>


.section .text
.balign  2

; Compare two \0-terminated strings s1 and s2 within SRAM but not more than n
; bytes.
; Parameters in registers. All parameters will be modified
; @param r24 s1 16 bit SRAM address in X.
; @param r22 s2 16 bit PMEM address in Z.
; @param r20 n 16 bit integer in r24:r25.
; @return Result in r24.
.global pstrncmp
pstrncmp:
   push  r16
   push  r17
   push  r18

   movw  XL,r24
   movw  ZL,r22
   movw  r24,r20

   clr   r0
   adiw  r24,1
.Lpsc0:
   sbiw  r24,1
   breq  .Lpsc1
   ld    r16,X+
   lpm   r17,Z+
   tst   r16
   in    r18,_SFR_IO_ADDR(SREG)
   tst   r17
   in    r0,_SFR_IO_ADDR(SREG)
   or    r18,r0
   mov   r0,r16
   sub   r0,r17
   andi  r18,2
   brne  .Lpsc1
   mov   r0,r16
   sub   r0,r17
   breq  .Lpsc0
.Lpsc1:
   mov   r24,r0
   ldi   r25,0
   pop   r18
   pop   r17
   pop   r16
   ret


; @param r24 PROGMEM pointer to string in Z (modified)
; @return String length in r24.
; This function works only with strings < 256
.global pstrlen
pstrlen:
   movw  r30,r24

   push  r16

   ser   r24   ; r24 = -1 (0xff)
.Lpslloop:
   inc   r24
   lpm   r16,Z+
   tst   r16
   brne  .Lpslloop
   ldi   r25,0
   pop   r16
   ret

.global pgm_word
.global pgm_ptr
pgm_ptr:
pgm_word:
   movw  ZL,r24
   lpm   r24,Z+
   lpm   r25,Z+
   ret

.global pgm_byte
pgm_byte:
   movw  ZL,r24
   lpm   r24,Z
   ret

