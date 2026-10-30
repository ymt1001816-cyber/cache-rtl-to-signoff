# constraint.sdc : same constraints as synthesis/cache_top.sdc, written for OpenSTA
#   (OpenSTA has no remove_from_collection, so the clock port is removed from the input list with lsearch)
set clk_port [get_ports clk]
create_clock -name clk -period 10 $clk_port
set non_clk_inputs [lsearch -inline -all -not -exact [all_inputs] $clk_port]
set_input_delay  1 -clock clk $non_clk_inputs
set_output_delay 1 -clock clk [all_outputs]
