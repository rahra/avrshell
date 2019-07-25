/*! \file sys_serial.S
 * This file contains the code for the serial communication.
 * It is an interrupt driven sender and receiver.
 *
 * @author Bernhard R. Fischer, 4096R/8E24F29D bf@abenteuerland.at
 */

.file "serial_io.S"

#define WITH_SEM

#include <avr/io.h>

#include "process.h"

; baud rate for 16MHz Arduino
; 207 = 9600, 103 = 19200, 16 = 115200
#define BAUDCOUNT 207

#define KBUF_INPUT_SIZE 64
#define KBUF_OUTPUT_SIZE 64


.section .text

.global init_serial
init_serial:
   push  r16
   
   ldi   r16,hi8(BAUDCOUNT)
   sts   UBRR0H,r16
   ldi   r16,lo8(BAUDCOUNT)
   sts   UBRR0L,r16
   ldi   r16,0x02                ; mode U2X (double baud clock)
   sts   UCSR0A,r16
   ldi   r16,0x18 | _BV(RXCIE0)  ; RXCIE, RXEN, TXEN
   sts   UCSR0B,r16
   ldi   r16,0x06    ; 8N1
   sts   UCSR0C,r16

   clr   r16
   sts   kbuf_output_len_,r16
   sts   kbuf_input_len_,r16
#ifndef WITH_SEM
   sts   kbuf_input_ready_,r16
#endif

   pop   r16
   ret


.global serial_rx_handler
serial_rx_handler:
   push  r24
   push  r25
   push  YL
   push  YH

   in    r24,_SFR_IO_ADDR(SREG)
   push  r24

   lds   r25,kbuf_input_len_        ; get current buffer length

   lds   r24,UDR0                   ; get data from serial port

   cpi   r24,'\r'                   ; translate \r to \n
   brne  .Lsrx_isend
   ldi   r24,'\n'

.Lsrx_isend:
   rcall sys_isend

   cpi   r24,8                      ; check if backspace
   breq  .Lsrx_bs
;   cpi   r24,'\r'  ; commented out because it was translated above
;   breq  .Lsrx_ready
   cpi   r24,'\n'
   breq  .Lsrx_ready

   cpi   r25,KBUF_INPUT_SIZE        ; exit if buffer is full
   ;brpl  .Lsrx_exit
   breq  .Lsrx_exit 

   ldi   YL,lo8(kbuf_input_)        ; get buffer address
   ldi   YH,hi8(kbuf_input_)

   add   YL,r25                     ; add length to buffer low byte
   ldi   r25,0                      ; add carry to high byte
   adc   YH,r25

   st    Y,r24                      ; store input byte to buffer

   lds   r25,kbuf_input_len_        ; get current buffer length
   inc   r25                        ; inc length
   sts   kbuf_input_len_,r25        ; store length
   cpi   r25,KBUF_INPUT_SIZE        ; set buffer ready if full
   ;brpl  .Lsrx_ready
   breq  .Lsrx_ready

.Lsrx_exit:
   pop   r24
   out   _SFR_IO_ADDR(SREG),r24

   pop   YH
   pop   YL
   pop   r25
   pop   r24
   reti

.Lsrx_bs:
   tst   r25
   breq  .Lsrx_exit
   dec   r25
   sts   kbuf_input_len_,r25
   rjmp  .Lsrx_exit

.Lsrx_ready:
#ifdef WITH_SEM
   ldi   r24,SYS_SEM_READ
   rcall sys_sem_post
#else
   ldi   r24,1
   sts   kbuf_input_ready_,r24
#endif
   rjmp  .Lsrx_exit


.global serial_tx_handler
serial_tx_handler:
   push  r24
   push  r25
   push  YL
   push  YH

   in    r24,_SFR_IO_ADDR(SREG)
   push  r24

   lds   r25,kbuf_output_len_    ; get buffer length
   dec   r25                     ; decrease length
   sts   kbuf_output_len_,r25    ; store length
   brne  .Lstx_send

   lds   r24,UCSR0B              ; switch off interrupt
   andi  r24,~_BV(UDRIE0)
   sts   UCSR0B,r24
 
