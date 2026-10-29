#!/bin/bash
# lec_all.sh [designs...] : Conformal LEC, RTL vs mapped netlist, with the dofiles Genus wrote (fv/<design>/rtl_to_fv_map.do)
source /ECEnet/Apps1/linux/EECE7353/cadence618_eda_tools_cad13_only_safe.sh > /dev/null 2>&1
export PATH=/ECEnet/Apps1/linux/Cadence/CONFRML261/bin:$PATH
cd ~/EECE7353/cache/03_Synthesis; mkdir -p logs/lec   # -xl: the default license tier (CFMA_Basic) is not on the school server
D=${@:-cache_top cache_top_2way cache_top_sram cache_top_sram_reg cache_top_sram_2way}
echo "host $(hostname) start $(date +%H:%M)"
for d in $D; do
  S=$(date +%s)
  lec -64 -xl -nogui -tclmode -dofile fv/$d/rtl_to_fv_map.do -logfile logs/lec/$d.log < /dev/null > logs/lec/$d.out 2>&1
  r=$(grep -E "^ *(Equivalent|Non-equivalent|Aborted|Not-compared)" logs/lec/$d.log | awk '{printf "%s %s  ", $1, $2}')
  printf "%-26s exit %s (%4d s)  %s\n" $d $? $(( $(date +%s) - S )) "$r"
  grep -h "// Error\|ERROR" logs/lec/$d.log | head -2
done
echo "LEC DONE $(date +%H:%M)"
