#!/bin/bash
# scan_compare.sh NAME NETLIST [EXTRA_ASSIGN_LINES...] : 32-chain scan insertion + Modus stuck-at ATPG on a netlist
#   used to compare the clock-gated design without test_en (cache_top_cg) and with test_en (cache_top_dft)
cd "$(dirname "$0")"; N=$1; NET=$2; shift 2
D=run_$N; rm -rf $D/mdb; mkdir -p $D
python3 ../insert_scan.py $NET $D/cache_scan.v 32
{ echo 'assign pin=clk      test_function= -ES;'; echo 'assign pin=rst_n    test_function= +TI;'; echo 'assign pin=scan_en  test_function= +SE;'
  for ((c=0; c<32; c++)); do echo "assign pin=scan_in_$c  test_function= SI$c;"; echo "assign pin=scan_out_$c test_function= SO$c;"; done
  for l in "$@"; do echo "$l"; done; } > $D/pins.assign
cat > $D/atpg.tcl <<T
set W mdb
build_model -workdir \$W -cell cache_top -designsource cache_scan.v -techlib /ECEnet/Apps1/linux/FreePDK45/osu_soc/lib/files/gscl45nm.v -designtop cache_top -allowmissingmodules no
build_testmode -workdir \$W -testmode FULLSCAN -assignfile pins.assign -modedef FULLSCAN
verify_test_structures -workdir \$W -testmode FULLSCAN
report_test_structures -workdir \$W -testmode FULLSCAN
build_faultmodel -workdir \$W -includedynamic no
create_scanchain_tests -workdir \$W -testmode FULLSCAN -experiment scan
commit_tests -workdir \$W -testmode FULLSCAN -inexperiment scan
create_logic_tests -workdir \$W -testmode FULLSCAN -experiment logic
report_fault_statistics -workdir \$W -testmode FULLSCAN -experiment logic
exit
T
( cd $D && env -i HOME=$HOME USER=$USER LOGNAME=$USER SHELL=/bin/bash TERM=dumb \
    PATH=/ECEnet/Apps1/linux/Cadence/MODUS251/bin:/usr/bin:/bin CDS_LIC_FILE=5280@cadencelm.coe.neu.edu \
    timeout 5400 modus -batch -disable_user_startup -files atpg.tcl > atpg.out 2>&1 )
echo "[$N] modus exit $?"
grep -E "ERROR|^ *[0-9]+ (ERROR|WARNING) \(TSV|TSV-[0-9]+" $D/atpg.out | sort | uniq -c | sort -rn | head -8
grep -E "Number of (controllable|observable) scan chains|Longest Scan Chain|scan chains.*(broken|not)" $D/atpg.out | head -6
awk '/INFO \(TDA-220\): +[0-9]+ +[0-9]+/{l=$0} END{print "last ATPG line:", l}' $D/atpg.out
grep -E "^Total Static" $D/atpg.out | tail -2
echo "SCAN_COMPARE_DONE $N"
