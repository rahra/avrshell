/*! \file ledproc_c.c
 * This is a example for a process run within AVRshell.
 * To use and test it define LED_PROC_C if it isn't already (see below).
 * Then compile and upload everything with `make` and `make upload`.
 * Find the start address of led_proc_main with `nm src.elf | grep led`.
 * Then start a serial terminal e.g. with minicom with `minicom -D /dev/ttyUSB3 -o -b 9600 -w`.
 * Within the terminal create a new process with `new 0x<address>`. The
 * avrshell responds with the pid of the newly create process. To start it
 * execute `run <pid>`. To list all processes execute `ps`.
 *
 * @author Bernhard R. Fischer <bf@abenteuerland.at>
 */
// define LED_PROC_C to compile example otherwise undef
#define LED_PROC_C 1
#ifdef LED_PROC_C

#include <stdint.h>

#include "process.h"
#include "avrshell.h"
#include "timer.h"

#pragma GCC diagnostic ignored "-Wmisspelled-isr"

// number of times the LED should be toggled
#define NUM_TOGGLE 50

// define this to use TIMER1 and interrupt service routine, otherisw system
// function tsleep() is used
//#define USE_TIMER1 1


#ifdef USE_TIMER1
void toggle(void) __attribute__((signal));
static volatile int8_t lcnt_;
#endif


void toggle(void)
{
   char *addr = (char*) 0x23;
   *addr = 0x20;
#ifdef USE_TIMER1
   lcnt_++;
#endif
}


/*! main function of LED process */
void led_proc_main(void)
{
   // init PORTB (where the LED of Arduino is attached to)
   char *addr = (char*) 0x24;    // DDRB
   *addr = 0x20;                 // set bit 5 to output

#ifdef USE_TIMER1
   lcnt_ = 0;
   // register interrupt
   register_int(14, toggle);

   // init timer 1
   addr = (char*) 0x80;          // TCCR1A
   *addr = 0;
   addr = (char*) 0x81;          // TCCR1B
   *addr = 4;                    // CS11+CS10 f=1/256
   addr = (char*) 0x82;
   *addr = 0;
   addr = (char*) 0x6f;          // TIMSK1
   *addr = 1;                    // set TOIE1

   for (; lcnt_ < NUM_TOGGLE;);

   *addr = 0;                    // clear TOIE1
#else
   for (int8_t i = 0; i < NUM_TOGGLE; i++)
   {
      toggle();
      tsleep(62);
   }
#endif
}
#endif

