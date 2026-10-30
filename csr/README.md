# Control / status registers (CSR) and UVM RAL

`axil_cache_csr.v` adds a register block to the AXI4-Lite cache: AXI address bit 16 = 1 selects the registers, bit 16 = 0 the cache.
Register accesses do not touch the cache and complete at once.

| Address | Register | Access | Content |
|---|---|---|---|
| 0x1_0000 | ID | RO | `0xCA0E_0001` |
| 0x1_0004 | CTRL | RW | bit 0 `cnt_en`: counters on (reset 1) |
| 0x1_0008 | CMD | WO | bit 0 `flush`: invalidate every line; bit 1 `cnt_clr`: clear the counters (write 1, reads 0) |
| 0x1_000C | HIT_CNT | RO | Read hits |
| 0x1_0010 | MISS_CNT | RO | Read misses |
| 0x1_0014 | WR_CNT | RO | Writes |
| other | | | SLVERR |

`cache_top_csr.v` is `rtl/cache_top.v` with a `flush` input.

## Verification

**RTL testbench** (`tb_csr.sv`, Icarus, in CI as `ci/regress.sh csr`): reset values, read-only and unmapped registers (SLVERR),
2,000 random cache accesses with every counter compared to a reference tag model, `cnt_en` freezing, `cnt_clr`, and flush
(warm lines miss afterwards, data unchanged). Two planted bugs (hit/miss swapped, flush ignored) both fail it.

**UVM register model** ([`uvm/`](uvm/), Xcelium): the AXI4-Lite UVM environment from [`../axi/uvm/`](../axi/uvm/) plus

| File | What |
|---|---|
| `cache_reg_model.sv` | RAL model: one class per register type, address map at 0x1_0000; counters are volatile |
| `axil_reg_adapter.sv` | Register operations ↔ AXI transactions (`reg2bus` / `bus2reg`) |
| `csr_counter.sv` | Independent counter reference, built only from what the AXI monitor sees |
| `csr_env.sv` | Connects the model to the AXI sequencer (auto-predict) |
| `csr_test.sv` | `csr_reset_test`: `uvm_reg_hw_reset_seq` + `uvm_reg_bit_bash_seq`. `csr_count_test`: 3,000 random accesses, then the counters vs the reference, `cnt_en`, `cnt_clr`, flush |

| Test | Result |
|---|---|
| `csr_reset_test` | Every register reads its reset value; bit bash passes (CMD is excluded: its bits are trigger pulses) |
| `csr_count_test` | All counter reads match the reference; all 32 warm lines miss after flush; scoreboard 1,758 reads, 0 errors |
| Planted bug (wrong ID reset value) | Caught by `uvm_reg_hw_reset_seq` |

Run on a machine with Xcelium: `cd uvm && ./run_uvm_csr.sh csr_reset_test` (or `csr_count_test`).
