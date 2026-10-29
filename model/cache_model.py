# cache_model.py : fast cache model for design-space exploration (DSE C1)
# Replays the CPU trace recorded from tb_cache.v (trace_dump.v) on any
# size / block size / associativity, with the same policy as cache_top.v:
# write-through, no-write-allocate, LRU replacement inside a set.
#
# Timing model (matches the RTL + testbench memory, MEM_LAT = 2):
#   hit  = 2 cycles (IDLE + COMPARE)
#   miss = 3 + 3 x (words per block)   -> 15 cycles for 4-word blocks

def load_segments(path):
    """Split the trace at each RESET; returns a list of [(op, addr), ...]."""
    segs, cur = [], []
    for line in open(path):
        t = line.split()
        if t[0] == "RESET":
            segs.append(cur); cur = []
        else:
            cur.append((t[0], int(t[1], 16)))
    segs.append(cur)
    return segs

def simulate(trace, size, block, assoc):
    """Return (reads, misses) for one cold-start run."""
    n_sets = size // (block * assoc)
    sets = [[] for _ in range(n_sets)]        # each set: list of tags, most recent last
    reads = misses = 0
    for op, addr in trace:
        blk = addr // block
        idx, tag = blk % n_sets, blk // n_sets
        ways = sets[idx]
        hit = tag in ways
        if hit:
            ways.remove(tag); ways.append(tag)  # update LRU order
        if op == "R":
            reads += 1
            if not hit:                         # read miss: refill, evict LRU if full
                misses += 1
                if len(ways) == assoc:
                    ways.pop(0)
                ways.append(tag)
        # op == "W": write-through, no-write-allocate -> no change on a miss
    return reads, misses

def amat(reads, misses, block):
    miss_cycles = 3 + 3 * (block // 4)
    return (2 * (reads - misses) + miss_cycles * misses) / reads

WORKLOADS = ["W1 scan 512B x2", "W2 loop 768B x8", "W3 stride 1KB", "W4 hot 80/20"]

if __name__ == "__main__":
    import sys
    segs = load_segments(sys.argv[1] if len(sys.argv) > 1 else "trace.txt")
    wl = segs[-4:]                              # the last four segments are W1..W4
    print("== Check against RTL (direct-mapped, 16-byte blocks)")
    for size in (256, 512, 1024, 2048):
        row = []
        for name, tr in zip(WORKLOADS, wl):
            r, m = simulate(tr, size, 16, 1)
            row.append("%s %5.1f%% AMAT %5.2f" % (name[:2], 100 * (r - m) / r, amat(r, m, 16)))
        print("%5d B | " % size + " | ".join(row))
