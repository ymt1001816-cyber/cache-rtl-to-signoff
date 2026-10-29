# sta_r5.tcl : Run 5 post-route timing in every view (derates are part of the Run 5 MMMC setup)
restoreDesign outputs_R5/cache_top_final.enc.dat cache_top
set_analysis_view -setup {ss_view typ_view ff_view} -hold {ff_view typ_view ss_view}
file mkdir reports_R5
set fp [open reports_R5/corners.txt w]
foreach v {typ_view ss_view ff_view} {
  set s [get_property [report_timing -view $v -late  -max_paths 1 -collection] slack]
  set h [get_property [report_timing -view $v -early -max_paths 1 -collection] slack]
  puts $fp "$v setup_WNS=$s hold_WNS=$h"; puts "CORNER $v setup_WNS=$s hold_WNS=$h"
}
close $fp
report_power -view typ_view -outfile reports_R5/power_typ.rpt
puts "STRIPES [llength [dbGet [dbGet top.nets.name vdd -p].sWires.shape stripe -p]]"
exit
