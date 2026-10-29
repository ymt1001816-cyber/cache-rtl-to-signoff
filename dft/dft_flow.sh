#!/bin/bash
# dft_flow.sh : cache_top_dft (clock gates with test_en + MBIST) -> Genus (FINAL, same as the control run) -> LEC
#               -> 32-chain scan insertion + Modus stuck-at ATPG with test_en tied to 1
#   compare with run_cg_no_te/ (cache_top_cg, no test_en: 84.26%)
source /ECEnet/Apps1/linux/EECE7353/cadence618_eda_tools_cad13_only_safe.sh > /dev/null 2>&1
C=~/EECE7353/cache; cd $C/03_Synthesis
echo "[1] synthesis $(date +%H:%M)"
[ -s outputs/dftfinal/cache_netlist.v ] || TOP=cache_top_dft EXTRA_HDL="clk_gate_te.v mbist_march.v" FINAL=1 timeout 3600 \
    genus -batch -files scripts/synth.tcl -log logs/genus_dftfinal < /dev/null > logs/genus_dftfinal.out 2>&1
ls -la outputs/dftfinal/cache_netlist.v || { echo "no netlist, stop"; exit 1; }
grep -E "^cache_top" reports/dftfinal/area.rpt | head -2; grep -m1 -i "slack" reports/dftfinal/timing.rpt
grep -E "LATCH|DFFNEGX1|DFFPOSX1|DFFSR" reports/dftfinal/gates.rpt | head -6
# same rename as the control run: insert_scan.py and Modus expect a top module called cache_top
sed -E 's/^module cache_top_dft( |\()/module cache_top\1/' outputs/dftfinal/cache_netlist.v > outputs/dftfinal/cache_netlist_top.v
echo "[2] LEC $(date +%H:%M)"
bash scripts/lec_all.sh cache_top_dft
echo "[3] scan + ATPG $(date +%H:%M)"
# test_en = 1: every clock gate open, so all chains shift; test_mode / mbist_start = 0: MBIST off, normal data path
bash $C/09_DFT/cg_mbist/scan_compare.sh dft_te $C/03_Synthesis/outputs/dftfinal/cache_netlist_top.v \
    'assign pin=test_en     test_function= +TI;' \
    'assign pin=test_mode   test_function= -TI;' \
    'assign pin=mbist_start test_function= -TI;'
D=$C/09_DFT/cg_mbist/run_dft_te
echo "TSV-315 (flop not in a working chain): $(grep -c 'WARNING (TSV-315)' $D/atpg.out)"
grep -E "TTM-35[79]" $D/atpg.out | head -2
echo DFT_FLOW_DONE
