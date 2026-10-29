# synth.tcl
# Genus synthesis script for cache_top
# Author: Meiyu Kuo

# ---- Setup ----
set LIB_DIR /ECEnet/Apps1/linux/FreePDK45/osu_soc/lib/files ;# OSU 45nm cells
# Run Genus from 03_Synthesis/.
set RTL_DIR ../02_Verilog/rtl ;# my Verilog

# ---- Read library and design ----
# ---- Extra .lib (e.g. an SRAM macro) and extra Verilog files from the environment ----
set LIBS $LIB_DIR/gscl45nm.lib
if {[info exists ::env(EXTRA_LIB)]} { set LIBS [concat $LIBS $::env(EXTRA_LIB)] }
read_libs $LIBS
# ---- Design: TOP from the environment, default cache_top (e.g. TOP=cache_top_2way) ----
if {[info exists ::env(TOP)]} { set TOP $::env(TOP) } else { set TOP cache_top }
read_hdl $RTL_DIR/$TOP.v
if {[info exists ::env(EXTRA_HDL)]} { foreach f $::env(EXTRA_HDL) { read_hdl $RTL_DIR/$f } }
# ---- Cache size: LINES from the environment, default 64 (1 KB) ----
if {[info exists ::env(LINES)]} { set LINES $::env(LINES) } else { set LINES 64 }

if {$LINES == 64} {
    elaborate $TOP ;# baseline: keep module name and folders
} else {
    elaborate $TOP -parameters [list [list LINES $LINES]]
}

# ---- Output folder name: L<lines> and/or P<period>, baseline uses reports/ outputs/ ----
set TAG ""
if {$TOP ne "cache_top"} { set TAG [string map {cache_top_ ""} $TOP] }
if {$LINES != 64} { set TAG ${TAG}L$LINES }
if {[info exists ::env(PERIOD)]} { set PERIOD $::env(PERIOD); set TAG ${TAG}P$PERIOD }
if {[info exists ::env(FINAL)]} { set TAG ${TAG}final }
if {[info exists ::env(CG)]} { set TAG ${TAG}cg }
if {$TAG eq ""} {
    set RPT reports
    set OUT outputs
} else {
    set RPT reports/$TAG
    set OUT outputs/$TAG
}

# ---- Constraints ----
read_sdc scripts/cache_top.sdc

# Override the clock period if PERIOD is given (re-apply I/O delays for the new clock)
if {[info exists PERIOD]} {
    create_clock -name clk -period $PERIOD [get_ports clk]
    set_input_delay  1 -clock clk [remove_from_collection [all_inputs] [get_ports clk]]
    set_output_delay 1 -clock clk [all_outputs]
}

# ---- FINAL: replace assign statements (feedthroughs) by buffers, so LVS sees no port-to-port shorts ----
if {[info exists ::env(FINAL)]} {
    set_db / .remove_assigns true
    set_remove_assign_options -buffer_or_inverter BUFX2
}

# ---- CG: try automatic clock gating (OSU has no integrated clock-gating cell; see what Genus can do) ----
if {[info exists ::env(CG)]} {
    foreach a {{lp_insert_clock_gating true} {lp_clock_gating_style latch} {lp_clock_gating_min_flops 3}} {
        if {[catch {set_db / .[lindex $a 0] [lindex $a 1]} m]} { puts "CG attr [lindex $a 0] ERR: $m" } else { puts "CG attr [lindex $a 0] OK" }
    }
}

# ---- Synthesize ----
syn_generic
syn_map
syn_opt

# ---- Reports ----
file mkdir $RPT $OUT
report_area   > $RPT/area.rpt
report_power  > $RPT/power.rpt
report_timing > $RPT/timing.rpt
report_gates  > $RPT/gates.rpt
if {[info exists ::env(CG)]} { catch {report_clock_gating > $RPT/clock_gating.rpt} }

# ---- Outputs for layout ----
write_hdl > $OUT/cache_netlist.v
write_sdc > $OUT/cache_top.sdc

exit
