#!/usr/bin/env python3
"""compare captured chain contents with bench-predicted values / injected-fault effects"""
import sys, collections
mode, exp, cap = sys.argv[1], sys.argv[2], sys.argv[3]
C = {}
L = 4144
for l in open(cap):
    f = l.split()
    if len(f) == 3:                       # parallel-load format: CAP t <all flops>
        t, bits = int(f[1]), f[2]
        for k in range(16): C[(t, k)] = bits[k*L:(k+1)*L]
    else:
        _, t, k, bits = f; C[(int(t), int(k))] = bits
if mode == 'good':
    n = bad = 0; ex = []
    for l in open(exp):
        t, k, j, v = map(int, l.split()); n += 1
        got = C[(t, k)][j]
        if got != str(v):
            bad += 1
            if len(ex) < 10: ex.append((t, k, j, v, got))
    print(f"compared {n} captured bits: {n-bad} match, {bad} mismatch {ex}")
else:   # fault injection: each entry must show the predicted faulty value at its flops
    good = {}
    for l in open(sys.argv[4]):            # exp file of fault-free values
        t, k, j, v = map(int, l.split()); good[(t, k, j)] = v
    ok = tot = 0; fails = []
    for i, l in enumerate(open(exp)):      # faults file
        f = l.split(); pin, sv, t = f[0], f[1], int(f[2])
        hits = []
        for e in f[3:]:
            k, j, x = map(int, e.split(':'))
            hits.append(C[(i, k)][j] == str(x))
        tot += 1
        if hits and all(hits): ok += 1
        else: fails.append(pin + '/' + sv)
    print(f"injected {tot} faults: {ok} detected exactly as predicted; failures {fails[:10]}")
