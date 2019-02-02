#include <avr/io.h>


.global led_proc
led_proc:
   ldi   r16,10
   sbi   _SFR_IO_ADDR(DDRB),5
.Llptoggle:
   sbi   _SFR_IO_ADDR(PINB),5

   ldi   r26,0x20
   ldi   r25,0
   ldi   r24,0
.Llploop:
   dec   r24
   brne  .Llploop
   dec   r25
   brne  .Llploop
   dec   r26
   brne  .Llploop

   dec   r16
   brne  .Llptoggle

   ret

