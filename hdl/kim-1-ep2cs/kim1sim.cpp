#include <iostream>
#include "VKIM_1.h"
#include "verilated.h"
#include <verilated_vcd_c.h>

int main(int argc, const char ** argv, const char ** env) {
  Verilated::commandArgs(argc, argv);

  VKIM_1 * dut = new VKIM_1;
  
  Verilated::traceEverOn(true);
  VerilatedVcdC * tfp = new VerilatedVcdC;
  dut->trace(tfp, 99);
  tfp->open("kim1sim.vcd");

  dut->ENABLE_TTY = 1;
  dut->DECODE_ENABLE = 0;
  dut->KB_COL = 0x7f; // No key pressed
  dut->TTYI = 1;

  for (int time = 0 ; time < 100000 ; time++) {
    if (time == 0) dut->reset = 1;
    if (time == 5) dut->reset = 0;
    if (time == 20000) dut->TTYI = 0;
    if (time == 21000) dut->TTYI = 1;
    if (time == 29000) dut->TTYI = 0;
    if (time == 30000) dut->TTYI = 1;
    dut->clk = (time & 2) ? 1 : 0;
    dut->eval();

    tfp->dump( time );
  }
  
  tfp->close();
  delete tfp;

  dut->final();
  delete dut;

  return 0;
}
