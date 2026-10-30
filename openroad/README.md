# Open-source RTL to GDS (OpenROAD-flow-scripts)

The same `rtl/cache_top.v`, taken to GDS with open-source tools only, in GitHub Actions
([workflow](../.github/workflows/openroad.yml), pinned ORFS image). Start it from **Actions → openroad → Run workflow**;
the GDS, reports and logs are saved as an artifact, and the key numbers appear on the run's summary page.

| Step | Cadence flow | This flow |
|---|---|---|
| Synthesis | Genus | Yosys + ABC |
| Place, CTS, route | Innovus | OpenROAD, TritonCTS, TritonRoute |
| Timing | Innovus / Tempus | OpenSTA |
| Cells | OSU gscl45nm | Nangate45 (same FreePDK45 process) |

## Result

| Check | Result |
|---|---|
| Routing DRC | 0 violations |
| Setup at 100 MHz | +6.42 ns worst slack |
| Hold | No violations |
| Equivalence | ORFS LEC passes after timing repair and at the end |
| Cells | 29,266 (8,646 flip-flops), 74,719 µm² at 41% utilization |
| Runtime | About 20 minutes on a free GitHub runner |

The numbers differ from the Cadence flow mainly because the cell libraries differ (Nangate cells are smaller and faster), so this is
a check that the design closes in an independent flow, not a tool-vs-tool benchmark.

`config.mk` raises `SYNTH_MEMORY_MAX_BITS` to 8,192: the data array is built from flip-flops on purpose, and ORFS stops at
4,096 bits by default to catch memories that should have been SRAM macros.
