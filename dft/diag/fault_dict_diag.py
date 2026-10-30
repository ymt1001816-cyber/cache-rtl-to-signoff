# fault_dict_diag.py OBSERVED.cpp CANDIDATE_DIR [drop_fraction] [seed]
#   Cause-effect diagnosis by fault-dictionary matching (the school has no Modus_Diagnostics license).
#   OBSERVED.cpp : tester fail log in Chip-Pad-Pattern format (here produced by report_fault_effects for an injected fault)
#   CANDIDATE_DIR: one fault_effects_logic_<faultid>.cpp per candidate fault (what the tester would log if that fault were present)
#   Each failure = (pattern, pad, scan offset, value). For every candidate:
#     TFSF = failures in both logs, TFSP = tester fails but the candidate predicts pass,
#     TPSF = the candidate predicts a fail but the tester passes.   score = TFSF / (TFSF + TFSP + TPSF)
#   drop_fraction: randomly drop this share of the observed failures (a tester with a small fail memory logs only some)
import glob, os, random, re, sys

def load(path):
    fails = set()
    for line in open(path):
        m = re.match(r"Chip \S+ pad (\S+) pattern (\S+) offset (\d+) value (\d)", line)
        if m:
            fails.add((m.group(2), m.group(1), int(m.group(3)), m.group(4)))
    return fails

obs = load(sys.argv[1])
drop = float(sys.argv[3]) if len(sys.argv) > 3 else 0.0
random.seed(int(sys.argv[4]) if len(sys.argv) > 4 else 1)
truncated = drop > 0
if truncated:
    obs = set(random.sample(sorted(obs), int(round(len(obs) * (1 - drop)))))
rows = []
for f in glob.glob(os.path.join(sys.argv[2], "*.cpp")):
    fid = re.search(r"_(\d+)\.cpp$", f).group(1)
    sim = load(f)
    tfsf, tfsp, tpsf = len(obs & sim), len(obs - sim), len(sim - obs)
    rows.append((tfsf / (tfsf + tfsp + tpsf) if (tfsf + tfsp + tpsf) else 0, fid, tfsf, tfsp, tpsf))
rows.sort(reverse=True)
print(f"observed {len(obs)} failures ({'after dropping %d%%' % round(drop * 100) if truncated else 'complete log'}); {len(rows)} candidates")
print(f"{'rank':>4} {'fault id':>9} {'score':>6} {'TFSF':>5} {'TFSP':>5} {'TPSF':>5}")
for i, (sc, fid, a, b, c) in enumerate(rows[:5], 1):
    print(f"{i:>4} {fid:>9} {sc:6.3f} {a:>5} {b:>5} {c:>5}")
