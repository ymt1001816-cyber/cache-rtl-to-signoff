# wb_study.py : write-through (this design) vs write-back, measured as DRAM traffic and energy (lec9 + Horowitz)
# Trace: Test 6 of tb_cache.v (10,000 random reads/writes, 2 KB range) = segment 1 of trace.txt.
from cache_model import load_segments
E_BIT = 20e-12                       # DRAM I/O energy per bit (Horowitz ISSCC 2014)

def run(trace, size, block, assoc, policy):
    """policy: 'WT-NWA' (this design), 'WT-WA', 'WB-WA'. Returns DRAM bytes read/written, transactions, hits."""
    n_sets = size // (block * assoc); sets = [[] for _ in range(n_sets)]; dirty = set()
    rd_b = wr_b = trans = hits = 0; wb_evict = 0
    for op, addr in trace:
        blk = addr // block; idx, tag = blk % n_sets, blk // n_sets; ways = sets[idx]; hit = tag in ways
        if hit:
            hits += 1; ways.remove(tag); ways.append(tag)
        allocate = (op == "R") or policy in ("WT-WA", "WB-WA")
        if not hit and allocate:
            if len(ways) == assoc:
                victim = ways.pop(0)
                if (idx, victim) in dirty:               # write the dirty block back first
                    dirty.discard((idx, victim)); wr_b += block; trans += 1; wb_evict += 1
            ways.append(tag); rd_b += block; trans += 1     # refill
        if op == "W":
            if policy.startswith("WT"):
                wr_b += 4; trans += 1                     # every store goes to DRAM
            elif tag in ways:
                dirty.add((idx, tag))
    flush = len(dirty) * block                            # write-back: dirty data still in the cache at the end
    return dict(read=rd_b, write=wr_b, trans=trans, hit=hits / len(trace), wb_evict=wb_evict, flush=flush)

if __name__ == "__main__":
    t6 = load_segments("trace.txt")[1]
    print("Test 6: %d accesses (%d writes), 1 KB, 16 B blocks" % (len(t6), sum(1 for o, a in t6 if o == "W")))
    for assoc in (1, 2):
        print("== %s" % ("direct-mapped" if assoc == 1 else "2-way"))
        for pol in ("WT-NWA", "WT-WA", "WB-WA"):
            r = run(t6, 1024, 16, assoc, pol); tot = r["read"] + r["write"]
            print("%-7s hit %5.1f%% | DRAM read %6d B, write %6d B, total %6d B | transactions %5d | dirty write-backs %4d | energy %.2f uJ (+ flush %d B)"
                  % (pol, 100 * r["hit"], r["read"], r["write"], tot, r["trans"], r["wb_evict"], tot * 8 * E_BIT * 1e6, r["flush"]))

    # Synthetic workload with write locality (NOT from the RTL testbench): read-modify-write a 512 B array, 8 passes
    w5 = [(op, 0xA000 + a) for p in range(8) for a in range(0, 512, 4) for op in ("R", "W")]
    print("\nW5 (synthetic, write locality): %d accesses, read-modify-write 512 B x 8 passes, 1 KB direct-mapped, 16 B blocks" % len(w5))
    for pol in ("WT-NWA", "WT-WA", "WB-WA"):
        r = run(w5, 1024, 16, 1, pol); tot = r["read"] + r["write"]
        print("%-7s hit %5.1f%% | DRAM read %6d B, write %6d B, total %6d B (+ flush %d B) | transactions %5d | energy %.2f uJ"
              % (pol, 100 * r["hit"], r["read"], r["write"], tot, r["flush"], r["trans"], (tot + r["flush"]) * 8 * E_BIT * 1e6))
