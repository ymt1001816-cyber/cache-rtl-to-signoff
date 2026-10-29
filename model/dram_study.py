# dram_study.py : what happens when the cache's memory is a real DDR4 DRAM (lec9) instead of the
# testbench's fixed-latency model, and how much energy the DRAM costs (Horowitz, ISSCC 2014).
# Uses the same CPU trace and cache model as cache_model.py.
import math
from cache_model import load_segments, simulate

# ---- DDR4-3200 timing, lec9 p49 (ns) ----
tRCD, CL, tRP, tBL, tCCD_L = 13.75, 13.75, 13.75, 2.5, 5.0
CTRL = 60.0          # controller + queuing + bus + on-chip wires (lec9 p66); makes a closed-page read ~90 ns, close to lec9 p7 "~100 ns"
ROW_BYTES, BANKS = 8192, 16   # one rank of 8 x8 chips: 1 KB page per chip -> 8 KB row; 16 banks (DDR4)

def dram_first_data_ns(addr, open_rows, policy):
    """Latency from request to first data word; updates the row-buffer state."""
    bank = (addr // ROW_BYTES) % BANKS; row = addr // (ROW_BYTES * BANKS)
    if policy == "closed":                       # precharge after every access
        return tRCD + CL, "closed"
    if open_rows.get(bank) == row:               # row-buffer hit
        return CL, "hit"
    kind = "empty" if bank not in open_rows else "conflict"
    open_rows[bank] = row
    return (tRCD + CL if kind == "empty" else tRP + tRCD + CL), kind

def miss_cycles(block, t_first_ns, tclk_ns):
    """Cache FSM: 3 fixed cycles + wait for the first word + one 32-bit word per cycle after that
    (the cache's 32-bit memory port, not the DRAM, limits the transfer rate)."""
    words = block // 4
    return 3 + math.ceil((t_first_ns + CTRL) / tclk_ns) + (words - 1)

def run(trace, size, block, assoc, tclk_ns, policy):
    """Replay a trace; returns (reads, misses, AMAT cycles, row-buffer hit rate)."""
    n_sets = size // (block * assoc); sets = [[] for _ in range(n_sets)]
    open_rows = {}; reads = misses = cyc = 0; rb = {"hit": 0, "empty": 0, "conflict": 0, "closed": 0}
    for op, addr in trace:
        blk = addr // block; idx, tag = blk % n_sets, blk // n_sets; ways = sets[idx]; hit = tag in ways
        if hit: ways.remove(tag); ways.append(tag)
        if op != "R": continue
        reads += 1
        if hit: cyc += 2; continue
        misses += 1
        t, kind = dram_first_data_ns(blk * block, open_rows, policy); rb[kind] += 1
        cyc += miss_cycles(block, t, tclk_ns)
        if len(ways) == assoc: ways.pop(0)
        ways.append(tag)
    acc = sum(rb.values())
    return reads, misses, cyc / reads, rb["hit"] / acc if acc else 0

# ---- energy (Horowitz ISSCC 2014: DRAM I/O > 20 pJ/bit; a DRAM access 1-2 nJ) ----
E_BIT = 20e-12
def dram_energy(misses, block): return misses * block * 8 * E_BIT

if __name__ == "__main__":
    wl = load_segments("trace.txt")[-4:]; names = ["W1", "W2", "W3", "W4"]
    print("== 1) Block size, 1 KB direct-mapped, W4: AMAT (cycles) with three memory models")
    print("block | testbench (3 cyc/word) | DDR4 open-page 100 MHz | DDR4 closed-page 100 MHz | DDR4 open-page 333 MHz | row-buffer hit")
    for b in (4, 8, 16, 32, 64):
        r, m = simulate(wl[3], 1024, b, 1)
        tb = (2 * (r - m) + (3 + 3 * b // 4) * m) / r
        _, _, o100, rbh = run(wl[3], 1024, b, 1, 10.0, "open")
        _, _, c100, _ = run(wl[3], 1024, b, 1, 10.0, "closed")
        _, _, o333, _ = run(wl[3], 1024, b, 1, 3.0, "open")
        print("%4d B | %22.2f | %22.2f | %24.2f | %22.2f | %5.1f%%" % (b, tb, o100, c100, o333, 100 * rbh))
    print("\n== 1b) Best block per workload (DDR4 open-page, 100 MHz), 1 KB direct-mapped")
    for n, tr in zip(names, wl):
        res = [(run(tr, 1024, b, 1, 10.0, "open")[2], b) for b in (4, 8, 16, 32, 64)]
        print(n, " ".join("%dB:%.2f" % (b, a) for a, b in res), " -> best", min(res)[1], "B")
    print("\n== 2) Energy for W4 (2000 reads), 1 KB, 16 B blocks, 100 MHz, cache power from SAIF")
    designs = [("Flip-flop DM", 1, 13.89e-3, 0), ("Flip-flop 2-way", 2, 13.74e-3, 0),
               ("SRAM DM", 1, 1.46e-3, 1), ("SRAM 2-way", 2, 1.76e-3, 1)]
    for name, assoc, p, sram in designs:
        r, m = simulate(wl[3], 1024, 16, assoc)
        cycles = 2 * (r - m) + (16 if sram else 15) * m          # measured RTL timing
        e_cache = p * cycles * 10e-9; e_dram = dram_energy(m, 16)
        print("%-16s misses %3d | cache %.3f uJ | DRAM %.3f uJ | total %.3f uJ | DRAM share %4.1f%% | per read %.2f nJ"
              % (name, m, e_cache * 1e6, e_dram * 1e6, (e_cache + e_dram) * 1e6, 100 * e_dram / (e_cache + e_dram), (e_cache + e_dram) / r * 1e9))
    print("\n== 2b) DRAM energy vs block size, W4, 1 KB direct-mapped")
    for b in (4, 8, 16, 32, 64):
        r, m = simulate(wl[3], 1024, b, 1)
        print("%2d B: misses %4d, bits moved %7d, DRAM %.2f uJ" % (b, m, m * b * 8, dram_energy(m, b) * 1e6))
