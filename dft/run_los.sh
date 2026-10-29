#!/bin/bash
# run_los.sh N : launch-on-shift (LOS) transition ATPG on an existing chains/N<N> Modus database
#   LOC (run_chains.sh): launch vector = the circuit's own response to the scan load (66.6%)
#   LOS: launch vector = the last scan shift, so every flop can launch a transition; needs scan_en to switch at speed
cd "$(dirname "$0")/chains/N${1:-32}" || exit 1
cat > los.tcl <<T
create_logic_delay_tests -workdir mdb -testmode FULLSCAN -experiment los -dynseqfilter losintra
report_fault_statistics -workdir mdb -testmode FULLSCAN -experiment los
exit
T
env -i HOME=$HOME USER=$USER LOGNAME=$USER SHELL=/bin/bash TERM=dumb \
  PATH=/ECEnet/Apps1/linux/Cadence/MODUS251/bin:/usr/bin:/bin CDS_LIC_FILE=5280@cadencelm.coe.neu.edu \
  timeout 7200 modus -batch -disable_user_startup -files los.tcl > los.out 2>&1
echo "exit $?"; grep -E "^Total Dynamic|ERROR|WARNING \(TDA" los.out | tail -6
awk '/INFO \(TDA-220\): +[0-9]+ +[0-9]+/{l=$0} END{print "last:", l}' los.out
echo LOS_DONE
