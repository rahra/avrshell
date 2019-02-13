#include "process.h"
#include "timer.h"


void tsleep(unsigned long t)
{
   t += get_uptime();
   while (t > get_uptime())
   {
      sys_schedule();
   }
}

