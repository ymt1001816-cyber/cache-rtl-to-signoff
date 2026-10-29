# make_lef_pinfix.py <in.lef> <out.lef>
# OSU gscl45nm: LEF pins sit on the 2.5 nm manufacturing grid (x.xxx5 um), the GDS cells on a
# 1 nm grid with every x.xxx5 rounded UP. So a pin's LEFT and BOTTOM edges in the LEF are 0.5 nm
# outside the real GDS pin; a wire that just touches that edge is open in Calibre LVS.
# Fix: move only the left (x1) and bottom (y1) edges of PIN rectangles inward by one grid step
# (+0.0025 um). They stay on the 2.5 nm grid and fall inside the GDS pin; right/top edges are
# already inside, obstructions (OBS) are left as they are.
import re, sys
from decimal import Decimal
src, dst = sys.argv[1], sys.argv[2]
out, pin, n = [], None, 0
for line in open(src):
    t = line.split()
    if len(t) >= 2 and t[0] == 'PIN': pin = t[1]
    elif pin and len(t) >= 2 and t[0] == 'END' and t[1] == pin: pin = None
    elif pin and t and t[0] == 'RECT':
        v = t[1:5]
        for i in (0, 1):                                   # x1, y1
            if re.fullmatch(r'-?\d+\.\d{3}5', v[i]):
                v[i] = str(Decimal(v[i]) + Decimal('0.0025')); n += 1
        line = re.sub(r'RECT .*;', 'RECT %s %s %s %s ;' % tuple(v), line)
    out.append(line)
open(dst, 'w').write(''.join(out))
print("edges moved inward:", n)