.Lstx_send:
   ldi   YL,lo8(kbuf_output_)    ; get buffer address
   ldi   YH,hi8(kbuf_output_)

   add   YL,r25                  ; add length to buffer address
   ldi   r25,0
   adc   YH,r25

   ld    r25,Y                   ; get byte from buffer
   sts   UDR0,r25                ; write it to serial port

.Lstx_exit:
   pop   r24
   out   _SFR_IO_ADDR(SREG),r24

   pop   YH
   pop   YL
   pop   r25
   pop   r24
   reti

; @param r24 byte to send
sys_isend:
   push  r25
   lds   r25,kbuf_output_len_
   tst   r25
   brne  .Lsi_exit                  ; exit if buffer is not ready

   sts   kbuf_output_,r24           ; store byte to 1st position in output buffer
   ldi   r25,1                      ; set buffer length to 1
   sts   kbuf_output_len_,r25

   lds   r25,UCSR0B                 ; enable UDR interrupt
   ori   r25,_BV(UDRIE0)
   sts   UCSR0B,r25

.Lsi_exit: 
   pop   r25
   ret


; @param r24 byte to send
.global sys_send
sys_send:
   push  r25

   rcall serial_tx_wait
   
   sts   kbuf_output_,r24
   ldi   r25,1
   sts   kbuf_output_len_,r25

   lds   r25,UCSR0B
   ori   r25,_BV(UDRIE0)
   sei
   sts   UCSR0B,r25
 
   pop   r25
   ret

 
; @param r25:r24 pointer to buffer
; @param r22 length
; @return r24 length sent
.global sys_write
sys_write:
   push  r20
   ldi   r20,0
   rcall sys_write0
   pop   r20
   ret


; @param r25:r24 pointer to buffer
; @param r22 length
; @return r24 length sent
.global sys_pwrite
sys_pwrite:
   push  r20
   ldi   r20,1
   rcall sys_write0
   pop   r20
   ret


; @param r25:r24 pointer to buffer
; @param r22 length
; @param r20 0 = ram, otherwise program memory
; @return r24 length sent
sys_write0:
   push  r25
   push  YL
   push  YH
   push  ZL
   push  ZH

   movw  ZL,r24                  ; copy source address to Z

   ldi   YL,lo8(kbuf_output_)    ; copy destination address to Y
   ldi   YH,hi8(kbuf_output_)

   mov   r24,r22
   cpi   r24,KBUF_OUTPUT_SIZE+1
   brlo  .Lsw_copy
   
   ldi   r24,KBUF_OUTPUT_SIZE

.Lsw_copy:
   add   YL,r24                  ; add length to Z
   ldi   r25,0
   adc   YH,r25

   rcall serial_tx_wait          ; wait for serial buffer to be ready

   sts   kbuf_output_len_,r24    ; store length

   tst   r20
   breq  .Lsw_copy_loop_ram

.Lsw_copy_loop_pgm:
   lpm   r25,Z+
   st    -Y,r25
   dec   r24
   brne  .Lsw_copy_loop_pgm
   rjmp  .Lsw_exit

.Lsw_copy_loop_ram:
   ld    r25,Z+
   st    -Y,r25
   dec   r24
   brne  .Lsw_copy_loop_ram

.Lsw_exit:
   lds   r24,UCSR0B
   ori   r24,_BV(UDRIE0)
   sei
   sts   UCSR0B,r24
 
   lds   r24,kbuf_output_len_    ; get length for return value

   pop   ZH
   pop   ZL
   pop   YH
   pop   YL
   pop   r25
   ret


; wait for serial output buffer to be ready
; interrupts are disable after return
; uses r25!
serial_tx_wait:
   cli
   lds   r25,kbuf_output_len_
   tst   r25
   breq  .Lswt_exit
   sei
   nop
   rjmp  serial_tx_wait                   ;FIXME: here we should schedule
.Lswt_exit:
   ret


