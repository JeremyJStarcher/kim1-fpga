create_clock -name "clk50" -period "50 MHz" [get_ports {clk50}]

create_generated_clock \
 -source [get_ports clk50] \
 -divide_by 50 \
 [get_registers clk]
 
derive_pll_clocks -create_base_clocks
derive_clock_uncertainty