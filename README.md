# AVR Shell

AVR Shell is tiny self-contained program to be executed on 8 bit AVR cores such
as the Atmega328p which is found on popular Arduino boards such as the Arduino
Uno or Arduino Nano.

The purpose of the programm is mainly to support your hardware development.

The AVR Shell provides a tiny command line interface which enables you to read
and write the AVR memory, including all registers and the program memory, by
using simple commands.

## Compile

To compile you need the `gcc-avr` and you need e.g. the `avrdude` to flash to
program.

Download the whole source, change into `src/` and simply run `make` and `make
upload` assuming your Arduino board is connected. You probably open the
`Makefile` and modify `USBDEV` and `BAUD` apropriately.

## Connecting

Simply connect to your Arduino with a serial terminal program such as `minicom`.
Just run `minicom -D /dev/ttyACM0 -o -b 9600 -w`.

## Commands

The following commands are implemented yet.

`in <reg_addr>` ... Works like the `in` instruction but is implemented with
memory mapped instructions (`ldd`).

`out <reg_addr> <value>` ... Works like the `out` instruction.

`sbi <reg_addr> <bit>` ... Set bit (0-7) in IO register.

`cbi <reg_addr> <bit>` ... Clear bit (0-7) in IO register.

`dump <addr>` ... Dumps 512 bytes of the memory.

`pdump <addr>` ... Dumps 512 bytes of the program memory.

All these commands are implemented using `ld`, `lpm`, and `st`.

## Interrupts

AVR Shell handles all interrupts and outputs a message if an interrupt is
caught (not sufficiently tested yet.).

Exceptions are the boot interrupt 0x00, and the serial interrupts 0x24 and 0x26
since they are used for the AVR shell itself.

