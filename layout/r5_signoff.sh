#!/bin/bash
# r5_signoff.sh : everything after layout_run5.tcl (run from 04_Layout/, in the background)
source /ECEnet/Apps1/linux/EECE7353/cadence618_eda_tools_cad13_only_safe.sh > /dev/null 2>&1
export USE_CALIBRE_VCO=aoi
C=~/EECE7353/cache; L=$C/04_Layout; V=$C/05_Calibre/lvs
cd $L
echo "[0] antenna / DRC / connectivity from Innovus"; tail -3 reports_R5/antenna.rpt; grep -h "Verification Complete\|Found no problems" logs/innovus_R5.log* | sort | uniq -c
echo "[1] fill fix $(date +%H:%M)"
timeout 1800 innovus -nowin -files scripts/r5_fillfix.tcl -log logs/innovus_R5fix > logs/r5_fillfix.out 2>&1 < /dev/null; grep FILLFIX logs/r5_fillfix.out
echo "[2] LVS $(date +%H:%M)"; cd $V
v2lvs -v $L/outputs_R5/cache_final_pg.v -lsp cells_lvs.sp -o src_r5.sp -s $V/cells_lvs.sp > v2lvs_r5.log 2>&1
awk 'BEGIN{h=0} /^\.SUBCKT cache_top /{h=1; print; next} h&&!/^\+/{print "+ vdd gnd"; h=0} {print}' src_r5.sp > src_r5_ports.sp
timeout 3600 bash ~/EECE7353/tools/run_lvs.sh $L/outputs_R5/cache_top_final.gds cache_top $V/src_r5_ports.sp cache_top r5
echo "[3] ERC $(date +%H:%M)"; cd $L
timeout 3600 bash scripts/run_erc.sh $L/outputs_R5/cache_top_final.gds r5
echo "[4] DRC $(date +%H:%M)"
timeout 7200 bash ~/EECE7353/tools/run_drc_all.sh $L/outputs_R5/cache_top_final.gds cache_top r5 | tail -3
echo "[5] LEC $(date +%H:%M)"; cd $C/03_Synthesis
export PATH=/ECEnet/Apps1/linux/Cadence/CONFRML261/bin:$PATH
NETLIST=../04_Layout/outputs_R5/cache_final.v timeout 900 lec -64 -xl -nogui -tclmode -dofile fv_layout/lec_layout.do -logfile logs/lec/layout_R5.log < /dev/null > logs/lec/layout_R5.out 2>&1
grep -E "^ *(Equivalent|Non-equivalent|Aborted)|Compared points" logs/lec/layout_R5.log | head -4
echo "[6] STA $(date +%H:%M)"; cd $L
timeout 1800 innovus -nowin -files scripts/sta_r5.tcl -log logs/innovus_R5sta > logs/sta_r5.out 2>&1 < /dev/null; grep -E "^CORNER|^STRIPES" logs/sta_r5.out
echo "[ALL DONE] $(date +%H:%M)"
