#!/bin/bash
# run_chains.sh : scan insertion + Modus ATPG for 1, 8, 16 and 32 scan chains (lec10 p22)
#   per N: stuck-at ATPG (static faults) + transition ATPG (dynamic faults, launch-on-capture)
#   and Verilog test benches of the stuck-at patterns for simulation (sim_patterns.sh)
# usage: ./run_chains.sh [N ...]        default: 1 8 16 32
cd "$(dirname "$0")"
NETLIST=../03_Synthesis/outputs/cache_netlist.v
LIB=/ECEnet/Apps1/linux/FreePDK45/osu_soc/lib/files/gscl45nm.v
for N in ${@:-1 8 16 32}; do
  D=chains/N$N; rm -rf $D/mdb; mkdir -p $D        # mdb = Modus work database, rebuilt every run
  python3 insert_scan.py $NETLIST $D/cache_scan.v $N
  {
    echo 'assign pin=clk      test_function= -ES;'
    echo 'assign pin=rst_n    test_function= +TI;'
    echo 'assign pin=scan_en  test_function= +SE;'
    if [ $N -eq 1 ]; then
      echo 'assign pin=scan_in  test_function= SI;'
      echo 'assign pin=scan_out test_function= SO;'
    else
      for ((c=0; c<N; c++)); do
        echo "assign pin=scan_in_$c  test_function= SI$c;"
        echo "assign pin=scan_out_$c test_function= SO$c;"
      done
    fi
  } > $D/pins.assign
  cat > $D/atpg.tcl <<EOF
set W mdb
build_model -workdir \$W -cell cache_top -designsource cache_scan.v -techlib $LIB -designtop cache_top -allowmissingmodules no
build_testmode -workdir \$W -testmode FULLSCAN -assignfile pins.assign -modedef FULLSCAN
report_test_structures -workdir \$W -testmode FULLSCAN
verify_test_structures -workdir \$W -testmode FULLSCAN
build_faultmodel -workdir \$W -includedynamic yes
create_scanchain_tests -workdir \$W -testmode FULLSCAN -experiment scan
commit_tests -workdir \$W -testmode FULLSCAN -inexperiment scan
create_logic_tests -workdir \$W -testmode FULLSCAN -experiment logic
commit_tests -workdir \$W -testmode FULLSCAN -inexperiment logic
write_vectors -workdir \$W -testmode FULLSCAN -language verilog -scanformat serial
create_logic_delay_tests -workdir \$W -testmode FULLSCAN -experiment delay
report_fault_statistics -workdir \$W -testmode FULLSCAN
exit
EOF
  ( cd $D && env -i HOME=$HOME USER=$USER LOGNAME=$USER SHELL=/bin/bash TERM=dumb \
      PATH=/ECEnet/Apps1/linux/Cadence/MODUS251/bin:/usr/bin:/bin CDS_LIC_FILE=5280@cadencelm.coe.neu.edu \
      timeout 7200 modus -batch -disable_user_startup -files atpg.tcl > atpg.out 2>&1 )
  echo "N=$N exit $?"
done
echo CHAINS_DONE
