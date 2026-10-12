#!/usr/bin/env python3
"""parallel-load validation files: flop order = chain k (0..15) x position j (0..4143)
usage: gen_partb.py <scan_chains.txt> <val_dir> <P>"""
import sys, re
CH, V, P = sys.argv[1:4]
NODES = ['00','01','02','03','10','11','12','13','20','21','22','23','30','31','32','33']
def vname(n): return re.sub(r'\[(\d+)\]', r'_\1_', n).replace('/', '_')
order = {'cardinal_router': [], 'cardinal_nic': [], 'cardinal_cpu': []}
for ln in open(CH):
    b, i, f = ln.split(); order[b].append(vname(f))
flops = []
for n in NODES:
    flops += [f'mesh_node{n}.{f}' for f in order['cardinal_router']] + [f'nic_{n}.{f}' for f in order['cardinal_nic']] + \
             [f'cpu_{n}.{f}' for f in order['cardinal_cpu']]
N = len(flops)
with open(f'{V}/par_flops.vh', 'w') as f:
    f.write(f"`define NFF {N}\n")
    f.write("task load_all; begin\n" + ''.join(f"  force cmp.{x}.D = ldv[{N-1-i}];\n" for i, x in enumerate(flops)) + "end endtask\n")
    f.write("task unload_all; begin\n" + ''.join(f"  release cmp.{x}.D;\n" for x in flops) + "end endtask\n")
    f.write(''.join(f"assign capv[{N-1-i}] = cmp.{x}.Q;\n" for i, x in enumerate(flops)))
# per-pattern load lines: concatenate the 16 chain lines
lines = open(f'{V}/{P}.load').read().split()
with open(f'{V}/{P}.pload', 'w') as f:
    for t in range(len(lines) // 16): f.write(''.join(lines[16*t:16*t+16]) + '\n')
print(N, 'flops,', len(lines) // 16, 'patterns')
