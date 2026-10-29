#!/bin/bash
# run_uvm.sh : compile and run the UVM testbench on a CoE machine (Xcelium)
# usage (from 02_Verilog/uvm):  bash run_uvm.sh [test_name] [seed]
# -coverage functional: Xcelium does not sample covergroups unless coverage is enabled
# -abvrecordcoverall: count every cover property match, not only the first one
# -64bit: some CoE hosts lack the 32-bit libz that randomization needs (*F,RNCNL)
TEST=${1:-cache_test}
SEED=${2:-1}
xrun -64bit -uvm -sv -coverage functional -covoverwrite -abvrecordcoverall -timescale 1ns/1ps +incdir+. \
     cache_if.sv ../rtl/cache_top.v tb_top.sv \
     +UVM_TESTNAME=$TEST -svseed $SEED -l uvm_$TEST.log
grep -E "\[SCB\]|\[COV\]|UVM_ERROR :|UVM_FATAL :" uvm_$TEST.log
