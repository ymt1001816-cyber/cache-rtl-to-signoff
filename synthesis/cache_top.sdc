# cache_top.sdc
# Timing constraints for cache_top
# Author: Meiyu Kuo

# Clock: 10 ns period (100 MHz)
create_clock -name clk -period 10 [get_ports clk]

# Inputs and outputs: assume 1 ns used outside the cache
set_input_delay  1 -clock clk [remove_from_collection [all_inputs] [get_ports clk]]
set_output_delay 1 -clock clk [all_outputs]
