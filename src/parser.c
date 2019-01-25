#include <avr/io.h>

#include "parser.h"


char nibble_to_ascx(char a)
{
   a &= 0xf;
   if (a >= 0xa)
      return a + 'a' - 0xa;;
   return a + '0';
}


int8_t is_eos(char a)
{
   return a == '\r' || a == '\n' || a == '\0';
}


int8_t is_xdigit(char a)
{
   if (a >= '0' && a <= '9')
      return 1;
   if (a >= 'a' && a <= 'f')
      return 1;
   if (a >= 'A' && a <= 'F')
      return 1;
   return 0;
}


int8_t asc_to_nibble(int8_t a)
{
   if (a < '0')
      return -1;

   if (a <= '9')
      return a - '0';

   if (a >= 'a' && a <= 'f')
      return a - 'a' + 0xa;

   if (a >= 'A' && a <= 'F')
      return a - 'A' + 0xa;

   return -1;
}


int asctoi(const char *s)
{
   int n = 0;
   int8_t base = 10;
   int8_t neg = 0;

   if (s == NULL) return 0;
   if (*s == '\r' || *s == '\n' || *s == '\0') return n;

   if (s[0] == '-')
   {
      neg = -1;

      s++;
      if (*s == '\r' || *s == '\n' || *s == '\0') return n;
   }

   if (s[0] == '0')
   {
      s++;
      if (*s == '\r' || *s == '\n' || *s == '\0') return n;

      if (s[0] == 'x')
      {
         base = 16;

         s++;
         if (*s == '\r' || *s == '\n' || *s == '\0') return n;
      }
      else
         base = 8;
   }

   for (; *s != '\r' && *s != '\n' && *s != '\0'; s++)
   {
      if (!is_xdigit(*s))
         break;

      switch (base)
      {
         case 10:
            n *= 10;
            break;
         case 8:
            n <<= 3;
            break;
         case 16:
            n <<= 4;
            break;
      }

      n += asc_to_nibble(*s);
   }

   if (neg)
      n = -n;

   return n;
}


char *next_token(char *s)
{
   // skip until next space or end of string
   for (; *s != ' ' && !is_eos(*s); s++);
   // skip leading spaces
   for (; *s == ' '; s++);

   return is_eos(*s) ? NULL : s;
}


int8_t get_int_param(char **cmd, int *parm)
{
   if (cmd == NULL)
      return E_NULL;

   if ((*cmd = next_token(*cmd)) == NULL)
      return E_NOPARM;

   if (parm != NULL)
      *parm = asctoi(*cmd);

   return E_OK;
}

