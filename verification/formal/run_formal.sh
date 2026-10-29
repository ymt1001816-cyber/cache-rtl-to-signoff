#!/bin/bash
# run_formal.sh : SymbiYosys (OSS CAD Suite)
# usage (from verification/formal):  bash run_formal.sh        -> bmc, prove, cover, bug4
#   bmc   = check every input sequence up to 80 cycles
#   prove = k-induction: holds for ANY length (needs the helper invariants)
#   cover = the important events are reachable (not vacuous)
#   bug4  = planted hang on line 63 must FAIL a_req_done
command -v sby > /dev/null || export PATH=~/tools/oss-cad-suite/bin:$PATH   # OSS CAD Suite
for t in bmc prove cover bug4; do
  sby -f cache.sby $t > sby_$t.log 2>&1
  echo "== $t: $(grep -o 'DONE ([A-Z]*' sby_$t.log | tail -1 | cut -c7-)"
  grep -E "failed assertion|reached cover" sby_$t.log | sed 's/.*summary: *//'
done
