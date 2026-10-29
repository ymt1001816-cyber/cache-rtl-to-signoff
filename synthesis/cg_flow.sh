#!/bin/bash
# cg_flow.sh : clock-gated design (cache_top_cg + clk_gate) -> Genus -> SAIF power -> LEC, compared with cache_top
source /ECEnet/Apps1/linux/EECE7353/cadence618_eda_tools_cad13_only_safe.sh > /dev/null 2>&1
C=~/EECE7353/cache; cd $C/03_Synthesis
echo "[1] synthesis $(date +%H:%M)"
TOP=cache_top_cg EXTRA_HDL=clk_gate.v timeout 3600 genus -batch -files scripts/synth.tcl -log logs/genus_cg < /dev/null > logs/genus_cg.out 2>&1
echo "genus exit $?"; ls -la outputs/cg/cache_netlist.v
for d in reports reports/cg; do echo "-- $d"; grep -E "^cache_top" $d/area.rpt | head -2; grep -E "Subtotal|register|logic|clock" $d/power.rpt | head -5; grep -m1 -i "slack" $d/timing.rpt; done
grep -E "LATCH|AND2|DFFPOSX1|MUX2|OAI21|Total" reports/cg/gates.rpt | head -10
echo "[2] SAIF power $(date +%H:%M)"
bash scripts/saif_power.sh cg $C/03_Synthesis/outputs/cg/cache_netlist.v $C/02_Verilog/tb/tb_cache.v cache_top_cg
echo "[3] LEC $(date +%H:%M)"
bash scripts/lec_all.sh cache_top_cg
echo CG_FLOW_DONE
