#!/bin/bash
# run_codecov.sh : code coverage of cache_top.v with Verilator (CoE has no IMC to report Xcelium code coverage)
# usage (from 02_Verilog/coverage):  bash run_codecov.sh
# Uses the original self-checking testbench (tb/tb_cache.v). Build files go to /tmp, not iCloud.
# Xcode's /usr/bin compilers are blocked until "sudo xcodebuild -license", so the Command Line Tools clang is used directly.
CLT=/Library/Developer/CommandLineTools; SDK=$CLT/SDKs/MacOSX.sdk
export PATH=$CLT/usr/bin:~/tools/oss-cad-suite/bin:$PATH
HERE=$(pwd); B=/tmp/cache_codecov; rm -rf $B; mkdir -p $B; cd $B
verilator --binary --timing --coverage -Wno-fatal -Wno-lint -Wno-style --top-module tb_cache \
  "$HERE/../rtl/cache_top.v" "$HERE/../tb/tb_cache.v" -j 4 \
  -MAKEFLAGS "CXX=$CLT/usr/bin/clang++ LINK=$CLT/usr/bin/clang++" -CFLAGS "-isysroot $SDK" -LDFLAGS "-isysroot $SDK" > build.log 2>&1
./obj_dir/Vtb_cache | grep "PASS ="
verilator_coverage --annotate annot --annotate-min 1 coverage.dat | tail -2
cp annot/cache_top.v "$HERE/cache_top_annotated.v"      # lines marked %000000 were never hit
echo "annotated source: cache_top_annotated.v"
