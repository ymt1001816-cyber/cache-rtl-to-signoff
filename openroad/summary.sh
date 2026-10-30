#!/bin/bash
# summary.sh RESULT_DIR : print the key numbers of an ORFS run (area, timing, power, routing DRC)
D=$1
echo "== design area";             grep -h -m1 "Design area" $D/reports/6_finish.rpt $D/logs/6_report.log 2>/dev/null | head -1
echo "== setup / hold (finish)";   grep -h -E "^(tns|wns|worst slack)" $D/reports/6_finish.rpt 2>/dev/null | head -6
echo "== power";                   grep -h -A6 -E "^Group +Internal" $D/reports/6_finish.rpt 2>/dev/null | tail -5
echo "== cell count";              grep -h -m1 -E "Number of cells|Cell type report" -A1 $D/reports/synth_stat.txt 2>/dev/null | head -3
echo "== detailed route DRC";      grep -h -E "Number of violations|violations = " $D/logs/5_2_route.log 2>/dev/null | tail -1
echo "== runtime per step";        for f in $D/logs/*.log; do t=$(grep -h -o "Elapsed time: [0-9:.]*" $f | tail -1); [ -n "$t" ] && echo "  $(basename $f .log): $t"; done
