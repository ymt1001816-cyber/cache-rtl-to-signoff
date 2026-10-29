#!/bin/bash
# run_lec11_checks.sh : extra checks suggested by lec11 (no testbench change needed)
#   1. regression: cache_test with 20 random seeds (lec11 p44: each seed = a different test)
#   2. lint: HAL static checks on the RTL (lec11 p32, p34)
#   3. X-propagation: rerun with -xprop C so unknowns are not hidden by if/case (lec11 p32 "X sources")
# usage (from 02_Verilog/uvm):  bash run_lec11_checks.sh      results in regress/
mkdir -p regress
OPT="-64bit -uvm -sv -coverage functional -covoverwrite -timescale 1ns/1ps +incdir+."
SRC="cache_if.sv ../rtl/cache_top.v tb_top.sv"

echo "== 1. regression (20 seeds)" > regress/summary.txt
xrun $OPT $SRC -elaborate -l regress/compile.log > /dev/null 2>&1      # compile once
for s in $(seq 1 20); do
  xrun $OPT $SRC -R +UVM_TESTNAME=cache_test -svseed $s -l regress/seed_$s.log > /dev/null 2>&1
  echo "seed $s : $(grep -o 'PASS = [0-9]*, FAIL = [0-9]*' regress/seed_$s.log) \
 cov $(grep -o 'functional coverage = [0-9.]*%' regress/seed_$s.log | grep -o '[0-9.]*%') \
 $(grep 'UVM_ERROR :' regress/seed_$s.log | tail -1)" >> regress/summary.txt
done

echo "== 2. HAL lint on cache_top.v" >> regress/summary.txt
xrun -64bit -hal ../rtl/cache_top.v -top cache_top -l regress/hal.log > /dev/null 2>&1
grep -E "^\s*(Total|Summary|.*error|.*warning)" -i regress/hal.log | tail -6 >> regress/summary.txt
[ -f xrun.hal.log ] && cp xrun.hal.log regress/
grep -h -o -E "\(([A-Z0-9_]+)\)" regress/hal.log xrun.hal.log 2>/dev/null | sort | uniq -c | sort -rn | head -15 >> regress/summary.txt

echo "== 3. X-propagation (-xprop C)" >> regress/summary.txt
for t in cache_test cache_reset_test; do
  xrun $OPT -xprop C $SRC +UVM_TESTNAME=$t -svseed 1 -xmlibdirname xcelium_xprop.d -l regress/xprop_$t.log > /dev/null 2>&1
  echo "$t : $(grep -o 'PASS = [0-9]*, FAIL = [0-9]*' regress/xprop_$t.log) $(grep 'UVM_ERROR :' regress/xprop_$t.log | tail -1) $(grep -c '\*E,' regress/xprop_$t.log) tool errors" >> regress/summary.txt
done
echo LEC11_DONE >> regress/summary.txt
