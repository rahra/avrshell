#include <avr/io.h>

#include "avrshell.h"
#include "parser.h"
#include "progmem.h"


static const char c_in_[] PROGMEM = "in";
static const char c_out_[] PROGMEM = "out";
static const char c_dump_[] PROGMEM = "dump";
static const char c_pdump_[] PROGMEM = "pdump";
static const char c_sbi_[] PROGMEM = "sbi";
static const char c_cbi_[] PROGMEM = "cbi";
static const char c_lds_[] PROGMEM = "lds";
static const char c_sts_[] PROGMEM = "sts";
static const char c_help_[] PROGMEM = "help";
static const char c_edump_[] PROGMEM = "edump";
static const char c_ste_[] PROGMEM = "ste";
static const char c_cpu_[] PROGMEM = "cpu";
static const char c_uptime_[] PROGMEM = "uptime";

static const char * const cmd_[] __attribute__((__progmem__)) = {c_in_, c_out_,
   c_dump_, c_pdump_, c_sbi_, c_cbi_, c_lds_, c_sts_, c_help_, c_edump_,
   c_ste_, c_cpu_, c_uptime_};


int strlen(const char *s)
{
   int n;

   if (s == NULL)
      return 0;

   for (n = 0; *s; n++, s++);

   return n;
}


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


int8_t lint_to_str(long int n, char *buf, int len)
{
   long int base;
   int8_t ret = E_TRUNC;
   char c;

   if (len <= 0 || buf == NULL)
      return E_NULL;

   if (len <= 1)
      goto lint_to_str_return;

   if (n < 0)
   {
      n = -n;
      *buf++ = '-';
      len--;
      if (len <= 1)
         goto lint_to_str_return;
   }

   for (base = 1000000000; base > n; base /= 10);

   for (; base; base /= 10)
   {
      c = n / base;
      n %= base;
      *buf++ = c + '0';
      len--;
      if (len <= 1)
         goto lint_to_str_return;
   }

   ret = E_OK;

lint_to_str_return:
   *buf = '\0';
   return ret;
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


int8_t get_command(const char *cmd, uint8_t rlen)
{
	char **ps, *s;
	uint8_t i, slen;

	ps = (char**) &cmd_;
	for (i = 0; i < sizeof(cmd_)/sizeof(*cmd_); i++)
	{
		// get address from prg memory
		s = pgm_ptr(ps);
		ps++;

		slen = pstrlen(s);
		if ((rlen >= slen) && !pstrncmp(cmd, s, slen))
         return i;
   }

   return -1;
}