; Copy data from kernel serial input buffer to user buffer. The buffer will not
; be \0-terminated!
; @param r25:r24 pointer to user buffer
; @param r22 size of user buffer
; @return r24 number of bytes copied to buffer
.global sys_read
sys_read:
   push  r23
   push  r25
   push  YL
   push  YH
   push  ZL
   push  ZH

   movw  YL,r24
   mov   r23,r22

   rcall serial_rx_wait

   lds   r24,UCSR0B
   andi  r24,~_BV(RXCIE0)
   sei
   sts   UCSR0B,r24
 
   lds   r25,kbuf_input_len_        ; check if data available
   tst   r25
   breq  .Lrd_exit

   tst   r22                        ; check if bufsize != 0
   breq  .Lrd_exit

   ldi   ZL,lo8(kbuf_input_)
   ldi   ZH,hi8(kbuf_input_)

.Lrd_loop:
   ld    r24,Z+
   st    Y+,r24
   dec   r25
   brne  .Lrd_loop2
   dec   r22
   rjmp  .Lrd_exit

.Lrd_loop2:
   dec   r22
   brne  .Lrd_loop

.Lrd_exit:
   sub   r23,r22                    ; calc number of bytes copied
   mov   r24,r23                    ; and set return value

   sts   kbuf_input_len_,r25
#ifndef WITH_SEM
   sts   kbuf_input_ready_,r25
#endif

   cpse  r25,r1                     ; test if all bytes where retrieved from kbuffer
   rcall .Lrd_mmov                  ; otherwise move bytes to the beginning

   lds   r25,UCSR0B
   ori   r25,_BV(RXCIE0)
   ;sei  ; not necessary since interrupts are already globally enabled above
   sts   UCSR0B,r25

   pop   ZH
   pop   ZL
   pop   YH
   pop   YL
   pop   r25
   pop   r23
   ret


; move bytes in memory, blocks may overlap only if src > dst
; @param Z source address
; @param Y destination address
; @param r25 number of bytes to move
.Lrd_mmov:
   ldi   YL,lo8(kbuf_input_)
   ldi   YH,hi8(kbuf_input_)
.Lrd_loop3:
   ld    r23,Z+
   st    Y+,r23
   dec   r25
   brne  .Lrd_loop3
   ret


; wait until input buffer is ready (meaning one of \n\r was received)
; the interrupts are globally disable on return
serial_rx_wait:
#ifdef WITH_SEM
   ldi   r24,SYS_SEM_READ
   rcall sys_sem_wait
   ret
#else
   cli
   lds   r24,kbuf_input_ready_
   tst   r24
   brne  .Lsrxw_exit
   sei
   nop
   rjmp  serial_rx_wait             ; FIXME: schedule...

.Lsrxw_exit:
   ret
#endif


.global sys_read_flush
sys_read_flush:
   push  r25

   ldi   r25,0
   cli
   sts   kbuf_input_len_,r25
   sei
#ifndef WITH_SEM
   sts   kbuf_input_ready_,r25
#endif

   pop   r25
   ret


; return last byte received from serial port. The character is not removed from
; the input buffer, thus it does not interfere or disturb with sys_read(). The
; function blocks if no bytes are available.
.global sys_peek_serial
sys_peek_serial:
   cli
   lds   r24,kbuf_input_len_     ; check if data is in buffer
   tst   r24
   brne  .Lsp_get
   rcall sys_schedule            ; wait if not (call scheduler)
   rjmp  sys_peek_serial

.Lsp_get:
   push  YL
   push  YH

   ldi   YL,lo8(kbuf_input_)     ; get base address of buffer
   ldi   YH,hi8(kbuf_input_)
   dec   r24                     ; dec byte counter to get buffer index
   add   YL,r24                  ; and add index to base address
   clr   r24
   adc   YH,r24
   sei
   ld    r24,Y                   ; get byte from buffer

   pop   YH
   pop   YL
   ret


.section .data
kbuf_input_:
.space KBUF_INPUT_SIZE
kbuf_input_len_:
.space 1
#ifndef WITH_SEM
kbuf_input_ready_:
.space 1
#endif
kbuf_output_:
.space KBUF_OUTPUT_SIZE
kbuf_output_len_:
.space 1

