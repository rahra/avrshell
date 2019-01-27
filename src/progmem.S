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

.global read_eeprom
read_eeprom:
   sbic  _SFR_IO_ADDR(EECR),EEPE
   rjmp  read_eeprom
   out   _SFR_IO_ADDR(EEARH),r25
   out   _SFR_IO_ADDR(EEARL),r24
   sbi   _SFR_IO_ADDR(EECR),EERE
   in    r24,_SFR_IO_ADDR(EEDR)
   ret

.global write_eeprom
write_eeprom:
   sbic  _SFR_IO_ADDR(EECR),EEPE
   rjmp  write_eeprom
   out   _SFR_IO_ADDR(EEARH),r25
   out   _SFR_IO_ADDR(EEARL),r24
   out   _SFR_IO_ADDR(EEDR),r22
   cli
   sbi   _SFR_IO_ADDR(EECR),EEMPE
   sei
   sbi   _SFR_IO_ADDR(EECR),EEPE
   ret

; Read special bits (fuse, lock, signature) from controller flash
; @param r25:r24 address of byte to read
.global read_fuse
read_fuse:
   push  r22
   ldi   r22,_BV(SPMEN)|_BV(BLBSET)
   rcall .Lread_special
   pop   r22
   ret

.global read_sig
read_sig:
   push  r22
   ldi   r22,_BV(SPMEN)|_BV(SIGRD)
   rcall .Lread_special
   pop   r22
   ret

.Lread_special:
   push  ZL
   push  ZH

   movw  ZL,r24
   cli
   out   _SFR_IO_ADDR(SPMCSR),r22
   sei
   lpm   r24,Z

   pop   ZH
   pop   ZL
   ret

