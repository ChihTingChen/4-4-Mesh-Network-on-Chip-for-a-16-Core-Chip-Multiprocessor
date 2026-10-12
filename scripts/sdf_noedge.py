#!/usr/bin/env python3
"""Merge edge-qualified IOPATHs into plain ones so the gscl45nm.v models
(which only declare (A *> Y) / (CLK *> Q)) accept every SDF delay.
  (IOPATH (posedge A) Y r1 f1) + (IOPATH (negedge A) Y r2 f2)
     -> (IOPATH A Y max(r1,r2) max(f1,f2))      [conservative]
usage: sdf_noedge.py in.sdf out.sdf"""
import re, sys
pat = re.compile(r'^(\s*)\(IOPATH\s+\((?:posedge|negedge)\s+(\S+)\)\s+(\S+)\s+(\(.*?\))\s+(\(.*?\))\s*\)\s*$')
def tri(s): return [float(x) if x.strip() else None for x in s.strip('()').split(':')]
def mx(a, b):
    out = []
    for x, y in zip(tri(a), tri(b)):
        out.append('' if x is None and y is None else f'{max(v for v in (x, y) if v is not None):.3f}')
    return '(' + ':'.join(out) + ')'
fin, fout = open(sys.argv[1]), open(sys.argv[2], 'w')
pend = {}; order = []; ind = ''; n = 0
def flush():
    for k in order:
        r, f = pend[k]
        fout.write(f'{ind}(IOPATH {k[0]} {k[1]} {r} {f})\n')
    pend.clear(); order.clear()
for line in fin:
    m = pat.match(line)
    if m:
        ind, a, y, r, f = m.groups(); k = (a, y); n += 1
        if k in pend: pend[k] = (mx(pend[k][0], r), mx(pend[k][1], f))
        else: pend[k] = (r, f); order.append(k)
        continue
    if pend: flush()
    fout.write(line)
flush(); fout.close()
print(f"merged {n} edge-qualified IOPATH entries")
