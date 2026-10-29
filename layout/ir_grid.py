# ir_grid.py : static IR drop of one supply net as a 2-D resistor grid (lec10 p26)
# Innovus rail analysis needs a QRC tech file that FreePDK45 lacks, so the vdd net is modeled by hand:
#   - one metal1 rail per two rows (rows are flipped), cut into dx-long resistors
#   - optional vertical metal6 stripes, joining every rail at their x position
#   - the power ring is an ideal source: rails end on the left / right ring, stripes on the top / bottom ring
#   - every node draws the same current (total = P / VDD)
# usage: python3 ir_grid.py <power_mW> <stripe_pitch_um or 0> <stripe_width_um>
import sys
P_mW, pitch, sw = float(sys.argv[1]), float(sys.argv[2]), float(sys.argv[3])
VDD, W, H, row = 1.1, 525.16, 521.17, 2.47
rsq1, rail_w, rsq6 = 0.38, 0.13, 0.25          # gscl45nm.lef
NR = int(H / row / 2)                           # vdd rails
dx = 2.5; NX = int(W / dx)                      # nodes per rail (ring at x = 0 and x = W)
I_node = P_mW / VDD / (NR * (NX - 1))           # mA per node
Rx = rsq1 * dx / rail_w                         # ohm, rail segment
cols = []
if pitch > 0:
    x = 50.0
    while x < W: cols.append(int(round(x / dx))); x += pitch
Ry = rsq6 * (H / NR) / sw if cols else None     # ohm, stripe segment between rails
v = [[0.0] * (NX + 1) for _ in range(NR)]       # drop in mV (mA * ohm)
for it in range(20000):
    err = 0.0
    for r in range(NR):
        vr = v[r]
        for i in range(1, NX):
            g = 2 / Rx; s = (vr[i - 1] + vr[i + 1]) / Rx + I_node
            if i in cols:                       # stripe: up and down neighbors (ring beyond the ends)
                up = v[r + 1][i] if r + 1 < NR else 0.0
                dn = v[r - 1][i] if r > 0 else 0.0
                g += 2 / Ry; s += (up + dn) / Ry
            new = vr[i] + 1.9 * (s / g - vr[i])     # SOR
            err = max(err, abs(new - vr[i])); vr[i] = new
    if err < 1e-4: break
worst = max(max(r) for r in v)
print(f"P={P_mW} mW  stripes={len(cols)} (pitch {pitch} um, width {sw} um)  worst drop = {worst:.1f} mV "
      f"({worst / VDD / 10:.1f}% of VDD)  [{it} iterations]")
# EM: highest DC current density, rail ends and stripe ends (ITRS-based limit 1.8 MA/cm2 for Cu at 105 C)
t1, t6 = 0.13, 0.28                              # um, metal thickness (FreePDK45 / Nangate tech LEF)
j_rail = max(max(abs(r[1] - r[0]), abs(r[NX - 1] - r[NX])) for r in v) / Rx / (rail_w * t1) * 1e-3 * 1e8 / 1e6
print(f"EM: rail-end J = {j_rail:.2f} MA/cm2", end='')
if cols:
    j_str = max(max(v[0][c], v[NR - 1][c]) for c in cols) / Ry / (sw * t6) * 1e-3 * 1e8 / 1e6
    print(f", stripe-end J = {j_str:.2f} MA/cm2", end='')
print("  (limit 1.8 MA/cm2)")
