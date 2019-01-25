#include "serial_io.h"
#include "progmem.h"
#include "parser.h"


#ifndef PROGMEM
#define PROGMEM __attribute__((__progmem__))
#endif

#define SYS_PWRITE(x) sys_pwrite(x, sizeof(x) - 1)
#define PSTRNCMP(x, y) pstrncmp(x, y, sizeof(y) - 1)

#define MEM_RAM 0
#define MEM_PRG 1

const char m_helo_[] PROGMEM = "AVR shell v0.2 (c) 2019 Bernhard Fischer, <bf@abenteuerland.at>";
const char m_prompt_[] __attribute__((__progmem__)) = "Arduino# ";
const char m_ok_[] __attribute__((__progmem__)) = "OK";
const char m_unk_[] PROGMEM = "*** unknown command";
const char m_unk_err_[] PROGMEM = "*** error unknown";
const char m_miss_arg_[] PROGMEM = "*** missing arg";
const char m_null_[] PROGMEM = "** NULL pointer";
const char m_int_[] PROGMEM = "__INTERRUPT__ 0x";

#define CMD_COUNT 6
const char c_in_[] __attribute__((__progmem__)) = "in";
const char c_out_[] __attribute__((__progmem__)) = "out";
const char c_dump_[] __attribute__((__progmem__)) = "dump";
const char c_pdump_[] __attribute__((__progmem__)) = "pdump";
const char c_sbi_[] PROGMEM = "sbi";
const char c_cbi_[] PROGMEM = "cbi";

const char * const cmd_[] __attribute__((__progmem__)) = {c_in_, c_out_, c_dump_, c_pdump_, c_sbi_, c_cbi_};


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
   if (type == MEM_PRG)
      return pgm_byte(addr);

   return *((char*) addr);
}


void mem_dump(const void *addr, int len, int8_t type)
{
   int8_t b, c;
   int i;

   for (i = 0, b = 0; i < len; i++, b++, addr++)
   {
      if (b == 0x10)
      {
         println();
         b = 0;
      }
      if (!b)
      {
         write_hexbyte(((int) addr) >> 8);
         write_hexbyte((int) addr);
         sys_send(':');
         //sys_send(' ');
      }
      if (!(b & 0x07))
         sys_send(' ');

      c = get_mem_byte(addr, type);
      write_hexbyte(c);
      sys_send(' ');
   }
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


int main(void)
{
   unsigned char rlen, slen;
   char buf[256], *cmd;
   char *s, **ps;
   int8_t i, exec;
   int addr;
   int val;

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

      ps = (char**) &cmd_;
      for (i = 0, exec = 0; i < CMD_COUNT && !exec; i++)
      {
         // get address from prg memory
         s = pgm_ptr(ps);
         ps++;

         slen = pstrlen(s);
         if ((rlen >= slen) && !pstrncmp(cmd, s, slen))
         {
            switch (i)
            {
               // in
               case 0:
                  exec++;
                  
                  if (get_int_param0(&cmd, &addr))
                     break;
 
                  val = *((char*)(addr + 0x20));

                  sys_send('0');
                  sys_send('x');
                  write_hexbyte(val);
                  println();

                  break;

               // out
               case 1:
                  exec++;
                  
                  if (get_int_param0(&cmd, &addr))
                     break;
                  if (get_int_param0(&cmd, &val))
                     break;

                  *((char*)(addr + 0x20)) = val;

                  break;

               //dump
               case 2:
               //pdump
               case 3:
                  exec++;

                  if (get_int_param0(&cmd, &addr))
                     break;
 
                  mem_dump((void*) addr, 512, i == 2 ? MEM_RAM : MEM_PRG);

                  break;

               //sbi
               case 4:
                  exec++;
                  
                  if (get_int_param0(&cmd, &addr))
                     break;
                  if (get_int_param0(&cmd, &val))
                     break;

                  addr += 0x20;
                  sbi((char*) addr, val);

                  break;

               //cbi
               case 5:
                  exec++;
                  if (get_int_param0(&cmd, &addr))
                     break;
                  if (get_int_param0(&cmd, &val))
                     break;

                  addr += 0x20;
                  cbi((char*) addr, val);

                  break;
            }
         }
      }

      // unknown command
      if (!exec)
      {
         SYS_PWRITE(m_unk_);
         println();
      }
   }

   // obligatory
   return 0;
}

