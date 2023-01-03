//
// this is an example of "host code" that can either run in cosim or on the PS
// we can use the same C host code and
// the API we provide abstracts away the
// communication plumbing differences.

#include <stdlib.h>
#include <stdio.h>
#include <locale.h>
#include <pthread.h>
#include <time.h>
#include <queue>
#include <unistd.h>
#include <bitset>

#include "bp_zynq_pl.h"
#include "bsg_printing.h"
#include "bsg_argparse.h"

#define FREE_DRAM 0
#define DRAM_ALLOCATE_SIZE 120 * 1024 * 1024

#ifndef ZYNQ_PL_DEBUG
#define ZYNQ_PL_DEBUG 0
#endif

#ifndef BP_NCPUS
#define BP_NCPUS 1
#endif

void nbf_load(bp_zynq_pl *zpl, char *);
bool decode_bp_output(bp_zynq_pl *zpl, int data, int* core);

std::queue<int> getchar_queue;

void *monitor(void *vargp) {
  int c = -1;
  while(1) {
    c = getchar();
    if(c != -1)
      getchar_queue.push(c);
  }
}

inline unsigned long long get_counter_64(bp_zynq_pl *zpl, unsigned int addr) {
  unsigned long long val;
  do {
    unsigned int val_hi = zpl->axil_read(  + 4);
    unsigned int val_lo = zpl->axil_read(addr + 0);
    unsigned int val_hi2 = zpl->axil_read(addr + 4);
    if (val_hi == val_hi2) {
      val = ((unsigned long long)val_hi) << 32;
      val += val_lo;
      return val;
    } else
      bsg_pr_err("ps.cpp: timer wrapover!\n");
  } while (1);
}


/////////////////////////////////////// GET ARGV = nbf file name //////////////////////////////////////////////////////////////////////////

