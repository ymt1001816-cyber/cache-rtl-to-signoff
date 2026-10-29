# insert_scan.py : stitch every flip-flop of a mapped netlist into N mux-D scan chains (lec10 p22, lec11 p17)
# The OSU library has no scan flip-flop, so each scan cell = MUX2X1 (inverting) + INVX1 in front of the DFF:
#   D_ff = scan_en ? previous Q : functional D          (scan_en = 0 -> normal operation)
# usage: python3 insert_scan.py in.v out.v [N]
#   N = 1 (default): ports scan_in / scan_out
#   N > 1          : ports scan_in_0..N-1 / scan_out_0..N-1, flops split into N equal chains
import re, sys
src = open(sys.argv[1]).read()
N = int(sys.argv[3]) if len(sys.argv) > 3 else 1
FF = ('DFFPOSX1', 'DFFSR')                 # posedge flops (one clock domain)
pat = re.compile(r'(\b(?:%s)\s+)(\\\S+\s|\w+)(\s*\()(.*?)(\);)' % '|'.join(FF), re.S)
total = len(pat.findall(src))
si_name = ['scan_in'] if N == 1 else ['scan_in_%d' % c for c in range(N)]
so_name = ['scan_out'] if N == 1 else ['scan_out_%d' % c for c in range(N)]
chains, new, decl, n = [[] for _ in range(N)], [], [], [0]
NET = r'(\\\S+\s(?:\s*\[\d+\])?|[^()\s\\]+(?:\s*\[\d+\])?)'   # escaped name may be followed by " [N]"
def esc(net):                                   # an escaped name must end with a space before ')' or ','
    return net + ' ' if net.startswith('\\') else net
def pin(conn, p):
    m = re.search(r'\.%s\s*\(\s*%s\s*\)' % (p, NET), conn)
    return m.group(1).strip() if m else None
def rew(m):
    i = n[0]; n[0] += 1
    c = i * N // total                          # flop i goes to chain c (consecutive flops share a chain)
    chain = chains[c]
    conn = m.group(4); d = pin(conn, 'D'); q = pin(conn, 'Q')
    si = si_name[c] if not chain else chain[-1]
    if q is None:                                   # unconnected Q: give it a net so the chain can continue
        q = 'scan_q_%d' % i; conn = conn.rstrip() + (', ' if conn.strip() else '') + '.Q(%s)' % q; decl.append('  wire %s;\n' % q)
    chain.append(esc(q))
    new.append('  MUX2X1 scan_mux_%d (.S(scan_en), .A(%s), .B(%s), .Y(scan_n_%d));\n'
               '  INVX1 scan_inv_%d (.A(scan_n_%d), .Y(scan_d_%d));\n'
               % (i, si, esc(d), i, i, i, i))
    conn = re.sub(r'\.D\s*\(\s*%s\s*\)' % NET, '.D(scan_d_%d)' % i, conn, count=1)
    return m.group(1) + m.group(2) + m.group(3) + conn + m.group(5)
mod = re.search(r'module\s+cache_top\s*\((.*?)\);', src, re.S)
body = pat.sub(rew, src)
k = n[0]
wires = ''.join('  wire scan_n_%d, scan_d_%d;\n' % (i, i) for i in range(k)) + ''.join(decl)
ports = ', '.join(['scan_en'] + si_name + so_name)
body = body.replace(mod.group(0), 'module cache_top (%s, %s);\n  input %s;\n  output %s;\n'
                    % (mod.group(1).strip(), ports, ', '.join(['scan_en'] + si_name), ', '.join(so_name)) + wires, 1)
end = body.rfind('endmodule')
body = body[:end] + ''.join(new) + ''.join('  assign %s = %s;\n' % (so_name[c], chains[c][-1]) for c in range(N)) + body[end:]
open(sys.argv[2], 'w').write(body)
print('scan cells inserted:', k, ' chains:', N, ' lengths:', [len(ch) for ch in chains])
