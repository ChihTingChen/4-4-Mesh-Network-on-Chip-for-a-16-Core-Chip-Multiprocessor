#!/usr/bin/env python3
"""
Static IR-drop solver for the Cardinal CMP power grid.

Voltus is not licensed here, so the grid is solved directly:
  * every PG special wire (M1 follow-pin rails, M6/M9/M10 stripes, M9/M10 ring)
    becomes a chain of resistors between the via locations that touch it
    (R = Rsheet * length / width, Rsheet from the LEF);
  * every PG via is a resistor between its two layers at (x, y)
    (R = LEF contact resistance / estimated cut count);
  * every standard cell draws I = P_cell / VDD from the vdd rail of its row
    (and returns it into the gnd rail), split between the two nearest rail
    nodes; P_cell comes from Innovus report_power;
  * the core ring is the supply (ideal pads on the ring).
G * V = I is solved with scipy for vdd and gnd separately.

usage: ir_solve.py <ir_dir> <vdd> [title] [bumps.txt]
  <ir_dir>/pg_wires.txt  net shape layer x1 y1 x2 y2 width
  <ir_dir>/pg_vias.txt   net name x y botLayer topLayer
  <ir_dir>/inst_pwr.txt  inst x y power_W
outputs <ir_dir>/ir_report.txt, ir_map_vdd.png, ir_map_gnd.png
"""
import sys, collections, math
import numpy as np
import scipy.sparse as sp
import scipy.sparse.linalg as spla

d = sys.argv[1]; VDD = float(sys.argv[2]); title = sys.argv[3] if len(sys.argv) > 3 else ""
RS = {'metal1': .38, 'metal2': .25, 'metal3': .25, 'metal4': .25, 'metal5': .25, 'metal6': .25,
      'metal7': .25, 'metal8': .25, 'metal9': .21, 'metal10': .21}
# LEF contactResistance per cut (ohm) of the via whose BOTTOM layer is key
RVIA = {'metal1': 5.69, 'metal2': 11.39, 'metal3': 16.73, 'metal4': 21.44, 'metal5': 24.08,
        'metal6': 11.39, 'metal7': 5.69, 'metal8': 16.73, 'metal9': 21.44}
NCUT = 4          # conservative cut count per generated via (viaGen arrays are >= 2x2)
Q = 0.005         # snapping grid (um)

def snap(v): return round(float(v) / Q) * Q
# optional area-array bumps (net x y per line) as additional ideal supplies
import os
BUMPS = None
if len(sys.argv) > 4 and os.path.exists(sys.argv[4]):
    BUMPS = collections.defaultdict(list)
    for ln in open(sys.argv[4]):
        t = ln.split()
        if len(t) == 3: BUMPS[t[0]].append((float(t[1]), float(t[2])))

wires = collections.defaultdict(list)   # net -> [(shape, layer, x1,y1,x2,y2,w)]
for ln in open(f"{d}/pg_wires.txt"):
    t = ln.split()
    if len(t) < 8: continue
    wires[t[0]].append((t[1], t[2], *map(float, t[3:8])))
vias = collections.defaultdict(list)
for ln in open(f"{d}/pg_vias.txt"):
    t = ln.split()
    if len(t) < 6: continue
    ncut = int(t[6]) if len(t) > 6 and t[6].isdigit() and int(t[6]) > 0 else NCUT
    vias[t[0]].append((snap(t[2]), snap(t[3]), t[4], t[5], ncut))
insts = []
import os
if os.path.exists(f"{d}/inst_pwr.txt"):
    for ln in open(f"{d}/inst_pwr.txt"):
        t = ln.split()
        if len(t) == 4:
            insts.append((float(t[1]), float(t[2]), float(t[3])))
else:
    # floorplan-stage check: uniform load of P_UNIFORM watts over the core rows
    PU = float(os.environ.get('P_UNIFORM', '1.25'))
    rails_y = sorted({(w[3] + w[5]) / 2 for w in [x for x in [] ]})
    ys = sorted({round((float(l.split()[4]) + float(l.split()[6])) / 2, 3) for l in open(f"{d}/pg_wires.txt")
                 if l.split()[1] == 'followpin' and l.split()[0] == 'vdd'})
    xs0 = [float(l.split()[3]) for l in open(f"{d}/pg_wires.txt") if l.split()[1] == 'followpin']
    xs1 = [float(l.split()[5]) for l in open(f"{d}/pg_wires.txt") if l.split()[1] == 'followpin']
    x0, x1 = min(xs0), max(xs1)
    pts = [(x, y) for y in ys for x in np.arange(x0 + 2.5, x1, 5.0)]
    insts = [(x, y, PU / len(pts)) for x, y in pts]
P_total = sum(p for _, _, p in insts)

report = [f"Static IR drop analysis {title}", f"VDD = {VDD} V, total power = {P_total*1e3:.2f} mW, "
          f"total current = {P_total/VDD*1e3:.2f} mA, {len(insts)} instances", ""]

