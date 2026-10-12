#!/usr/bin/env python3
"""
Chip-level scan vectors from a tile's ATPG patterns, for gate-level validation.

For each selected pattern of partition P:
  * scan load: P's own flops (PPI) and neighbour flops in its context (XPPI)
    take the ATPG values; every other flop in the chip gets a random value
  * chip inputs: ATPG values for P's PIs, random otherwise
  * expected capture: fault-free bench simulation of the PPOs / XPOs, mapped to
    (chain, position) of the capturing flop
  * optional fault injection: for sampled faults, the first pattern that
    detects the fault (bench fault simulation) and the flops that differ

usage: gen_vectors.py <partition> <bench_dir> <run_dir> <netlist.v> <scan_chains.txt> <out_dir> <npat> <nfault>
files written: <P>.load (pattern chain bits[pos0..]), <P>.pi (pattern bitvector),
               <P>.exp (pattern chain pos value), <P>.faults (fault inject list)
"""
import sys, re, random
sys.path.insert(0, sys.path[0])
from benchsim import Bench, read_patterns

P, BD, RD, NET, CHAINS, OUT, NPAT, NFLT = sys.argv[1:9]
NPAT, NFLT = int(NPAT), int(NFLT)
random.seed(577)
NODES = ['00','01','02','03','10','11','12','13','20','21','22','23','30','31','32','33']
L = 4144

# chain position of every flop: chain k = router -> nic -> cpu of node k
def vname(n): return re.sub(r'\[(\d+)\]', r'_\1_', n).replace('/', '_')
order = {'cardinal_router': [], 'cardinal_nic': [], 'cardinal_cpu': []}
for ln in open(CHAINS):
    b, i, f = ln.split(); order[b].append(vname(f))
pos = {}
for k, n in enumerate(NODES):
    seq = [f'mesh_node{n}/{f}' for f in order['cardinal_router']] + \
          [f'nic_{n}/{f}' for f in order['cardinal_nic']] + [f'cpu_{n}/{f}' for f in order['cardinal_cpu']]
    assert len(seq) == L
    for j, f in enumerate(seq): pos[f] = (k, j)

# chip input port order used by the testbench (must match tb_atpg.v)
pi_order = []
for n in NODES:
    pi_order += [f'imem_data_{n}[{i}]' for i in range(31, -1, -1)]
for n in NODES:
    pi_order += [f'dmem_data_out_{n}[{i}]' for i in range(63, -1, -1)]
pi_order += ['reset', 'test_se'] + [f'test_si_{k}_' for k in range(15, -1, -1)]
pi_index = {p: i for i, p in enumerate(pi_order)}

b = Bench(f'{BD}/{P}.bench')
pmap = [l.split() for l in open(f'{BD}/{P}.map')]     # node kind inst net
pomap = {}
for l in open(f'{BD}/{P}.pomap'):
    t = l.split(); pomap[t[0]] = (t[1], t[2] if len(t) > 2 else '')
