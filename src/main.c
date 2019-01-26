#include "serial_io.h"
#include "progmem.h"
#include "parser.h"
#include "avrshell.h"


#define SYS_PWRITE(x) sys_pwrite(x, sizeof(x) - 1)
#define PSTRNCMP(x, y) pstrncmp(x, y, sizeof(y) - 1)

#define MEM_RAM 0
#define MEM_PRG 1
#define MEM_EEP 3

static const char m_helo_[] PROGMEM = "AVR shell v0.2 (c) 2019 Bernhard Fischer, <bf@abenteuerland.at>";
static const char m_prompt_[] __attribute__((__progmem__)) = "Arduino# ";
static const char m_ok_[] __attribute__((__progmem__)) = "OK";
static const char m_unk_[] PROGMEM = "*** unknown command";
static const char m_unk_err_[] PROGMEM = "*** error unknown";
static const char m_miss_arg_[] PROGMEM = "*** missing arg";
static const char m_null_[] PROGMEM = "** NULL pointer";
static const char m_int_[] PROGMEM = "__INTERRUPT__ 0x";

static const char m_help0_[] PROGMEM =
   "in <io_reg> ............... read IO register\n"
   "out <io_reg> <byte> ....... write value to IO register\n"
   "cbi <io_reg> <bit> ........ clear bit (0-7) in IO register\n"
   "sbi <io_reg> <bit> ........ set bit (0-7) in IO register\n";
static const char m_help1_[] PROGMEM =
   "lds <memaddr> ............. read byte from memory\n"
   "sts <memaddr> <byte> ...... write byte to memory\n"
   "dump <memaddr> [<len>] .... dump <len> bytes of RAM memory\n"
   "pdump <memaddr> [<len>} ... dump <len> bytes of program memory\n";


void println(void)
{
   sys_send('\n');
}


void write_hexbyte(char a)
{
   int a0;

   a0 = a;
   a >>= 4;
   a = nibble_to_ascx(a);
   sys_send(a);
   a0 = nibble_to_ascx(a0);
   sys_send(a0);
}


void write_ptr(const void *ptr)
{
   int a, a0;

   a = a0 = (int) ptr;
   write_hexbyte(a >> 8);
   write_hexbyte(a0);
}


int8_t get_mem_byte(const void *addr, int8_t type)
{
   switch (type)
   {
      case MEM_EEP:
         return read_eeprom(addr);

      case MEM_PRG:
         return pgm_byte(addr);
   }

   return *((char*) addr);
}


void mem_dump(const void *addr, int len, int8_t type)
{
   int8_t b, c;
   int i;
   char buf[16];

   for (i = 0, b = 0; i < len; i++, b++, addr++)
   {
      // after 16 bytes start new line
      if (b == 0x10)
      {
         sys_write(buf, 16);
         println();
         b = 0;
      }
      // print address at the beginning of a new line
      if (!b)
      {
         write_hexbyte(((int) addr) >> 8);
         write_hexbyte((int) addr);
         sys_send(':');
         //sys_send(' ');
      }
      // extra space after 8 bytes
      if (!(b & 0x07))
         sys_send(' ');

      c = get_mem_byte(addr, type);
      write_hexbyte(c);
      sys_send(' ');

      if (c >= 0x20 && c < 0x7f)
         buf[b] = c;
      else
         buf[b] = '.';
   }

   // last line, fill with spaces
   for (i = b; i < 16; i++)
   {
      // extra space after 8 bytes
      if (!(i & 0x07))
         sys_send(' ');

      sys_send(' ');
      sys_send(' ');
      sys_send(' ');
   }

   // final character output
   sys_write(buf, b);
   println();
}


void sbi(char *addr, int8_t b)
{
   int8_t a;

   a = *addr;
   a |= 1 << (b & 0x7);
   *addr = a;
}


void cbi(char *addr, int8_t b)
{
   int8_t a;

   a = *addr;
   a &= ~(1 << (b & 0x7));
   *addr = a;
}


void output_error(int8_t err)
{
   switch (err)
   {
      case E_OK:
         break;
         
      case E_NULL:
         SYS_PWRITE(m_null_);
         println();
         break;

      case E_NOPARM:
         SYS_PWRITE(m_miss_arg_);
         println();
         break;
 
      default:
         SYS_PWRITE(m_unk_err_);
         println();
   }
 
}


int8_t get_int_param0(char **cmd, int *parm)
{
   int8_t err;

   err = get_int_param(cmd, parm);
   output_error(err);

   return err;
}


void help(void)
{
   SYS_PWRITE(m_help0_);
   SYS_PWRITE(m_help1_);
}


int main(void)
{
   unsigned char rlen;
   char buf[256], *cmd;
   int addr, off;
   int val;
   int8_t cmdnr;

   init_serial();
   println();
   SYS_PWRITE(m_helo_);
   println();
 
   for (;;)
   {
      SYS_PWRITE(m_prompt_);
      sys_read_flush();
      rlen = sys_read(buf);

      cmd = buf;
      // skip leading spaces
      for (; *cmd == ' '; cmd++);
      if (*cmd == '#' || is_eos(*cmd))
         continue;

      cmdnr = get_command(cmd, rlen);
      off = 0;

      switch (cmdnr)
      {
         // lds
         // in
         case C_IN:
            off = 0x20;

         case C_LDS:
            if (get_int_param0(&cmd, &addr))
               break;

            addr += off;

            val = *((char*)(addr));

            sys_send('0');
            sys_send('x');
            write_hexbyte(val);
            println();

            break;

         // out
         case C_OUT:
            off = 0x20;

         case C_STS:
            if (get_int_param0(&cmd, &addr))
               break;
            if (get_int_param0(&cmd, &val))
               break;

            *((char*)(addr + off)) = val;

            break;

         //edump
         case C_EDUMP:
            off |= MEM_EEP;

         //pdump
         case C_PDUMP:
            off |= MEM_PRG;

         //dump
         case C_DUMP:
            if (get_int_param0(&cmd, &addr))
               break;

            val = 512;
            get_int_param(&cmd, &val);
            mem_dump((void*) addr, val, off);

            break;

         //sbi
         case C_SBI:
            if (get_int_param0(&cmd, &addr))
               break;
            if (get_int_param0(&cmd, &val))
               break;

            addr += 0x20;
            sbi((char*) addr, val);

            break;

         //cbi
         case C_CBI:
            if (get_int_param0(&cmd, &addr))
               break;
            if (get_int_param0(&cmd, &val))
               break;

            addr += 0x20;
            cbi((char*) addr, val);

            break;
         
         case C_HELP:
            help();
            break;

         // unknown command
         default:
            SYS_PWRITE(m_unk_);
            println();
      } /* switch (cmdnr) */
   }

   // obligatory
   return 0;
}