def solve(net):
    W = wires[net]; V = vias[net]
    node = {}
    def nid(key):
        if key not in node: node[key] = len(node)
        return node[key]
    rows, cols, vals = [], [], []
    def res(a, b, r):
        g = 1.0 / max(r, 1e-6)
        rows.extend([a, b, a, b]); cols.extend([a, b, b, a]); vals.extend([g, g, -g, -g])

    # via points per layer
    pts = collections.defaultdict(list)
    for x, y, bl, tl, nc in V:
        pts[bl].append((x, y)); pts[tl].append((x, y))
        res(nid((bl, x, y)), nid((tl, x, y)), RVIA.get(bl, 10.0) / nc)

    supply = set()
    rails = []      # (y, x1, x2, sorted [(x, node)]) of metal1 rails
    for shape, layer, x1, y1, x2, y2, w in W:
        horiz = (x2 - x1) >= (y2 - y1)
        lo, hi = (x1, x2) if horiz else (y1, y2)
        c = (y1 + y2) / 2 if horiz else (x1 + x2) / 2
        # build nodes using the exact via coordinates
        nodes_here = []
        for x, y in pts.get(layer, ()):
            if x1 - 1e-3 <= x <= x2 + 1e-3 and y1 - 1e-3 <= y <= y2 + 1e-3:
                nodes_here.append(((x if horiz else y), nid((layer, x, y))))
        nodes_here = sorted(set(nodes_here))
        for (a, na), (b, nb) in zip(nodes_here, nodes_here[1:]):
            if na != nb:
                res(na, nb, RS.get(layer, .25) * max(b - a, 1e-3) / w)
        if shape == 'ring':
            supply.update(n for _, n in nodes_here)
        if BUMPS and layer == 'metal10':
            for bx, by in BUMPS.get(net, ()):
                if x1 - 1e-3 <= bx <= x2 + 1e-3 and y1 - 1e-3 <= by <= y2 + 1e-3 and nodes_here:
                    a = by if not horiz else bx
                    supply.add(min(nodes_here, key=lambda t: abs(t[0] - a))[1])
        if layer == 'metal1' and shape == 'followpin':
            rails.append((c, lo, hi, nodes_here))

    n = len(node)
    G = sp.csr_matrix((vals, (rows, cols)), shape=(n, n))
    I = np.zeros(n)
    rails.sort()
    ry = np.array([r[0] for r in rails])
    for x, y, p in insts:
        k = int(np.argmin(np.abs(ry - y)))         # rail of the cell's row (this net)
        _, lo, hi, nh = rails[k]
        if not nh: continue
        xs = np.array([a for a, _ in nh])
        j = int(np.searchsorted(xs, x))
        cur = p / VDD
        if j <= 0: I[nh[0][1]] += cur
        elif j >= len(nh): I[nh[-1][1]] += cur
        else:
            a, b = xs[j - 1], xs[j]; f = (x - a) / max(b - a, 1e-9)
            I[nh[j - 1][1]] += cur * (1 - f); I[nh[j][1]] += cur * f
    # keep only the part of the grid connected to the ring; dangling via pads
    # (stacks dropped by viaGen) would make G singular
    from scipy.sparse.csgraph import connected_components
    ncomp, lab = connected_components(G, directed=False)
    good_lab = set(lab[list(supply)])
    conn = np.array([lab[i] in good_lab for i in range(n)])
    lost_current = I[~conn].sum()
    free = np.array([i for i in range(n) if conn[i] and i not in supply])
    Gff = G[free][:, free].tocsc()
    drop = np.full(n, np.nan)
    drop[list(supply)] = 0.0
    drop[free] = spla.spsolve(Gff, I[free])
    bad = ~np.isfinite(drop)
    report.append(f"[{net}] grid nodes not connected to the ring: {int((~conn).sum())} "
                  f"(carrying {lost_current*1e3:.3f} mA of load current)")
    inv = {v: k for k, v in node.items()}
    per = collections.defaultdict(float)
    for i in range(n):
        if np.isfinite(drop[i]): per[inv[i][0]] = max(per[inv[i][0]], drop[i])
    report.append(f"[{net}] worst drop per layer (mV): " +
                  ", ".join(f"{k}={v*1e3:.1f}" for k, v in sorted(per.items(), key=lambda kv: int(kv[0][5:]))))
    m1 = [(inv[i][1], inv[i][2], drop[i]) for i in range(n)
          if inv[i][0] == 'metal1' and np.isfinite(drop[i]) and drop[i] <= VDD]
    return drop, bad, m1, len(supply), n

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
for net in ('vdd', 'gnd'):
    if net not in wires: continue
    drop, bad, m1, ns, n = solve(net)
    good = drop[~bad]
    worst = good.max() if good.size else float('nan')
    report.append(f"[{net}] nodes={n} supply(ring) nodes={ns} isolated/floating nodes={int(bad.sum())}")
    report.append(f"[{net}] worst static drop = {worst*1e3:.2f} mV ({worst/VDD*100:.2f}% of VDD), "
                  f"mean on M1 rails = {np.mean([v for _,_,v in m1])*1e3:.2f} mV")
    if m1:
        xs, ys, vs = zip(*m1)
        plt.figure(figsize=(7, 6))
        sc = plt.scatter(xs, ys, c=np.array(vs) * 1e3, s=2, cmap='inferno', marker='s')
        plt.colorbar(sc, label=f'{"IR drop" if net=="vdd" else "ground bounce"} (mV)')
        plt.gca().set_aspect('equal'); plt.xlabel('x (um)'); plt.ylabel('y (um)')
        plt.title(f'Static {net} drop on M1 rails {title}\nworst {worst*1e3:.1f} mV ({worst/VDD*100:.2f}% VDD)')
        tag = '_bumps' if BUMPS else '_ring'
        plt.tight_layout(); plt.savefig(f"{d}/ir_map_{net}{tag}.png", dpi=130); plt.close()
open(f"{d}/ir_report{'_bumps' if BUMPS else '_ring'}.txt", 'w').write("\n".join(report) + "\n")
print("\n".join(report))
