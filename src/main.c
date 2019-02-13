#include "serial_io.h"
#include "timer.h"
#include "progmem.h"
#include "parser.h"
#include "avrshell.h"
#include "process.h"


#define SYS_PWRITE(x) sys_pwrite(x, sizeof(x) - 1)
#define PSTRNCMP(x, y) pstrncmp(x, y, sizeof(y) - 1)

#define MEM_RAM 0
#define MEM_PRG 1
#define MEM_EEP 3

static const char m_helo_[] PROGMEM = "AVR shell v0.3 (c) 2019 Bernhard Fischer, <bf@abenteuerland.at>";
static const char m_prompt_[] __attribute__((__progmem__)) = "Arduino# ";
static const char m_ok_[] __attribute__((__progmem__)) = "OK";
static const char m_unk_[] PROGMEM = "*** unknown command";
static const char m_unk_err_[] PROGMEM = "*** error unknown";
static const char m_miss_arg_[] PROGMEM = "*** missing arg";
static const char m_null_[] PROGMEM = "** NULL pointer";
static const char m_int_[] PROGMEM = "__INTERRUPT__ 0x";

static const char s_devsig_[] PROGMEM = "device signature = ";
static const char s_oscal_[] PROGMEM = "oscillator calibration = 0x";
static const char s_blb_[] PROGMEM = "boot load lock = 0x";
static const char s_fl_[] PROGMEM = "fuse low = 0x";
static const char s_fh_[] PROGMEM = "fuse high = 0x";
static const char s_ef_[] PROGMEM = "extended fuse = 0x";

static const char m_help0_[] PROGMEM =
   "in <io_reg> ............... read IO register\n"
   "out <io_reg> <byte> ....... write value to IO register\n"
   "cbi <io_reg> <bit> ........ clear bit (0-7) in IO register\n"
   "sbi <io_reg> <bit> ........ set bit (0-7) in IO register\n";
static const char m_help1_[] PROGMEM =
   "lds <memaddr> ............. read byte from memory\n"
   "sts <memaddr> <byte> ...... write byte to memory\n"
   "dump [<memaddr> [<len>]] .. dump <len> bytes of RAM memory\n"
   "pdump [<memaddr> [<len>]] . dump <len> bytes of program memory\n";
static const char m_help2_[] PROGMEM =
   "edump [<memaddr> [<len>] .. dump <len> bytes of EEPROM memory\n"
   "ste <memaddr> <byte> ...... write byte to EEPROM memory\n"
   "cpu ....................... CPU info\n"
   "uptime .................... show system uptime ticks.\n";
static const char m_help3_[] PROGMEM =
   "run <pid> ................. run process <pid>.\n"
   "stop <pid> ................ stop process <pid>.\n"
   "new <address> ............. create new process with start routine at <address>.\n";


void println(void)
{
   sys_send('\n');
}


void write_binbyte(int8_t n)
{
   int8_t i, b;

   for (i = 0; i < 8; i++)
   {
      b = ((n & 0x80) != 0) + '0';
      n <<= 1;
      sys_send(b);
   }
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
   SYS_PWRITE(m_helo_);
   println();
   SYS_PWRITE(m_help0_);
   SYS_PWRITE(m_help1_);
   SYS_PWRITE(m_help2_);
   SYS_PWRITE(m_help3_);
}


void print_fuse(int addr, const char *str)
{
   int8_t byte;
   char s[] = ", ";

   sys_pwrite(str, pstrlen(str));
   byte = read_fuse(addr);
   write_hexbyte(byte);
   sys_write(s, 2);
   write_binbyte(byte);
   println();
}


int main(void)
{
   unsigned char rlen;
   static char buf[256], *cmd;   //FIXME: moved to main memory, buffer too large on stack
   int addr, off;
   int val;
   int8_t cmdnr, byte, err;

   init_serial();
   println();
   SYS_PWRITE(m_helo_);
   println();
 
   for (;;)
   {
      SYS_PWRITE(m_prompt_);
      sys_read_flush();
      rlen = sys_read(buf);
sys_send('\'');
for (int8_t i = 0; i < rlen; i++)
sys_send(i+0x20);
sys_send('\'');
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
            if ((err = get_int_param(&cmd, &addr)))
            {
               if (err != E_NOPARM)
               {
                  output_error(err);
                  break;
               }
               addr = 0;
            }

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

         //ste
         case C_STE:
            if (get_int_param0(&cmd, &addr))
               break;
            if (get_int_param0(&cmd, &val))
               break;

            write_eeprom((char*) addr, val);

            break;
         
         case C_CPU:
            SYS_PWRITE(s_devsig_);
            byte = read_sig(0);
            write_hexbyte(byte);
            sys_send(' ');
            byte = read_sig(2);
            write_hexbyte(byte);
            sys_send(' ');
            byte = read_sig(4);
            write_hexbyte(byte);
            println();

            SYS_PWRITE(s_oscal_);
            byte = read_sig(1);
            write_hexbyte(byte);
            println();

            print_fuse(1, s_blb_);
            print_fuse(0, s_fl_);
            print_fuse(3, s_fh_);
            print_fuse(2, s_ef_);
            break;

         case C_UPTIME:
            lint_to_str(get_uptime(), buf, sizeof(buf));
            sys_write(buf, strlen(buf));
            println();
            break;

         case C_RUN:
            if (get_int_param0(&cmd, &addr))
               break;
            run_proc(addr);
            break;

         case C_STOP:
            if (get_int_param0(&cmd, &addr))
               break;
            stop_proc(addr);
            break;

          case C_NEW:
            if (get_int_param0(&cmd, &addr))
               break;
            addr >>= 1;    // program addresses are word addresses on AVR
            pid_t pid = new_proc((void (*)(void)) addr);
            lint_to_str(pid, buf, sizeof(buf));
            sys_write(buf, strlen(buf));
            println();
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

