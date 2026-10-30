# cov_merge.py RUN_DIR REPORT.md : merge the per-seed coverage JSON files of a regression
#   - merged hit count of every bin, and the first seed that hit it
#   - coverage per group and in total, coverage after 1, 2, 5, 10, ... seeds (how fast random stimulus closes)
#   - the holes (bins no seed hit); exit code 1 if there is any
import glob, json, os, sys

runs = []
for f in glob.glob(os.path.join(sys.argv[1], "cov_*.json")):
    with open(f) as fh:
        runs.append(json.load(fh))
if not runs:
    sys.exit("no coverage files")
seed_key = lambda r: (int(r["seed"]) if r["seed"].isdigit() else 0, r["test"])
runs.sort(key=seed_key)

groups = runs[0]["hits"]
merged = {g: {b: 0 for b in bins} for g, bins in groups.items()}
first = {g: {b: None for b in bins} for g, bins in groups.items()}
seeds = sorted({r["seed"] for r in runs}, key=lambda s: int(s) if s.isdigit() else 0)
curve, covered_after = {}, set()
total = sum(len(b) for b in groups.values())
for r in runs:
    for g, bins in r["hits"].items():
        for b, n in bins.items():
            merged[g][b] += n
            if n and first[g][b] is None:
                first[g][b] = r["seed"]
for k, s in enumerate(seeds, 1):
    covered_after |= {(g, b) for g in first for b, fs in first[g].items() if fs is not None and seeds.index(fs) < k}
    curve[k] = 100.0 * len(covered_after) / total

holes = [(g, b) for g in merged for b, n in merged[g].items() if n == 0]
covered = total - len(holes)
out = [f"# Functional coverage: {len(seeds)} seeds merged", "",
       f"**{covered} / {total} bins covered ({100.0 * covered / total:.1f}%)**, {len(holes)} holes", "",
       "| Group | Covered | Least-hit bin |", "|---|---|---|"]
for g, bins in merged.items():
    done = sum(1 for n in bins.values() if n)
    least = min(bins.items(), key=lambda kv: kv[1])
    out.append(f"| {g} | {done} / {len(bins)} | {least[0]} ({least[1]}) |")
out += ["", "## Coverage vs number of seeds", "", "| Seeds | Coverage |", "|---|---|"]
for k in [1, 2, 5, 10, 20, 50, 100, 200, 500]:
    if k <= len(seeds):
        out.append(f"| {k} | {curve[k]:.1f}% |")
out += ["", "## Holes", ""] + ([f"- {g}: {b}" for g, b in holes] or ["None."])
out += ["", "## Bins (merged hits, first seed)", "", "| Group | Bin | Hits | First seed |", "|---|---|---|---|"]
for g, bins in merged.items():
    for b, n in bins.items():
        out.append(f"| {g} | {b} | {n} | {first[g][b] or '-'} |")
with open(sys.argv[2], "w") as fh:
    fh.write("\n".join(out) + "\n")
print(f"merged {len(runs)} runs ({len(seeds)} seeds): {covered}/{total} bins ({100.0 * covered / total:.1f}%), {len(holes)} holes")
for g, b in holes:
    print(f"  HOLE {g}: {b}")
sys.exit(1 if holes else 0)