pats = read_patterns(f'{RD}/{P}.test', len(b.inputs))
sel = list(range(min(NPAT // 2, len(pats)))) + random.sample(range(len(pats)), min(NPAT - NPAT // 2, len(pats)))
sel = sorted(set(sel))[:NPAT]

loads, pis = [], []
for pi_ in sel:
    p = pats[pi_]
    ld = [[random.randint(0, 1) for _ in range(L)] for _ in range(16)]
    pv = [random.randint(0, 1) for _ in pi_order]
    pv[pi_index['test_se']] = 0                 # capture in functional mode unless ATPG sets it
    for i, (node, kind, *rest) in enumerate(pmap):
        val = 1 if p[i] == '1' else 0
        if kind in ('PPI', 'XPPI'):
            inst = rest[0]
            k, j = pos[inst]; ld[k][j] = val
        elif kind == 'PI':
            net = rest[-1]
            if net in pi_index: pv[pi_index[net]] = val
        elif kind == 'CONSTSRC':
            pass
        else:
            sys.exit(f'unexpected input kind {kind}')
    loads.append(ld); pis.append(pv)

# bench inputs as seen by the chip (after random fill): rebuild from loads / pis
W = len(sel)
def words_from_chip():
    w = {}
    for i, (node, kind, *rest) in enumerate(pmap):
        bits = 0
        for t in range(W):
            if kind in ('PPI', 'XPPI'):
                k, j = pos[rest[0]]; v = loads[t][k][j]
            elif kind == 'PI':
                v = pis[t][pi_index[rest[-1]]] if rest[-1] in pi_index else 0
            else:
                v = 1          # constsrc: any value, constants are AND(x,!x)/OR(x,!x)
            bits |= v << t
        w[node] = bits
    return w
words = words_from_chip()
good = b.sim(words, W)

def observed(po):
    kind, what = pomap[po]
    if kind == 'PPO':
        return [pos[what]] if what in pos else []
    if kind == 'XPO' and not what.startswith(('CHIPOUT:', 'OTHER:')):
        return [pos[f] for f in what.split(';') if f in pos]
    return []

with open(f'{OUT}/{P}.load', 'w') as f:
    for t in range(W):
        for k in range(16): f.write(''.join(map(str, loads[t][k])) + '\n')   # line 16*t+k, char j = position j
with open(f'{OUT}/{P}.pi', 'w') as f:
    for t in range(W): f.write(''.join(map(str, pis[t])) + '\n')
nexp = 0
with open(f'{OUT}/{P}.exp', 'w') as f:
    for po in b.outputs:
        for (k, j) in observed(po):
            for t in range(W):
                f.write(f"{t} {k} {j} {(good[po] >> t) & 1}\n"); nexp += 1

# fault injection set: sampled faults, first detecting pattern, differing flops
names = dict(l.split(None, 1) for l in open(f'{BD}/{P}.faultnames'))
flist = [l.split() for l in open(f'{BD}/{P}.flt')]
random.shuffle(flist)
inj = []
fanout = {}
for g_, (fn_, args_) in b.gates.items():
    for a_ in args_: fanout[a_] = fanout.get(a_, 0) + 1
for node, sv in flist:
    if len(inj) >= NFLT: break
    # Xcelium force on a cell input port acts on the whole net (port collapsing):
    # inject input-pin faults only where the net has a single load
    if node.startswith('p') and node in b.gates and fanout.get(b.gates[node][1][0], 0) > 1: continue
    v = b.sim(words, W, fault=(node, int(sv[1])))
    diff = {}
    for po in b.outputs:
        d = v[po] ^ good[po]
        if d:
            for (k, j) in observed(po):
                for t in range(W):
                    if (d >> t) & 1: diff.setdefault(t, []).append((k, j, (v[po] >> t) & 1))
    if diff:
        t = min(diff); inj.append((node, sv[1], names[node].strip(), t, diff[t]))
with open(f'{OUT}/{P}.faults', 'w') as f:
    for node, sv, pin, t, d in inj:
        f.write(f"{pin} {sv} {t} " + ' '.join(f'{k}:{j}:{x}' for k, j, x in d[:8]) + '\n')
print(f"{P}: {W} patterns, {nexp} expected capture bits, {len(inj)} injectable faults")

# Verilog include for fault injection runs
with open(f'{OUT}/{P}_faults.vh', 'w') as f:
    f.write(f"`define NFLT {len(inj)}\n")
    f.write("function integer fpat(input integer i);\n  case (i)\n")
    for i, (node, sv, pin, t, d) in enumerate(inj): f.write(f"    {i}: fpat = {t};\n")
    f.write("    default: fpat = 0;\n  endcase\nendfunction\n")
    f.write("task inject(input integer i);\n  case (i)\n")
    for i, (node, sv, pin, t, d) in enumerate(inj):
        f.write(f"    {i}: force cmp.{pin.replace('/', '.')} = 1'b{sv};\n")
    f.write("  endcase\nendtask\ntask release_all(input integer i);\n  case (i)\n")
    for i, (node, sv, pin, t, d) in enumerate(inj):
        f.write(f"    {i}: release cmp.{pin.replace('/', '.')};\n")
    f.write("  endcase\nendtask\n")
