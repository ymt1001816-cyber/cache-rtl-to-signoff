# Code coverage of cache_top.v (Verilator 5.053, original testbench tb_cache.v, 10/28)

Simulation: PASS = 8,994, FAIL = 0 (Verilator's $random sequence differs from Xcelium, so the count differs from 8,938).

| Metric (lec11 p53-54) | Covered | Not covered and why |
|---|---|---|
| Expression / condition | 27 / 27 = 100% | - |
| Branch | 18 / 18 = 100% | - |
| Toggle | 494 / 498 = 99.2% | cpu_addr[1:0] never toggles: the CPU only sends word-aligned addresses (same rule as illegal_bins cp_align) -> exclude |
| Line (statement) | 9 / 10 = 90% | line 78 `default: state <= IDLE;` is unreachable: all 4 values of the 2-bit state have their own case item -> exclude (defensive code) |

With the two justified exclusions, every reachable line, branch, expression, and bit is exercised.
Xcelium also collected code coverage (`-coverage all`), but CoE has no IMC to report it.
