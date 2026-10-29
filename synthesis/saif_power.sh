#!/bin/bash
# saif_power.sh <name> <netlist> <tb> <dut_module> [sram_model.v] [sram.lib]
# Gate-level simulation of a synthesized netlist with SAIF dump (real switching activity),
# then Genus power with default activity vs the SAIF activity.
source /ECEnet/Apps1/linux/EECE7353/cadence618_eda_tools_cad13_only_safe.sh > /dev/null 2>&1
N=$1; NET=$2; TB=$3; DUT=$4; SV=$5; SL=$6
C=~/EECE7353/cache; OSU=/ECEnet/Apps1/linux/FreePDK45/osu_soc/lib/files
W=$C/02_Verilog/sim/saif/$N; mkdir -p $W; cd $W
sed -E "s/^( *)cache_top[a-z_0-9]* #\(\.LINES\(LINES\)\) dut/\1$DUT dut/" $TB | sed "s/^module tb_cache_posedge;/module tb_cache;/" > tb.v   # netlist has no LINES parameter; one top name for SAIF
grep -c "$DUT dut" tb.v
EXTRA=""; if [ -n "$SV" ]; then sed 's/parameter VERBOSE = 1/parameter VERBOSE = 0/' $SV > sram_model.v; EXTRA=sram_model.v; fi
printf 'dumpsaif -scope tb_cache.dut -hierarchy -internal -output %s.saif -overwrite\nrun\ndumpsaif -end\nexit\n' $N > saif.tcl
S=$(date +%s)
xrun -64bit -timescale 1ns/1ps -access +rwc $NET $OSU/gscl45nm.v $EXTRA tb.v -top tb_cache -input saif.tcl -l xrun.log > /dev/null 2>&1 < /dev/null
echo "[$N] xrun exit $? ($(( $(date +%s) - S )) s)"; grep -E "PASS =" xrun.log; ls -la $N.saif 2>&1 | awk '{print $5, $9}'; grep -i "\*E,\|dumpsaif" xrun.log | head -3
cat > power.tcl <<T
read_libs [concat $OSU/gscl45nm.lib $SL]
read_netlist $NET
read_sdc $C/03_Synthesis/scripts/cache_top.sdc
report_power > power_default.rpt
if {[catch {read_saif -instance tb_cache/dut $N.saif} m]} { puts "SAIF1 ERR: \$m"; if {[catch {read_saif $N.saif -instance tb_cache/dut} m2]} { puts "SAIF2 ERR: \$m2" } }
report_power > power_saif.rpt
exit
T
genus -batch -files power.tcl -log genus_power < /dev/null > genus_power.out 2>&1
echo "[$N] genus exit $?"; grep -h "SAIF[12] ERR\|asserted\|annotat" genus_power.log* | head -5
for f in power_default power_saif; do echo "  $f: $(grep -E "register|logic|memory|Subtotal" $f.rpt | awk '{printf "%s %s  ", $1, $5}')"; done
