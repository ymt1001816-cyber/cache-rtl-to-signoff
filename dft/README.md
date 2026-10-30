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
Genus mapped the gated flip-flops to falling-edge flip-flops behind a NAND gate, which is why the scan script keeps the two edges in separate chains.

## MBIST

`mbist_march.v` runs March C- (10N operations, 2,561 cycles for 256 words). In `rtl/cache_top_dft.v` it writes the real data array
through the same clock gates, so it tests the clock gates too: forcing one gate off makes MBIST fail.
