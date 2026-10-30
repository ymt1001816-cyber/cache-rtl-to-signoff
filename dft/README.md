# Design for test

The OSU library has no scan flip-flop, so `insert_scan.py` builds each scan cell from a MUX2 + inverter in front of the flip-flop
and stitches all flip-flops into 1–32 chains. ATPG and pattern simulation use Cadence Modus.

| File | What |
|---|---|
| `insert_scan.py` | Scan insertion on the mapped netlist; falling- and rising-edge flip-flops go to separate chains |
| `run_chains.sh`, `run_los.sh` | Stuck-at and transition ATPG for 1 / 8 / 16 / 32 chains; launch-on-shift |
| `sim_patterns.sh` | Verilog simulation of the ATPG patterns on the scan netlist |
| `lec_scan.do` | LEC: scan netlist = RTL when scan is disabled |
| [`mbist/`](mbist/) | March C- MBIST controller, fault-injecting memory model and testbench |
| `dft_flow.sh`, `scan_compare.sh` | Clock-gated design with test enable: synthesis → LEC → scan → ATPG |
| `tb_dft.sv`, `cache_top_wrap.v` | Test-mode checks of the DFT RTL; wrapper to run the original testbench on it |
| `te_scan_en.sh` | Same scan netlist and ATPG, with the clock-gate test enable driven by scan_en instead of a tied pin |

## Scan and ATPG

| Chains | Stuck-at coverage | Tester cycles |
|---|---|---|
| 1 | 99.99% | 11.1 M |
| 32 | 99.99% | 0.35 M (31× fewer) |

Patterns pass gate-level simulation with 0 miscompares; a planted defect makes 151 tests fail.
Transition faults: launch-on-capture 66.6%, launch-on-shift 70.9% with 41% fewer patterns.

## Clock gating vs scan

Clock gates stop the clock while the cache is idle, and scan shift happens while it is idle.

| Design | Chains that shift | Stuck-at coverage |
|---|---|---|
| Clock gating, no test enable | 2 of 32 | 84.3% |
| Clock gate with test enable (`rtl/clk_gate_te.v`) | 32 of 32 | **99.84%** |

The test enable goes into the latch with the functional enable (`en | test_en`), so the gated clock stays glitch-free.

### Where should the test enable come from?

| Test enable driven by | Testmode coverage | Global coverage | Untested faults | Patterns |
|---|---|---|---|---|
| Its own pin, tied to 1 for the whole test | 99.84% | 98.97% | 552 | 1,294 |
| **scan_en** | **99.99%** | **99.94%** | **17** | 1,267 |

Tied to 1, the clock gates are open in capture too, so the enable logic that picks which word is written can never be tested
(its faults are inactive). Driven by scan_en, the gates are forced open only while shifting and follow the functional enable in capture,
so 2,816 more faults become testable and untested faults drop from 552 to 17, with slightly fewer patterns.
Genus mapped the gated flip-flops to falling-edge flip-flops behind a NAND gate, which is why the scan script keeps the two edges in separate chains.

## MBIST

`mbist_march.v` runs March C- (10N operations, 2,561 cycles for 256 words). In `rtl/cache_top_dft.v` it writes the real data array
through the same clock gates, so it tests the clock gates too: forcing one gate off makes MBIST fail.

## Logic diagnosis (from a tester fail log back to the defect)

[`diag/`](diag/): `prepare_diagnostics_setup` injects random logic faults and `report_fault_effects` writes the fail log each one
would cause on a tester (Chip-Pad-Pattern format: failing scan-out pin, pattern, scan offset, value). Modus `diagnose_failset_logic`
needs a Modus_Diagnostics license the school does not have, so `fault_dict_diag.py` does cause-effect diagnosis by fault-dictionary
matching, scored like commercial tools: TFSF (tester fail, simulation fail), TFSP (tester fail, simulation pass) and TPSF (tester pass,
simulation fail).

| Fail log | Injected fault found at | TFSF / TFSP / TPSF |
|---|---|---|
| Complete (74 failures) | rank 1 of 261 detected candidates | 74 / 0 / 0 |
| Tester kept only 40% (30 failures) | rank 1 | 30 / 0 / 44 |

With a truncated log TPSF grows (predicted failures the tester did not record) but TFSP stays 0: every recorded failure is still
explained, which is why diagnosis weighs TFSP most. Limitation: the 400 decoy candidates are random faults, which are easy to tell
apart; real tools pick candidates by back-tracing from the failing outputs, where neighbouring and equivalent faults are much closer.

