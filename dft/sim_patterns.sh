#!/bin/bash
# sim_patterns.sh N [fault] : simulate the Modus stuck-at patterns on the scan netlist with Xcelium
#   The Modus test bench (VER.FULLSCAN.mainsim.v) shifts every pattern through the scan chains and
#   compares each scan-out and output bit with the value ATPG expects.
#   good run : 0 miscompares (ATPG and simulation agree on the netlist)
#   fault    : force one output to 0 (a planted defect) -> the patterns must report miscompares
source /ECEnet/Apps1/linux/EECE7353/cadence618_eda_tools_cad13_only_safe.sh > /dev/null 2>&1
cd "$(dirname "$0")/chains/N$1" || exit 1
V=mdb/testresults/verilog
TOP=$(grep -m1 -oE "^ *module +\w+" $V/VER.FULLSCAN.mainsim.v | awk '{print $2}')
INST=$(grep -A1 -E "^ *cache_top *$" $V/VER.FULLSCAN.mainsim.v | tail -1 | awk '{print $1}')   # instance name is on the next line
TAG=good; TCL=""
if [ -n "$2" ]; then
  TAG=fault; printf 'force %s.%s.cpu_ready 0\nrun\nexit\n' $TOP $INST > force.tcl; TCL="-input force.tcl"
fi
echo "top $TOP  dut $INST  run $TAG  start $(date +%H:%M)"
S=$(date +%s)
xrun -64bit -access +rwc -xmlibdirname xcelium_$TAG /ECEnet/Apps1/linux/FreePDK45/osu_soc/lib/files/gscl45nm.v cache_scan.v \
     $V/VER.FULLSCAN.mainsim.v -top $TOP $TCL \
     +TESTFILE1=$V/VER.FULLSCAN.data.scan.ex1.ts1.verilog +TESTFILE2=$V/VER.FULLSCAN.data.logic.ex2.ts1.verilog \
     -l sim_$TAG.log > /dev/null 2>&1 < /dev/null
echo "xrun exit $? ($(( $(date +%s) - S )) s)"
grep -E "Total Number of (Cycles|Tests)|Passed Tests|Failed Tests|Good Compares|Miscompares" sim_$TAG.log
echo SIM_DONE
