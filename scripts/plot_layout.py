#!/usr/bin/env python3
"""usage: plot_layout.py <pnr_run_dir> <outdir>  (uses ir/inst_loc.txt, ir/pg_wires.txt, out/pg_bumps.txt)"""
import sys, re, collections
import matplotlib; matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle
d, o = sys.argv[1], sys.argv[2]
pts = collections.defaultdict(lambda: ([], []))
for ln in open(f"{d}/ir/inst_loc.txt"):
    n, x, y = ln.split()
    if n.startswith('FILL'): continue
    m = re.match(r'(?:cpu|nic)_(\d\d)/|mesh_node(\d\d)/', n)
    k = (m.group(1) or m.group(2)) if m else 'top'
    blk = 'cpu' if n.startswith('cpu') else 'nic' if n.startswith('nic') else 'router' if n.startswith('mesh') else 'top'
    pts[(k, blk)][0].append(float(x)); pts[(k, blk)][1].append(float(y))
cmap = plt.get_cmap('tab20')
nodes = sorted({k for k, _ in pts if k != 'top'})
fig, ax = plt.subplots(figsize=(8, 8))
for i, k in enumerate(nodes):
    for blk, a in (('cpu', 0.35), ('router', 0.9), ('nic', 0.9)):
        if (k, blk) in pts:
            xs, ys = pts[(k, blk)]
            ax.scatter(xs, ys, s=0.05 if blk == 'cpu' else 0.15, color=cmap(i % 20), alpha=a, linewidths=0, rasterized=True)
    xs, ys = pts[(k, 'cpu')]
    ax.text(sum(xs)/len(xs), sum(ys)/len(ys), f"node {k}", ha='center', va='center', fontsize=9, weight='bold')
if ('top', 'top') in pts:
    ax.scatter(*pts[('top', 'top')], s=0.3, color='k', linewidths=0, label='top-level glue', rasterized=True)
ax.set_aspect('equal'); ax.set_xlabel('x (um)'); ax.set_ylabel('y (um)')
ax.set_title('Placement by tile (router + NIC + CPU of each mesh node)')
plt.tight_layout(); plt.savefig(f"{o}/layout_tiles.png", dpi=150); plt.close()

fig, ax = plt.subplots(figsize=(8, 8))
col = {'metal10': '#c0392b', 'metal9': '#2e86c1', 'metal6': '#7d8a2e'}
for ln in open(f"{d}/ir/pg_wires.txt"):
    net, shape, layer, x1, y1, x2, y2, w = ln.split()
    if layer not in col and shape != 'ring': continue
    x1, y1, x2, y2 = map(float, (x1, y1, x2, y2))
    c = '#555' if shape == 'ring' else col[layer]
    ax.add_patch(Rectangle((x1, y1), x2 - x1, y2 - y1, color=c, alpha=0.45 if net == 'vdd' else 0.25, lw=0))
for ln in open(f"{d}/out/pg_bumps.txt"):
    net, x, y = ln.split()
    ax.plot(float(x), float(y), 'o', ms=6, mfc='#f1c40f' if net == 'vdd' else '#222', mec='k', mew=0.6)
ax.autoscale(); ax.set_aspect('equal'); ax.set_xlabel('x (um)'); ax.set_ylabel('y (um)')
ax.set_title('PDN: M9/M10 ring, 14 um M10 (V) / M9 (H) straps @40 um,\n1.2 um M6 straps @20 um; yellow = vdd bump, black = gnd bump')
plt.tight_layout(); plt.savefig(f"{o}/layout_pdn.png", dpi=150); plt.close()
print("ok")
