#!/usr/bin/env python3
"""Bit-parallel logic simulator for ISCAS89 .bench (Python ints as pattern words).

    c = Bench('tile11.bench')
    vals = c.sim({pi: word, ...}, width)            # fault-free, returns {node: word}
    vals = c.sim(pi_words, width, fault=('p12', 0))  # node p12 stuck-at-0
Patterns: bit i of every word = pattern i.
"""
import re, sys

class Bench:
    def __init__(self, path):
        self.inputs, self.outputs, self.gates = [], [], {}
        for ln in open(path):
            ln = ln.strip()
            if not ln or ln.startswith('#'): continue
            m = re.match(r'INPUT\((\S+)\)', ln)
            if m: self.inputs.append(m.group(1)); continue
            m = re.match(r'OUTPUT\((\S+)\)', ln)
            if m: self.outputs.append(m.group(1)); continue
            m = re.match(r'(\S+)\s*=\s*(\w+)\((.*)\)', ln)
            out, fn, args = m.group(1), m.group(2).upper(), [a.strip() for a in m.group(3).split(',')]
            self.gates[out] = (fn, args)
        # levelize (iterative DFS topological order)
        order, state = [], {}
        for root in self.gates:
            if state.get(root): continue
            stack = [(root, 0)]
            while stack:
                n, i = stack.pop()
                if n not in self.gates: continue
                if i == 0:
                    if state.get(n) == 2: continue
                    state[n] = 1
                args = self.gates[n][1]
                if i < len(args):
                    stack.append((n, i + 1))
                    a = args[i]
                    if a in self.gates and state.get(a) != 2:
                        if state.get(a) == 1: raise RuntimeError(f'combinational loop at {a}')
                        stack.append((a, 0))
                else:
                    state[n] = 2; order.append(n)
        self.order = order

    def sim(self, pi_words, width, fault=None):
        mask = (1 << width) - 1
        v = dict(pi_words)
        fnode, fval = fault if fault else (None, None)
        if fnode is not None and fnode in v:
            v[fnode] = mask if fval else 0
        for n in self.order:
            fn, args = self.gates[n]
            a = [v[x] for x in args]
            if fn == 'AND':
                r = mask
                for x in a: r &= x
            elif fn == 'NAND':
                r = mask
                for x in a: r &= x
                r ^= mask
            elif fn == 'OR':
                r = 0
                for x in a: r |= x
            elif fn == 'NOR':
                r = 0
                for x in a: r |= x
                r ^= mask
            elif fn == 'XOR':
                r = a[0] ^ a[1]
            elif fn == 'NOT':
                r = a[0] ^ mask
            elif fn in ('BUFF', 'BUF'):
                r = a[0]
            else:
                raise ValueError(fn)
            if n == fnode: r = mask if fval else 0
            v[n] = r
        return v

def read_patterns(path, ninputs):
    """Atalanta .test file -> list of bit strings (one per pattern)"""
    pats = []
    for ln in open(path):
        m = re.match(r'\s*\d+:\s*([01xX]+)', ln)
        if m: pats.append(m.group(1)[:ninputs])
    return pats
