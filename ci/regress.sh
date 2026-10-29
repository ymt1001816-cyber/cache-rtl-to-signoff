#!/bin/bash
# regress.sh : open-source regression (Icarus Verilog + SymbiYosys); exits non-zero if any check fails
#   usage: ci/regress.sh [sim|sim_cg|mbist|dft|cocotb|axi|formal|all]      (default all)
cd "$(dirname "$0")/.."; mkdir -p build; fails=0
check() {   # check <name> <log> <pattern that must appear>
  if grep -q "$3" "$2"; then echo "PASS  $1"; else echo "FAIL  $1  (see $2)"; fails=$((fails+1)); fi
}
run_sim() { # run_sim <name> <dut module> <rtl files...>
  local n=$1 m=$2; shift 2
  sed "s/cache_top #(.LINES(LINES)) dut/$m #(.LINES(LINES)) dut/" verification/tb/tb_cache.v > build/tb_$n.v
  iverilog -g2012 -o build/$n.vvp "$@" build/tb_$n.v && (cd build && vvp -n $n.vvp > $n.log)
  check "$n: self-checking testbench, 10,000 random + directed requests" build/$n.log "FAIL = 0"
}
what=${1:-all}
if [[ $what == sim || $what == all ]]; then run_sim sim cache_top rtl/cache_top.v; fi
if [[ $what == sim_cg || $what == all ]]; then run_sim sim_cg cache_top_cg rtl/cache_top_cg.v rtl/clk_gate.v; fi
if [[ $what == mbist || $what == all ]]; then
  iverilog -g2012 -o build/mbist.vvp dft/mbist/mem_fault.sv dft/mbist/mbist_march.v dft/mbist/tb_mbist.sv && vvp -n build/mbist.vvp > build/mbist.log
  check "mbist: March C- finds 5 injected memory faults" build/mbist.log "ALL 6 PASSED"
fi
if [[ $what == dft || $what == all ]]; then
  iverilog -g2012 -o build/dft.vvp rtl/cache_top_dft.v rtl/clk_gate_te.v dft/mbist/mbist_march.v dft/tb_dft.sv && (cd build && vvp -n dft.vvp > dft.log)
  check "dft: test_en opens the clock gates, MBIST passes on the data array and finds a broken clock gate" build/dft.log "ALL DFT CHECKS PASSED"
  run_sim sim_dft cache_top rtl/cache_top_dft.v rtl/clk_gate_te.v dft/mbist/mbist_march.v dft/cache_top_wrap.v
fi
if [[ $what == cocotb || $what == all ]]; then
  for d in base cg dft; do
    (cd verification/cocotb && make DUT=$d > ../../build/cocotb_$d.log 2>&1)
    check "cocotb $d: random memory latency, hit/miss reference model, coverage closed" build/cocotb_$d.log "TESTS=2 PASS=2 FAIL=0"
  done
  (cd verification/cocotb && make BUG=write_allocate > ../../build/cocotb_bug.log 2>&1)
  check "cocotb bug: planted write-allocate bug is caught by the memory-traffic check" build/cocotb_bug.log "1 memory writes, 4 memory reads"
fi
if [[ $what == axi || $what == all ]]; then
  iverilog -g2012 -o build/axi.vvp rtl/cache_top.v axi/axil_cache.v axi/tb_axil_cache.sv && vvp -n build/axi.vvp > build/axi.log
  check "axi: AXI4-Lite wrapper, random AW/W order and ready delays, protocol checks, SLVERR" build/axi.log "ALL CHECKS PASSED"
fi
if [[ $what == formal || $what == all ]]; then
  (cd verification/formal && for t in bmc prove cover bug4; do sby -f cache.sby $t > ../../build/formal_$t.log 2>&1; done)
  check "formal bmc: no assertion fails in 80 cycles" build/formal_bmc.log "DONE (PASS"
  check "formal prove: k-induction proof" build/formal_prove.log "DONE (PASS"
  check "formal cover: key events reachable" build/formal_cover.log "DONE (PASS"
  check "formal bug4: planted hang is caught" build/formal_bug4.log "DONE (FAIL"
  (cd axi/formal && for t in bmc prove cover; do sby -f axil.sby $t > ../../build/axi_formal_$t.log 2>&1; done)
  check "axi formal prove: AXI4-Lite rules hold for every input sequence and any cache behavior" build/axi_formal_prove.log "DONE (PASS"
  check "axi formal bmc + cover" build/axi_formal_cover.log "DONE (PASS"
fi
echo "$fails failed"; exit $fails
