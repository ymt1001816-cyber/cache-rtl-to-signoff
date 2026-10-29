# make_lef_antenna.py : add process-antenna data to the OSU LEF (lec10 p26: antenna rule checking)
# FreePDK45 has no antenna rules ("Currently no antenna rule checks", FreePDK45 release notes), so the
# limits are borrowed from the open SkyWater SKY130 PDK (ar_q.met*.1 / ar_q.via*.1):
#   metal: sidewall area / gate area <= 400; with a diffusion connection 400 + 400 x diff area + 2200
#   via:   cut area / gate area <= 6;        with a diffusion connection 6 + 36 x diff area
# Metal thickness (sidewall = perimeter x thickness) from the FreePDK45 Nangate tech LEF.
# Gate area per input pin = sum of W x L of the transistors it drives (OSU cells.sp).
# Diffusion area per output pin = W x 0.09 um per connected drain (cells.sp has ad = 0; estimate).
# usage: python3 make_lef_antenna.py in.lef cells.sp out.lef
import re, sys
lef, sp, out = sys.argv[1:4]
THK = {'metal1': .13, 'metal2': .14, 'metal3': .14, 'metal4': .28, 'metal5': .28, 'metal6': .28,
       'metal7': .8, 'metal8': .8, 'metal9': 2, 'metal10': 2}
num = lambda v: float(v[:-1]) * {'u': 1, 'n': 1e-3}[v[-1]]
gate, diff, cell = {}, {}, None
for line in open(sp):
    t = line.split()
    if not t: continue
    if t[0].lower() == '.subckt': cell = t[1]; gate[cell] = {}; diff[cell] = {}; continue
    if cell and t[0][0] in 'Mm':
        d, g, s = t[1], t[2], t[3]
        w = num(re.search(r'w=(\S+)', line).group(1)); l = num(re.search(r'l=(\S+)', line).group(1))
        gate[cell][g] = gate[cell].get(g, 0) + w * l
        for n in (d, s): diff[cell][n] = diff[cell].get(n, 0) + w * 0.09
res, layer, macro, pin, dirn = [], None, None, None, None
for line in open(lef):
    m = re.match(r'(LAYER|MACRO|PIN)\s+(\S+)', line.strip())
    if m and line.startswith('LAYER'): layer = m.group(2)
    if m and m.group(1) == 'MACRO': macro = m.group(2)
    if m and m.group(1) == 'PIN' and macro: pin = m.group(2)
    if layer and line.startswith('END ' + layer):
        if layer in THK:
            res.append('  THICKNESS %g ;\n  ANTENNAMODEL OXIDE1 ;\n  ANTENNASIDEAREARATIO 400 ;\n'
                       '  ANTENNADIFFSIDEAREARATIO PWL ( ( 0 400 ) ( 0.0001 2600 ) ( 100 42600 ) ) ;\n' % THK[layer])
        elif layer.startswith('via'):
            res.append('  ANTENNAMODEL OXIDE1 ;\n  ANTENNAAREARATIO 6 ;\n'
                       '  ANTENNADIFFAREARATIO PWL ( ( 0 6 ) ( 100 3606 ) ) ;\n')
        layer = None
    if 'DIRECTION' in line and pin: dirn = line.split()[1]
    res.append(line)
    if macro and pin and line.strip() == 'USE SIGNAL ;':
        if dirn == 'INPUT' and gate.get(macro, {}).get(pin):
            res.append('    ANTENNAGATEAREA %.4f ;\n' % gate[macro][pin])
        if dirn == 'OUTPUT' and diff.get(macro, {}).get(pin):
            res.append('    ANTENNADIFFAREA %.4f ;\n' % diff[macro][pin])
    if pin and line.strip().startswith('END ' + pin): pin = None
open(out, 'w').writelines(res)
print('antenna LEF written:', out)
