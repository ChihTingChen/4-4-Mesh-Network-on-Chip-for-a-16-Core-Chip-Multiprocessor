#!/usr/bin/env python3
"""Chip-level stuck-at coverage from per-partition Atalanta runs.
usage: aggregate.py <bench_dir> <run_dir>
Fault classes (commercial-ATPG style):
  DT  detected by ATPG patterns
  DI  detected implicitly by the scan-chain flush test (clock-tree cell pins, DFF CLK pins)
  UD  undetectable: proven redundant by ATPG (tied / blocked / redundant logic)
  AU  ATPG untestable within effort: aborted
fault coverage = (DT+DI) / all ; test coverage = (DT+DI) / (all - UD)
"""
import sys, re, glob, os, collections
BD, RD = sys.argv[1], sys.argv[2]
tot = collections.Counter()
rows = []
und_kind = collections.Counter()
und_list = []
for out in sorted(glob.glob(f'{RD}/*.out')):
    P = os.path.basename(out)[:-4]
    s = open(out).read()
    if 'Fault coverage' not in s: rows.append((P, 'running')); continue
    nf = int(re.search(r'Number of collapsed faults\s*:\s*(\d+)', s).group(1))
    red = int(re.search(r'identified redundant faults\s*:\s*(\d+)', s).group(1))
    ab = int(re.search(r'aborted faults\s*:\s*(\d+)', s).group(1))
    pats = int(re.search(r'after compaction\s*:\s*(\d+)', s).group(1)) if 'after compaction' in s else \
           int(re.search(r'Number of test patterns\s*:\s*(\d+)', s).group(1))
    dt = nf - red - ab
    tot['faults'] += nf; tot['UD'] += red; tot['AU'] += ab; tot['DT'] += dt; tot['patterns_sum'] += pats
    tot['patterns_max'] = max(tot['patterns_max'], pats)
    rows.append((P, nf, dt, red, ab, pats, 100 * dt / nf))
    names = {}
    fn = f'{BD}/{P}.faultnames'
    for l in open(fn):
        a, b = l.split(None, 1); names[a] = b.strip()
    uf = f'{RD}/{P}.ufaults'
    if os.path.exists(uf):
        for l in open(uf):
            t = l.split()
            if not t: continue
            node = t[0].split('->')[-1]
            pin = names.get(node, node)
            cell = pin.rsplit('/', 1)
            und_list.append((P, pin, t[-1]))
            blk = 'router' if 'mesh_node' in pin else 'nic' if pin.startswith('nic_') else 'cpu' if pin.startswith('cpu_') else 'top'
            und_kind[(blk, cell[-1])] += 1
summ = open(f'{BD}/summary.txt').read()
clock_pin = int(re.search(r'clock_cell_pin_faults (\d+)', summ).group(1))
dff_clk = sum(int(l.split()[5]) for l in summ.splitlines() if re.match(r'(tile\d\d|top) ', l))
DI = clock_pin + dff_clk
ALL = tot['faults'] + DI
det = tot['DT'] + DI
print(f"{'partition':10s} {'faults':>8s} {'DT':>8s} {'UD':>6s} {'AU':>5s} {'patterns':>8s} {'FC%':>8s}")
for r in rows:
    if r[1] == 'running': print(f"{r[0]:10s} running"); continue
    print(f"{r[0]:10s} {r[1]:8d} {r[2]:8d} {r[3]:6d} {r[4]:5d} {r[5]:8d} {r[6]:8.3f}")
print(f"\nDI (clock-tree + DFF CLK pins, flush test): {DI}")
print(f"total pin faults {ALL}, detected {det}, UD {tot['UD']}, AU {tot['AU']}")
print(f"FAULT COVERAGE = {100*det/ALL:.3f} %   TEST COVERAGE = {100*det/(ALL-tot['UD']):.3f} %")
print(f"patterns: sum over partitions {tot['patterns_sum']}, max {tot['patterns_max']}")
print("\nundetected faults by block / pin:")
for (blk, pin), c in sorted(und_kind.items(), key=lambda x: -x[1])[:25]:
    print(f"  {blk:6s} pin {pin:5s} {c}")
with open(f'{RD}/undetected.txt', 'w') as f:
    for P, pin, cls in und_list: f.write(f"{P} {pin} {cls}\n")
