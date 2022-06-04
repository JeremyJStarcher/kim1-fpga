PROJECT = KIM_EP2C5

SRC = mcs6502.v mcs6530.sv KIM_1.sv KIM_EP2C5.sv

QUARTUS_SH = quartus_sh --64bit
QUARTUS_PGM = quartus_pgm

# Program the FPGA via JTAG

.PHONY : program
program : $(PROJECT).sof
	$(QUARTUS_PGM) -c 1 -m jtag -o "p;$(PROJECT).sof"

# .sof is for programming the FPGA (JTAG)
# .pof is for programming the configuration flash (ASP)

$(PROJECT).sof $(PROJECT).pof : ROM.hex KIM_EP2C5.tcl $(SRC)
	$(QUARTUS_SH) -t KIM_EP2C5.tcl

# Program the serial configuration Flash

.PHONY : program-flash
program-flash : $(PROJECT).pof
	$(QUARTUS_PGM) -c 1 -m as -o "pv;$(PROJECT).pof"

#
# Check each of the source files
#

.PHONY: lint
lint :
	verilator --lint-only $(SRC)

#
# Convert binary ROM files into ASCII hex for SystemVeriog's
# $readmemb function
#
# RIOT 003's ROM is at 1800
# RIOT 002's ROM is at 1C00
#

ROM.hex : 6530-002.bin 6530-003.bin
	cat 6530-003.bin 6530-002.bin | od -v -t x1 -An > ROM.hex

#6530-002.hex : 6530-002.bin
#	od -v -t x1 -An 6530-002.bin > 6530-002.hex

#6530-003.hex : 6530-003.bin
#	od -v -t x1 -An 6530-003.bin > 6530-003.hex

#
# Compile and run a simulation using Verilator
#

# View the .vcd file
.PHONY : gtkwave
gtkwave : kim1sim.vcd kim1sim.gtkw
	gtkwave kim1sim.vcd  kim1sim.gtkw

kim1sim.vcd : obj_dir/VKIM_1
	obj_dir/VKIM_1

obj_dir/VKIM_1 : $(SRC) kim1sim.cpp
	verilator -trace -cc mcs6502.v mcs6530.sv KIM_1.sv -exe kim1sim.cpp --top-module KIM_1
	cd obj_dir && make -j -f VKIM_1.mk

#
# Clean up generated files
#
.PHONY : clean
clean :
	rm -rf *.hex db incremental_db *.ppf *.cnx *.qpf *.qsf *.rpt *.smsg \
	*.summary *.done *.pof *.sof *.pin *.jdi greybox_tmp obj_dir *.vcd
