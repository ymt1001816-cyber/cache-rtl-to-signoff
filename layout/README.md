# Layout and signoff (Cadence Innovus, Siemens Calibre)

| File | What |
|---|---|
| `layout_run5.tcl`, `mmmc_run5.tcl` | Innovus floorplan → place → CTS → route, with SS / TT / FF analysis views and metal6 power stripes |
| `r5_signoff.sh` | Everything after layout: fill fix, LVS, ERC, DRC, LEC, STA |
| `sta_r5.tcl` | Timing at the three corners |
| `make_lef_antenna.py` | Adds antenna rules (SKY130 ratios) to the LEF; FreePDK45 has none |
| `make_lef_pinfix.py` | Moves LEF pin edges onto the GDS grid (the "0.5 nm gap" bug) |
| `ir_grid.py` | IR-drop resistor-grid model (Innovus rail analysis needs a QRC file FreePDK45 lacks) |
| `run_erc.sh` | Custom Calibre ERC deck: floating wells and nets (FreePDK45 ships no ERC rules) |
| `power_tcf.sh` | Post-layout power with real switching activity |
| `r5_fillfix.tcl` | Fills rows that would otherwise have untapped wells |

## Results (Run 5)

| Check | Result |
|---|---|
| DRC / LVS | Innovus DRC 0, Calibre LVS CORRECT |
| Timing at 100 MHz | SS setup +1.10 ns, worst hold +0.24 ns, TT and FF pass |
| IR drop / EM | 6.1% → 2.2% with metal6 stripes; 0.50 MA/cm² (limit 1.8) |
| Antenna / ERC | Clean |
| Equivalence | Layout netlist = RTL |
| SDF simulation | Gate-level simulation with layout delays passes |

A denser floorplan (placement density 0.75) brings the chip to 221,402 µm² (−19%) with all checks still clean.
The bugs these checks found are listed in the [main README](../README.md#bugs-that-only-signoff-found).
