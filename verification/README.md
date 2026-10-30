# Verification

Everything starts from the [verification plan](VERIFICATION_PLAN.md): what must be true, how it is checked, how we know it was exercised.

| Folder | What | How to run | Result |
|---|---|---|---|
| [`tb/`](tb/) | Self-checking Verilog testbench: directed + 10,000 random requests, 4 workloads with hit rate and AMAT | `ci/regress.sh sim` | PASS 8,938, FAIL 0 |
| [`uvm/`](uvm/) | UVM environment: CPU agent, memory responder, scoreboard, covergroups, SVA (Xcelium) | `uvm/run_uvm.sh` | 100% functional coverage, 20/20 seeds, 4/4 planted bugs caught |
| [`cocotb/`](cocotb/) | Python testbench: random memory latency 1–4 cycles, reference model predicts every hit and miss, scoreboard checks data **and memory traffic**, coverage must close | `cd cocotb && make [DUT=cg\|dft]` | ~6,900 checks pass on original, clock-gated and DFT RTL; planted write-allocate bug fails |
| [`formal/`](formal/) | SymbiYosys: bmc, k-induction prove, cover, and a planted hang (bug4) | `ci/regress.sh formal` | prove PASS; bug4 caught |
| [`coverage/`](coverage/CODE_COVERAGE.md) | Code coverage with Verilator | `coverage/run_codecov.sh` | Branch and expression 100%, toggle 99.2% |

## Why several methods

- **Directed + random simulation** finds the bugs you can think of and many you cannot.
- **UVM** makes the environment reusable: the AXI4-Lite agent in [`../axi/uvm/`](../axi/uvm/) reuses the same sequences, scoreboard and coverage unchanged.
- **cocotb** makes the reference model short: a few lines of Python predict hit / miss, so the testbench can check behavior (memory traffic), not just data.
- **Formal** proves properties for every input sequence, which simulation cannot.
- **Code coverage** shows what the tests never reached (the toggle gap is `cpu_addr[1:0]`, which the cache ignores by design).

Register verification with a UVM register model (RAL) is in [`../csr/`](../csr/README.md).
Equivalence (Conformal LEC) and gate-level / SDF simulation are in [`../synthesis/`](../synthesis/README.md) and [`../layout/`](../layout/README.md).
