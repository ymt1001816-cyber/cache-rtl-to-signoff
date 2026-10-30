# Coverage closure

The first coverage model had 6 bins and was 100% after one run, which said little.
It was refined to 7 groups and 94 bins, then a 100-seed regression was merged to find what the stimulus never reached.

## Flow

1. **Coverage model** (`Coverage` in `test_cache.py`): op_result (hit, cold miss, conflict miss for reads; hit / miss for writes),
   tag_range, line_refill (all 64 lines), op_word, mem_latency (memory read / write × latency 1–4), sequences
   (read after write to the same word / same line, re-fetch of an evicted tag), address corners.
2. **Regression** (`regress.sh SEEDS N`): every seed runs all tests with 1,000 random requests; each test writes its bin counts to JSON.
3. **Merge** (`cov_merge.py`): merged counts, first seed that hit each bin, coverage vs number of seeds, list of holes.
   (The university's Cadence IMC is too old to read Xcelium 26 coverage databases, so the merge is a short Python script.)
4. **Close the holes**, rerun, confirm 100% with every check still passing.

## Result

| | Bins covered (100 seeds) | 1 seed | 10 seeds | 100 seeds |
|---|---|---|---|---|
| Before ([report](reports/coverage_baseline.md)) | 91 / 94 | 96.8% | 96.8% | 96.8% |
| After ([report](reports/coverage_closure.md)) | **94 / 94** | 100% | 100% | 100% |

**Holes before closure:** `tag 32-62`, `tag 63`, `highest address 0xFFFC`.

**Why more seeds did not help:** coverage was flat from 1 to 100 seeds. The random address generator only used 4 of the 64 tags
(it was written to create reuse, so that hits and conflict misses happen). No seed could reach the upper address space:
a stimulus constraint problem, not a lack of simulation time.

**Fixes:**

- `random_addr()`: 20% of requests anywhere in the 64 KB space, 80% local (keeps the hit and conflict bins covered).
- `test_address_corners`: a directed test for the lowest and highest address and a read of another word right after a write,
  because random stimulus almost never lands exactly on 0xFFFC.

Every one of the 100 seeds passes all data and memory-traffic checks after the change.
CI runs a 20-seed regression (`ci/regress.sh cov`) and fails if any bin is empty.
