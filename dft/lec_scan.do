// lec_scan.do : Conformal LEC, RTL (golden) vs scan-inserted netlist (revised) in functional mode
// DFT insertion changes the D input of every flip-flop, so it must be proven harmless when scan_en = 0.
set_undefined_cell black_box -noascend -both
read_library -liberty -both /ECEnet/Apps1/linux/FreePDK45/osu_soc/lib/files/gscl45nm.lib
read_design -verilog -golden ../02_Verilog/rtl/cache_top.v
read_design -verilog -revised cache_scan.v
set_root_module cache_top -both
add_pin_constraints 0 scan_en -revised
add_ignored_inputs scan_in -revised
add_ignored_outputs scan_out -revised
set_system_mode lec
add_compared_points -all
compare
report_compare_data -summary
report_verification
exit -force
