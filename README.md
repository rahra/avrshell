# AVR Shell

AVR shell is the ultimate development, debugging and education system for
AVR-based microcontrollers.

AVR Shell is tiny self-contained multi-tasking OS to be executed on 8 bit AVR
cores such as the Atmega328p which is found on popular Arduino boards such as
the Arduino Uno or Arduino Nano.

The purpose of AVRShell is mainly to support your hardware development and or
testing your software or for educational purposes.

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

`out <reg_addr> <value>`. ... Works like the `out` instruction.

`sbi <reg_addr> <bit>` ...... Set bit (0-7) in IO register.

`cbi <reg_addr> <bit>` ...... Clear bit (0-7) in IO register.

`dump <addr> [len]` ......... Dumps _len_ (default = 512) bytes of the memory.

`pdump <addr> [len]` ........ Dumps _len_ (default = 512) bytes of the program memory.

`edump <addr> [len]` ........ Dumps _len_ (default = 512) bytes of the EEPROM memory.

`ste <addr> <byte>` ......... Write _byte_ to EEPROM at address _addr_.

`cpu` ....................... Output CPU information, such as fuse bits, lock bits and signature.

`uptime` .................... Show system uptime ticks since last reset.

`run <pid>` ................. Run process _pid_.

`stop <pid>` ................ Stop process _pid_.

`new <address>` ............. Create new process with start routine at _address_.

All these commands are implemented using `ld`, `lpm`, and `st`.

## Interrupts

AVR Shell handles all interrupts and outputs a message if an interrupt is
caught.

Exceptions are the boot interrupt 0x00, and the serial interrupts 0x24 and 0x26
since they are used for the AVR shell itself.

# Author

AVR Shell is developed by Bernhard R. Fischer, bf@abenteuerland.at.

PGP Key: `9867 8E06 0630 07E4 A1F0 B9C5 9BD6 0166 8E24 F29D`

Don't hesitate to contact me.

Have phun using AVR Shell!

