#!/usr/bin/env python3
"""Join Innovus 'report_power -instances' (mW) with instance centres -> inst_pwr.txt (W).
usage: ir_inst.py <ir_dir>"""
import sys, re
d = sys.argv[1]
loc = {}
for ln in open(f"{d}/inst_loc.txt"):
    t = ln.split()
    if len(t) == 3: loc[t[0]] = (t[1], t[2])
toks = []; state = 0          # 0: before 'Instance' header, 1: in header, 2: data
for ln in open(f"{d}/inst_power.rpt"):
    if state == 0:
        if ln.startswith('Instance'): state = 1
        continue
    if state == 1:
        if ln.startswith('----'): state = 2
        continue
    toks.extend(ln.split())
# records: name n1 n2 n3 n4 n5 n6 n7 cell
out = open(f"{d}/inst_pwr.txt", 'w'); n = 0; tot = 0.0; i = 0
num = re.compile(r'^-?[0-9.]+(e[-+]?[0-9]+)?$')
while i + 8 < len(toks):
    name = toks[i]; vals = toks[i+1:i+8]
    if all(num.match(v) for v in vals) and name in loc:
        p = float(vals[5]) * 1e-3; x, y = loc[name]
        out.write(f"{name} {x} {y} {p:.6e}\n"); n += 1; tot += p; i += 9
    else:
        i += 1
out.close()
print(f"{n} instances, total {tot*1e3:.1f} mW")
