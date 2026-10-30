# AXI4-Lite interface

`axil_cache.v` wraps the cache in an AXI4-Lite slave, so a standard bus master can use it. The memory side is unchanged.
Protocol notes: [AXI_GUIDE.md](AXI_GUIDE.md).

| File / folder | What | Result |
|---|---|---|
| `axil_cache.v` | Slave wrapper: AW and W in any order, writes have priority, partial writes (byte strobes) return SLVERR | |
| `tb_axil_cache.sv` | Testbench: random AW/W order and ready delays, reference memory, VALID/READY checks | 0 protocol violations (`ci/regress.sh axi`) |
| `axil_sva.sv` | The same rules as concurrent SVA, attached with `bind` (Xcelium) | 0 assertion failures |
| [`formal/`](formal/) | SymbiYosys k-induction proof with the cache replaced by an unconstrained stub | Rules hold for every input sequence and any cache behavior |
| [`uvm/`](uvm/) | AXI4-Lite master agent (driver, monitor) plugged into the original UVM environment | 3 seeds pass, 100% coverage; a planted data bug fails all 5,145 reads |

**Verification by concern:** SVA and formal check the protocol; the scoreboard checks the data.