#ifndef VCS
int main(int argc, char **argv) {
#else
extern "C" void cosim_main(char *argstr) {
  int argc = get_argc(argstr);
  char *argv[argc];
  get_argv(argstr, argc, argv);
#endif
  // this ensures that even with tee, the output is line buffered
  // so that we can see what is happening in real time

  setvbuf(stdout, NULL, _IOLBF, 0);

  bp_zynq_pl *zpl = new bp_zynq_pl(argc, argv);

  // the read memory map is essentially
  //
  // 0,4,8,C: reset, dram allocated, dram base address
  // 10,14,18,1C,20,24: pl to ps data
  // 28,2C,30,34,38,3C: pl to ps fifo counters
  // 40,44,48,4C,50,54: ps to pl fifo counters

  // the write memory map is essentially
  //
  // 0,4,8,C: registers
  // 10,14,18,1C,20,24: ps to pl fifo

  int data;
  int val1 = 0x1;
  int val2 = 0x0;
  int mask1 = 0xf;
  int mask2 = 0xf;
  std::bitset<BP_NCPUS> done_vec;
  bool core_done = false;

  int allocated_dram = DRAM_ALLOCATE_SIZE;
#ifdef FPGA
  unsigned long phys_ptr;
  volatile int *buf;
#endif

/////////////////////////////////////// R/W Shell CSRs ///////////////////////////////////////////////////////////////////////////////////////

  int val;
  bsg_pr_info("ps.cpp: reading three base registers\n");
  bsg_pr_info("ps.cpp: reset(lo)=%d dram_init=%d, dram_base=%x\n",
              zpl->axil_read(0x0 + GP0_ADDR_BASE),
              zpl->axil_read(0x4 + GP0_ADDR_BASE),
              val = zpl->axil_read(0x8 + GP0_ADDR_BASE));

  bsg_pr_info("ps.cpp: putting BP into reset\n");
  zpl->axil_write(0x0 + GP0_ADDR_BASE, 0x0, mask1); // MC reset

  bsg_pr_info("ps.cpp: attempting to write and read register 0x8\n");

  zpl->axil_write(0x8 + GP0_ADDR_BASE, 0xDEADBEEF, mask1); // MC DRAM base addr
  assert((zpl->axil_read(0x8 + GP0_ADDR_BASE) == (0xDEADBEEF)));
  zpl->axil_write(0x8 + GP0_ADDR_BASE, val, mask1); // MC DRAM base addr
  assert((zpl->axil_read(0x8 + GP0_ADDR_BASE) == (val)));

  bsg_pr_info("ps.cpp: successfully wrote and read registers in bsg_zynq_shell "
              "(verified ARM GP0 connection)\n");


/////////////////////////////////////// RESET ////////////////////////////////////////////////////////////////////////////////

  bsg_pr_info("ps.cpp: asserting reset to BP\n");

  // Assert reset, we do it repeatedly just to make sure that enough cycles pass
  zpl->axil_write(0x0 + GP0_ADDR_BASE, 0x0, mask1);
  assert((zpl->axil_read(0x0 + GP0_ADDR_BASE) == (0)));
  zpl->axil_write(0x0 + GP0_ADDR_BASE, 0x0, mask1);
  assert((zpl->axil_read(0x0 + GP0_ADDR_BASE) == (0)));
  zpl->axil_write(0x0 + GP0_ADDR_BASE, 0x0, mask1);
  assert((zpl->axil_read(0x0 + GP0_ADDR_BASE) == (0)));
  zpl->axil_write(0x0 + GP0_ADDR_BASE, 0x0, mask1);
  assert((zpl->axil_read(0x0 + GP0_ADDR_BASE) == (0)));

  // Deassert reset
  bsg_pr_info("ps.cpp: deasserting reset to BP\n");
  zpl->axil_write(0x0 + GP0_ADDR_BASE, 0x1, mask1);
  zpl->axil_write(0x0 + GP0_ADDR_BASE, 0x1, mask1);
  zpl->axil_write(0x0 + GP0_ADDR_BASE, 0x1, mask1);

  bsg_pr_info("Reset asserted and deasserted\n");
  
  
  

/////////////////   Store packet to arbitrary manycore tile CSR & load packet to same tile ///////////////////////////////////////////////////////


  bsg_pr_info("mc_ps.c Attempting to Store packet to arbitrary manycore tile CSR & load packet to same tile \n");
  
  
   // the write memory map is essentially
  //
  // 0,4,8,C: registers
  // 10,14,18,1C,20,24: ps to pl fifo
	
// PS IO xcord = 0
// PS IO ycord = 1
	
	
  int opocode_addr = 0x10008004; // storing to CSR_DRAM ALLOCATE
  int data27_regid = 0x00000021; // storing 1 to DRAM allocate
  int xy_srcxy_data = 0x60600020; // dest xy= 3/3, src x/y = 0,1
  int unused_y		= 0x00000000;
  
  
  //writing opcode and address to ps to pl fifo 0,1,2,3 to STORE DATA
    bsg_pr_info("mc_ps.cpp: writing STORE to ps to pl fifo \n");
  
  zpl->axil_write(0x00000010,opocode_addr , mask1);
  zpl->axil_write(0x00000014,data27_regid , mask1);
  zpl->axil_write(0x00000018,xy_srcxy_data , mask1);
  zpl->axil_write(0x0000001C,unused_y , mask1);
     
  // Read and discard request
  
  
  // the read memory map is essentially
  //
   // 0,4,8,C,0		   : registers
   // 10,14,18,1C,20,24: pl_to_ps fifo
   // 28,2C,30,34,38,3C: pl_to_ps fifo counters
   // 40,44,48,4C,50,54: ps_to_pl fifo counters
 
  tmp1 = (zpl->axil_read(0x00000020));   
  tmp2 = (zpl->axil_read(0x00000024));
  
  
  //writing opcode and address to ps to pl fifo 0,1,2,3 to LOAD DATA
    bsg_pr_info("mc_ps.cpp: writing LOAD to ps to pl fifo \n");
  
  
  opocode_addr = 0x00008004; // writng 0 to dram allocate
  data27_regid = 0x00000201; // data = payload info = is_unsigned_1 =1 and regid = 1
  xy_srcxy_data = 0x60600020; // dest xy= 3/3, src x/y = 0,1
  unused_y		= 0x00000000; 
   
	
  zpl->axil_write(0x00000010,opocode_addr , mask1);
  zpl->axil_write(0x00000014,data27_regid , mask1);
  zpl->axil_write(0x00000018,xy_srcxy_data , mask1);
  zpl->axil_write(0x0000001C,unused_y , mask1);
  
  
  tmp1 = (zpl->axil_read(0x00000020));   
  tmp2 = (zpl->axil_read(0x00000024));
  
  tmp1 = tmp1>>2;
  assert(tmp1 == 1);

  zpl->done();

  delete zpl;
  exit(EXIT_SUCCESS);
}

