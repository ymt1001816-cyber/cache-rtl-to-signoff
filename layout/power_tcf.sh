#!/bin/bash
# power_tcf.sh : power from real switching activity instead of the default 0.2 toggle rate
#   1. Run 5 layout netlist + SDF, original testbench (10 ns clock) -> toggle counts of every net (TCF file)
#   2. Innovus reads the TCF into the Run 5 database and reports power again (reports_R5/power_tcf.rpt)
source /ECEnet/Apps1/linux/EECE7353/cadence618_eda_tools_cad13_only_safe.sh > /dev/null 2>&1
C=~/EECE7353/cache; OSU=/ECEnet/Apps1/linux/FreePDK45/osu_soc/lib/files
W=$C/02_Verilog/sim/pwr_r5; mkdir -p $W; cd $W
sed 's/cache_top #(.LINES(LINES)) dut/cache_top dut/' $C/02_Verilog/tb/tb_cache.v > tb_cache_gl.v
sed -i "s/mem_ack <= 1'b0;/mem_ack <= #1 1'b0;/; s/mem_ack  <= 1'b1;/mem_ack  <= #1 1'b1;/; s/mem_rdata     <= mem\\[mem_addr\\];/mem_rdata     <= #1 mem[mem_addr];/" tb_cache_gl.v
cat > sdf_annot.v <<V
module sdf_annot;
  initial \$sdf_annotate("$C/04_Layout/outputs_R5/cache_top.sdf", tb_cache.dut, , "sdf_annotate.log", "MAXIMUM");
endmodule
V
cat > tcf.tcl <<T
dumptcf -scope tb_cache.dut -output r5.tcf -overwrite
run
dumptcf -end
exit
T
[ -s r5.tcf ] || xrun -64bit -timescale 1ns/1ps -access +rc $C/04_Layout/outputs_R5/cache_final.v $OSU/gscl45nm.v tb_cache_gl.v sdf_annot.v \
     -top tb_cache -top sdf_annot -input tcf.tcl -l xrun_tcf.log > /dev/null 2>&1 < /dev/null
echo "xrun exit $?"; grep -E "PASS =|FAIL" xrun_tcf.log | tail -3; ls -la r5.tcf
cd $C/04_Layout
cat > pwr_tcf.tcl <<T
restoreDesign outputs_R5/cache_top_final.enc.dat cache_top
set_power_analysis_mode -analysis_view typ_view
report_power -outfile reports_R5/power_default_typ.rpt
read_activity_file -format TCF -scope dut $W/r5.tcf      ;# the TCF's top instance is "dut"
report_power -outfile reports_R5/power_tcf.rpt
exit
T
innovus -no_gui -files pwr_tcf.tcl -log pwr_tcf > /dev/null 2>&1 < /dev/null
echo "innovus exit $?"; grep -E "Total Power:|annotation coverage" reports_R5/power_default_typ.rpt reports_R5/power_tcf.rpt; grep -A4 "Activity annotation summary" pwr_tcf.log
echo POWER_TCF_DONE
