# 1 KB Cache: RTL to Signoff (45 nm)

A 1 KB direct-mapped, write-through cache taken from Verilog RTL to a DRC-clean, LVS-correct layout in FreePDK45,
with a full verification stack (UVM, SVA, formal, LEC, gate-level/SDF simulation) and design-for-test (scan, ATPG, MBIST).

Course project, EECE 7353 VLSI Design, Northeastern University, Fall 2026 · Meiyu Kuo

<p align="center"><img src="docs/figures/fig_layout_run4.png" width="420" alt="Placed and routed cache layout"></p>

## Results at a glance

| Area | Result |
|---|---|
| Functional verification | UVM testbench: 100% functional coverage, 20/20 random seeds pass, 4/4 planted bugs caught |
| Formal | SymbiYosys k-induction proves no-write-allocate, bounded latency, one memory operation at a time |
| Code coverage | Branch and expression 100%, toggle 99.2% (Verilator) |
| Equivalence | Conformal LEC: RTL = netlist = layout netlist (8,725 points); scan netlist = RTL with scan disabled |
| Layout | Innovus DRC 0, Calibre LVS CORRECT, 274,294 µm² chip |
| Timing | Passes SS / TT / FF corners at 100 MHz (SS setup +1.10 ns, worst hold +0.24 ns) |
| Power integrity | IR drop 6.1% → 2.2% after adding metal6 stripes; EM 0.50 MA/cm² (limit 1.8) |
| Extra signoff | Antenna clean (SKY130 ratios), custom Calibre ERC clean |
| DFT | Scan insertion script, 1–32 chains: 99.99% stuck-at coverage; 32 chains cut tester cycles 31× (11.1 M → 0.35 M); patterns verified in gate-level simulation (0 miscompares; a planted defect gives 151 failing tests); transition faults: launch-on-capture 66.6%, launch-on-shift 70.9% with 41% fewer patterns |
| MBIST | March C- controller (10N = 2,561 cycles) catches stuck-at, transition, coupling and address-decoder faults |
| Power | 33.8 mW with real switching activity, 98% of it following the clock |
| Clock gating | Latch-based clock gates in RTL (one per word): cells −50%, area −38%, real-activity power −70% (13.9 → 4.1 mW) at synthesis; same testbench passes; LEC equivalent incl. 256 latches |

## Bugs that only signoff found

1. **Floating set pins**: 50 flip-flop set pins were tied to 1 in the netlist but never wired to VDD. Innovus was clean; Calibre LVS caught it.
2. **A 0.5 nm gap**: the library LEF pins are on a 0.5 nm grid, the GDS on 1 nm. Three clock wires ended exactly on the LEF edge and were open in silicon. Fixed by moving LEF pin edges 2.5 nm inward (stays on the manufacturing grid).
3. **Floating wells**: a custom ERC deck found rows that held only filler cells, so their wells had no tap. DRC and LVS cannot see this (no transistors).
4. **A post-layout race**: the testbench memory changed data exactly at the clock edge; with clock-tree latency the refill was off by one word. Fixed by matching the SDC input delay.

## Design-space exploration

16 cache variants (4 sizes × flip-flop or SRAM storage × direct-mapped or 2-way) were synthesized, plus a write-back version; SRAM versions use OpenRAM macros.
An SRAM-based cache is 5.4× smaller but its read data arrives late in the cycle; a 2-way SRAM cache was the best balance.

<p align="center"><img src="docs/figures/fig_design_space.png" width="480" alt="Design space: area vs AMAT"></p>

## Repository layout

| Folder | Contents |
|---|---|
| `rtl/` | Cache RTL (direct-mapped, 2-way, write-back, SRAM variants, clock-gated version) |
| `verification/` | Self-checking testbench, UVM environment + SVA, SymbiYosys formal, code coverage, verification plan |
| `model/` | Python reference model (miss counts, AMAT, DRAM energy) |
| `synthesis/` | Genus script, constraints, SAIF power, LEC |
| `layout/` | Innovus script (MMMC corners, power stripes), antenna LEF generator, IR-drop grid solver, ERC deck, signoff pipeline |
| `dft/` | Scan insertion, Modus ATPG flow, pattern simulation, MBIST (controller, fault-injecting memory, testbench) |
| `docs/figures/` | Figures from the report |

## Tools

Cadence Xcelium, Genus, Innovus, Conformal, Modus, Spectre · Siemens Calibre · SymbiYosys · Verilator · Icarus Verilog · OpenRAM · Python.
PDK and standard cells (FreePDK45, OSU gscl45nm) are not included. Scripts use the university's tool paths; adjust them for another setup.

## My role and AI use

I wrote the RTL, the testbench and UVM components, the SVA properties, the clock-gating RTL and the MBIST controller.
As allowed by the course, I used an AI assistant (Claude) to help set up the tool flows and write several scripts
(layout, signoff, scan insertion, ATPG, IR-drop model, ERC deck, formal environment assumptions, the MBIST fault-injecting memory and testbench) and to draft documentation.
I ran, reviewed and can explain every step.
