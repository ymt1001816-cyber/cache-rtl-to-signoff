# Synthesis, power and equivalence

| File | What |
|---|---|
| `synth.tcl` | Genus script. `TOP=<module>` picks the design (cache_top, 2-way, SRAM, clock-gated, DFT); `FINAL=1` turns feedthrough assigns into buffers for LVS |
| `cache_top.sdc` | 100 MHz clock, 1 ns input / output delay |
| `saif_power.sh` | Power with real switching activity from simulation (SAIF) instead of a default toggle rate |
| `lec_all.sh` | Conformal LEC, RTL vs mapped netlist |
| `cg_flow.sh` | Clock-gated design: synthesis → SAIF power → LEC |

## Clock gating

The data array is 256 words of flip-flops, and almost all power follows the clock (98%). A latch-based clock gate per word
(`rtl/clk_gate.v`, `rtl/cache_top_cg.v`) lets the clock reach a word only when it is written.

| | Without clock gating | With clock gating |
|---|---|---|
| Synthesis power (real activity) | 13.9 mW | 4.11 mW (−70%) |
| Layout power (real activity) | 33.8 mW | 4.56 mW (−86%) |
| Chip area | 274,294 µm² | 146,136 µm² (−47%) |
| LEC | Equivalent | Equivalent (incl. 256 latches) |

Clock gating breaks scan unless the clock gate has a test enable: see [`../dft/`](../dft/README.md).
