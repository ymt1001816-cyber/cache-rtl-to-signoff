#!/bin/bash
# regress.sh [SEEDS] [N] [DUT] : run the cocotb tests with SEEDS different random seeds (default 100, N requests each),
#   one coverage JSON per test and seed in cov_runs/, then merge them (cov_merge.py -> COVERAGE_REPORT.md)
#   exit code: number of failing seeds; the merge fails too if any coverage bin is still empty
cd "$(dirname "$0")"
SEEDS=${1:-100}; N=${2:-1000}; DUT=${3:-base}
rm -rf cov_runs; mkdir -p cov_runs
fails=0
for ((s = 1; s <= SEEDS; s++)); do
  if COV_DIR="$PWD/cov_runs" make DUT=$DUT N=$N COCOTB_RANDOM_SEED=$s > cov_runs/seed_$s.log 2>&1 \
     && grep -q "FAIL=0" cov_runs/seed_$s.log; then :; else fails=$((fails + 1)); echo "seed $s FAILED (cov_runs/seed_$s.log)"; fi
done
echo "$SEEDS seeds, $fails failed"
python3 cov_merge.py cov_runs COVERAGE_REPORT.md || fails=$((fails + 1))
exit $fails
