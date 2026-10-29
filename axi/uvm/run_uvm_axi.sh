#!/bin/bash
# run_uvm_axi.sh [seed] : AXI4-Lite UVM test on CoE (Xcelium). Run from axi/uvm.
#   also compiles the protocol SVA (../axil_sva.sv, bound into axil_cache)
#   -xmlibdirname on /tmp: the compiled library on the NFS home got corrupted (*F,DLPAKC)
#   -uvmnocdnsextra: the Cadence UVM add-on package is not needed and failed to compile (*E,UVMCXF)
SEED=${1:-1}; L=/tmp/xc_axi_$$
xrun -64bit -uvm -uvmnocdnsextra -sv -coverage functional -covoverwrite -abvrecordcoverall -timescale 1ns/1ps -xmlibdirname $L \
     +incdir+. +incdir+../../verification/uvm \
     ../../verification/uvm/cache_if.sv axil_if.sv ../../rtl/cache_top.v ../axil_cache.v ../axil_sva.sv tb_top_axi.sv \
     -svseed $SEED -l uvm_axi_$SEED.log > /dev/null 2>&1 < /dev/null
rm -rf $L
tr -d '\000' < uvm_axi_$SEED.log | grep -E "\*[EF],|\[SCB\]|\[COV\] functional|UVM_ERROR :|UVM_FATAL :|COVER "
echo "SVA failures: $(tr -d '\000' < uvm_axi_$SEED.log | grep -c 'ASRTST')"
