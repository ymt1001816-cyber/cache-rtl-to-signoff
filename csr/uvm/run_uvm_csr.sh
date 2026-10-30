#!/bin/bash
# run_uvm_csr.sh [test] [seed] : CSR + RAL UVM tests on CoE (Xcelium). Run from csr/uvm.
#   test: csr_reset_test (default) or csr_count_test
#   -xmlibdirname on /tmp and -uvmnocdnsextra: see axi/uvm/run_uvm_axi.sh
T=${1:-csr_reset_test}; SEED=${2:-1}; L=/tmp/xc_csr_$$
xrun -64bit -uvm -uvmnocdnsextra -sv -timescale 1ns/1ps -xmlibdirname $L \
     +incdir+. +incdir+../../axi/uvm +incdir+../../verification/uvm \
     ../../verification/uvm/cache_if.sv ../../axi/uvm/axil_if.sv ../cache_top_csr.v ../axil_cache_csr.v tb_top_csr.sv \
     +UVM_TESTNAME=$T -svseed $SEED -l uvm_${T}_$SEED.log > /dev/null 2>&1 < /dev/null
rm -rf $L
tr -d '\000' < uvm_${T}_$SEED.log | grep -E "\*[EF],|\[CSR\]|\[FLUSH\]|\[SCB\]|RegModel|UVM_ERROR :|UVM_FATAL :|UVM_WARNING :" | head -40
