# Verification Plan: cache_top (1 KB direct-mapped, write-through, no-write-allocate)

lec11 p14: a verification engineer starts from the spec and writes a plan: *what* must be true, *how* each item is checked, and *how we know it was exercised*.
Drafted with an AI assistant from the project results; reviewed by the author.

## 1. Features to verify (from the spec, report Section II)

| ID | Feature / requirement | Check (does it work?) | Coverage (was it exercised?) | Status |
|---|---|---|---|---|
| F1 | Read hit returns the cached word | scoreboard vs `ref_mem` | `cp_read_hit` bin `hit`; `x_line_hit` | ✅ PASS 5,145 |
| F2 | Read miss refills 4 words, then returns the correct word | scoreboard | `cp_read_hit` bin `miss`; cover `c_read_refill` | ✅ |
| F3 | Write goes to memory (write-through) | scoreboard (later reads see the new value) | `cp_op` bin `write`; cover `c_write` | ✅ |
| F4 | Write hit also updates the cache | scoreboard (bug 1: 469 FAIL) | `x_op_word` | ✅ |
| F5 | Write miss does **not** allocate (no memory read) | SVA `a_no_read_on_write` (bug 2: caught only by SVA) | directed Test 4 | ✅ |
| F6 | Reset clears all 64 valid bits | `cache_reset_test` + SVA `a_no_x_ctrl` + `min_checks` (bug 3) | reset test | ✅ |
| F7 | Every request completes (no hang) | SVA `a_req_done`, ≤ 20 cycles (safety); `a_req_eventually`, `s_eventually` (liveness, checked at end of simulation); bug 4 caught by both | all tests | ✅ |
| F8 | Every line and word works | scoreboard | `cp_index` 64/64, `cp_word` 4/4, `x_line_hit` | ✅ 100% |
| F9 | Conflict misses (same index, different tag) | scoreboard | stride seq; biased seq kind 1 | ✅ |
| F10 | No unknown (X) on control outputs | SVA `a_no_x_ctrl`; `-xprop C` run | all tests | ✅ |

## 2. Stimulus (lec11 p44–46)

| Sequence | Type | Targets |
|---|---|---|
| `cache_directed_seq` | directed | F1–F5 corner cases from the proposal (Tests 1–4) |
| `cache_random_seq` | constrained random, 10,000 | F1–F4, F8 |
| `cache_stride_seq` | constrained random | F9 |
| `cache_biased_seq` | biased random (`dist`) | F1 (hot block), F9 (same index) |
| `cache_read_seq` + reset pulse | directed | F6 |

## 3. Regression and sign-off criteria

| Criterion | Target | Result |
|---|---|---|
| All tests pass | 0 UVM_ERROR | ✅ 3 tests |
| Random seeds | 20 seeds pass | ✅ 20 / 20 |
| Functional coverage | 100% | ✅ |
| Every planted bug detected | 4 / 4 | ✅ |
| Lint | 0 errors | ✅ HAL (warnings reviewed) |
| X-propagation | pass with `-xprop C` | ✅ |
| Same testbench on other designs | pass unchanged | ✅ 5 designs |

## 4. Not covered (known limits)

- ~~Code coverage report~~ **done (10/28)** with Verilator (`verification/coverage/CODE_COVERAGE.md`): expression and branch 100%, toggle 99.2%, line 90%; the only misses are unreachable (FSM `default`, `cpu_addr[1:0]`) and are excluded.
- ~~Formal proof~~ **done (10/28)**: no JasperGold on CoE, so SymbiYosys (`verification/formal/`): k-induction proves F5, F7 and `a_one_mem_op` for every input sequence; covers reachable; bug 2 found at step 4, bug 4 at step 22.
- **Timing / gate level**: covered outside UVM (gate-level and SDF simulation with the original testbench, LEC; layout LEC 10/28).
- **Signoff gaps closed 10/28** (`docs/`), fixed in Run 5 (`layout/layout_run5.tcl`):
  - Corners: Spectre FO4 derates (SS 2.90, FF 0.50). Run 4 failed SS setup by 2.577 ns; Run 5 optimizes SS/TT/FF together: SS +1.103 ns, worst hold +0.239 ns (FF).
  - IR / EM: 2-D grid model (`ir_grid.py`; no QRC file for Innovus ERA). Run 4 67 mV (6.1%) -> Run 5 with 4 um M6 stripes 24.5 mV (2.2%); max J 0.50 MA/cm2 < 1.8 (ITRS via Lienig ISPD 2018).
  - Antenna: SKY130 ratios added to the LEF (`make_lef_antenna.py`): no violations.
  - ERC: own Calibre deck (`run_erc.sh`): floating wells in FILL-only rows in Run 4 -> fillers removed -> 0 in Run 5.
  - Run 5 also: Innovus DRC 0, Calibre LVS CORRECT, layout LEC Equivalent, Calibre DRC only library rules.
  - DFT: scan LEC Equivalent (scan_en = 0); 1/8/16/32 chains (`dft/run_chains.sh`): stuck-at 99.99% (~1,280 patterns), transition 66.6% (~3,260); tester cycles 11.1 M -> 0.35 M with 32 chains. Patterns simulated on the netlist (`sim_patterns.sh`, N32): 1,285 tests, 0 miscompares.
  - Power with real activity (Run 5 SDF sim -> TCF -> Innovus): 39.9 -> 33.8 mW; 98% follows the clock.
  - MBIST: `dft/mbist/` (fault-injecting memory + testbench ready; March C- controller written by the author).
