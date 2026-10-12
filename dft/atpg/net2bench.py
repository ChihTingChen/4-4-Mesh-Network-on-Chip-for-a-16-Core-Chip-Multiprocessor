#!/usr/bin/env python3
"""
Full-scan ATPG model builder: gate-level Verilog (gscl45nm) -> ISCAS89 .bench
partitions + cell-pin stuck-at fault lists for Atalanta.

Model (standard full-scan combinational ATPG):
  * every DFFPOSX1 is cut: Q net = pseudo primary input (PPI),
    D pin = pseudo primary output (PPO)
  * chip input ports = PI, chip output ports = PO
  * the clock network (clk and the CTS buffers it drives, DFF CLK pins) is not
    part of the combinational model; its faults are reported separately as
    "detected implicitly by the scan-chain (flush) test" (DI)
  * fault universe = stuck-at-0/1 on every input and output pin of every
    non-clock cell (uncollapsed pin faults, as commercial ATPG reports them)
  * each cell input pin is a BUFF node, so a pin fault is a fault on that node;
    a cell output pin fault is the fault on the net stem it drives
  * the design is partitioned per mesh tile (router + NIC + CPU) plus the
    top-level buffers; a net crossing a partition boundary is a PI of the
    loading partition and a PO of the driving partition

usage: net2bench.py <netlist.v> <top> <outdir>
outputs per partition P: P.bench, P.flt (fault list), P.map (PI order -> names)
"""
import re, sys, os, collections

net_file, TOP, OUT = sys.argv[1], sys.argv[2], sys.argv[3]
os.makedirs(OUT, exist_ok=True)

CELLS = {  # cell: (inputs, {output: function-tag})
 'AND2X1': (['A','B'], {'Y':'AND'}), 'AND2X2': (['A','B'], {'Y':'AND'}),
 'OR2X1': (['A','B'], {'Y':'OR'}),   'OR2X2': (['A','B'], {'Y':'OR'}),
 'NAND2X1': (['A','B'], {'Y':'NAND'}), 'NAND3X1': (['A','B','C'], {'Y':'NAND'}),
 'NOR2X1': (['A','B'], {'Y':'NOR'}),   'NOR3X1': (['A','B','C'], {'Y':'NOR'}),
 'XOR2X1': (['A','B'], {'Y':'XOR'}),   'XNOR2X1': (['A','B'], {'Y':'XNOR'}),
 'INVX1': (['A'], {'Y':'NOT'}), 'INVX2': (['A'], {'Y':'NOT'}), 'INVX4': (['A'], {'Y':'NOT'}), 'INVX8': (['A'], {'Y':'NOT'}),
 'BUFX2': (['A'], {'Y':'BUFF'}), 'BUFX4': (['A'], {'Y':'BUFF'}),
 'CLKBUF1': (['A'], {'Y':'BUFF'}), 'CLKBUF2': (['A'], {'Y':'BUFF'}), 'CLKBUF3': (['A'], {'Y':'BUFF'}),
 'AOI21X1': (['A','B','C'], {'Y':'AOI21'}), 'AOI22X1': (['A','B','C','D'], {'Y':'AOI22'}),
 'OAI21X1': (['A','B','C'], {'Y':'OAI21'}), 'OAI22X1': (['A','B','C','D'], {'Y':'OAI22'}),
 'MUX2X1': (['A','B','S'], {'Y':'MUXN'}),
 'HAX1': (['A','B'], {'YS':'XOR', 'YC':'AND'}),
 'FAX1': (['A','B','C'], {'YS':'XOR3', 'YC':'MAJ'}),
 'DFFPOSX1': (['D','CLK'], {'Q':'DFF'}),
}

# ---------------------------------------------------------------- parse
src = open(net_file).read()
src = re.sub(r'//.*', '', src)
modules = {}
for m in re.finditer(r'\bmodule\s+(\S+)\s*\((.*?)\);(.*?)\bendmodule', src, re.S):
    modules[m.group(1)] = m.group(3)

def widths(body):
    w = {}
    for kind, rng, names in re.findall(r'\b(input|output|wire)\s*(\[\s*\d+\s*:\s*\d+\s*\])?\s*([^;]*);', body):
        for n in names.split(','):
            n = n.strip()
            if not n: continue
            if rng:
                hi, lo = map(int, re.findall(r'\d+', rng))
                w[n] = (kind, hi, lo)
            else:
                w[n] = (kind, None, None)
    return w

def bits(expr, w):
    """expand a connection expression into a list of bit-names (MSB first)"""
    expr = expr.strip()
    if not expr: return []
    if expr.startswith('{'):
        out = []
        for part in split_top(expr[1:-1]): out += bits(part, w)
        return out
    m = re.fullmatch(r"(\d+)'b([01xz]+)", expr)
    if m: return ["1'b" + c for c in m.group(2)]
    m = re.fullmatch(r'(\\?\S+?)\s*\[\s*(\d+)\s*:\s*(\d+)\s*\]', expr)
    if m:
        n, hi, lo = m.group(1), int(m.group(2)), int(m.group(3))
        step = -1 if hi >= lo else 1
        return [f'{n}[{i}]' for i in range(hi, lo + step, step)]
    m = re.fullmatch(r'(\\?\S+?)\s*\[\s*(\d+)\s*\]', expr)
    if m: return [f'{m.group(1)}[{m.group(2)}]']
    if expr in w and w[expr][1] is not None:
        _, hi, lo = w[expr]
        step = -1 if hi >= lo else 1
        return [f'{expr}[{i}]' for i in range(hi, lo + step, step)]
    return [expr]

def split_top(s):
    parts, depth, cur = [], 0, ''
    for ch in s:
        if ch == '{': depth += 1
        if ch == '}': depth -= 1
        if ch == ',' and depth == 0: parts.append(cur); cur = ''
        else: cur += ch
    if cur.strip(): parts.append(cur)
    return parts

parsed = {}
inst_re = re.compile(r'\b([A-Za-z_][\w]*)\s+(\\\S+|[A-Za-z_][\w]*)\s*\((.*?)\)\s*;', re.S)
for mname, body in modules.items():
    w = widths(body)
    insts = []
    for im in inst_re.finditer(body):
        ref, iname, conns = im.group(1), im.group(2), im.group(3)
        if ref in ('module', 'input', 'output', 'wire', 'assign'): continue
        pins = {}
        for pm in re.finditer(r'\.(\w+)\s*\(((?:[^()]|\([^()]*\))*)\)', conns):
            pins[pm.group(1)] = pm.group(2)
        insts.append((ref, iname, pins))
    assigns = re.findall(r'\bassign\s+(.*?)\s*=\s*(.*?)\s*;', body)
    parsed[mname] = (w, insts, assigns)

# ---------------------------------------------------------------- flatten
parent = {}
def find(x):
    while parent.get(x, x) != x:
        parent[x] = parent.get(parent[x], parent[x]); x = parent[x]
    return x
def union(a, b):
    ra, rb = find(a), find(b)
    if ra != rb: parent[ra] = rb

cells = []   # (path, ref, {pin: global_net_bit})
def flatten(mname, prefix, portmap):
    w, insts, assigns = parsed[mname]
    def g(b):
        if b.startswith("1'b"): return b
        return portmap.get(b, prefix + b)
    for lhs, rhs in assigns:
        for a, b in zip(bits(lhs, w), bits(rhs, w)): union(g(a), g(b))
    for ref, iname, pins in insts:
        path = prefix + iname.lstrip('\\')
        if ref in CELLS:
            conn = {}
            for p, e in pins.items():
                bl = bits(e, w)
                conn[p] = g(bl[0]) if bl else None
            cells.append((path, ref, conn))
        elif ref in parsed:
            sw = parsed[ref][0]
            pm = {}
            for p, e in pins.items():
                for a, b in zip(bits(p, sw), bits(e, w)):
                    pm[a] = g(b)
            flatten(ref, path + '/', pm)
        else:
            sys.exit(f"unknown cell/module {ref}")
flatten(TOP, '', {})
top_w = parsed[TOP][0]
chip_in, chip_out = set(), set()
for n, (kind, hi, lo) in top_w.items():
    if kind in ('input', 'output'):
        for b in bits(n, top_w):
            (chip_in if kind == 'input' else chip_out).add(find(b))
print(f"{len(cells)} leaf cells, {len(chip_in)} chip input bits, {len(chip_out)} chip output bits")

# ---------------------------------------------------------------- connectivity
driver, loads = {}, collections.defaultdict(list)
for ci, (path, ref, conn) in enumerate(cells):
    ins, outs = CELLS[ref]
    for p, n in conn.items():
        if n is None: continue
        n = find(n) if not n.startswith("1'b") else n
        conn[p] = n
        if p in outs: driver[n] = (ci, p)
        else: loads[n].append((ci, p))

# clock network: clk port and everything reachable through buffers/inverters
clk = find('clk')
clock_nets, clock_cells = {clk}, set()
frontier = [clk]
while frontier:
    n = frontier.pop()
    for ci, p in loads[n]:
        path, ref, conn = cells[ci]
        if ref.startswith(('BUF', 'INV', 'CLKBUF')) and p == 'A':
            clock_cells.add(ci)
            o = conn['Y']
            if o not in clock_nets: clock_nets.add(o); frontier.append(o)

CONTEXT = os.environ.get('CONTEXT', '1') == '1'

def comb_inputs(ci):
    ref = cells[ci][1]
    return [cells[ci][2].get(p) for p in CELLS[ref][0] if not (ref == 'DFFPOSX1')]

def compute_context(member_set):
    """cells outside the partition that are needed so that every boundary net
    is modelled exactly: the combinational fan-in of nets entering the
    partition (back to scan flops / chip inputs) and the combinational
    fan-out of nets leaving it (forward to scan flops / chip outputs), plus
    the fan-in of every side input of that fan-out logic."""
    ctx = set()
    def is_comb_cell(ci):
        return ci not in clock_cells and cells[ci][1] != 'DFFPOSX1'
    # forward: fan-out cones of nets driven by partition cells
    stack = []
    for ci in member_set:
        for o in CELLS[cells[ci][1]][1]:
            n = cells[ci][2].get(o)
            if n and not n.startswith("1'b"): stack.append(n)
    seen_n = set()
    while stack:
        n = stack.pop()
        if n in seen_n: continue
        seen_n.add(n)
        for lc, p in loads[n]:
            if lc in member_set or lc in ctx or not is_comb_cell(lc): continue
            ctx.add(lc)
            for o in CELLS[cells[lc][1]][1]:
                on = cells[lc][2].get(o)
                if on and not on.startswith("1'b"): stack.append(on)
    # backward: fan-in of every input used by partition or context cells
    stack = []
    for ci in list(member_set) + list(ctx):
        for n in cells[ci][2].values():
            if n and not n.startswith("1'b"): stack.append(n)
    seen_n = set()
    while stack:
        n = stack.pop()
        if n in seen_n: continue
        seen_n.add(n)
        d = driver.get(n)
        if d is None: continue
        dc = d[0]
        if dc in member_set or dc in ctx or not is_comb_cell(dc): continue
        ctx.add(dc)
        for m in comb_inputs(dc):
            if m and not m.startswith("1'b"): stack.append(m)
    return ctx

def partition(path):
    m = re.match(r'(?:cpu|nic)_(\d\d)/', path) or re.match(r'mesh_node(\d\d)/', path)
    return 'tile' + m.group(1) if m else 'top'

part_of = [partition(c[0]) for c in cells]
parts = sorted(set(part_of))

# ---------------------------------------------------------------- per-partition bench
stats = collections.Counter()
summary = []
for P in parts:
    ids = {}
    def nid(n):
        if n not in ids: ids[n] = f'n{len(ids)}'
        return ids[n]
    lines, pis, pos, faults = [], [], [], []
    po_names = []
    pi_names = []
    cnt = 0
    def node(expr):
        nonlocal_cnt[0] += 1
        return f'x{nonlocal_cnt[0]}'
    nonlocal_cnt = [0]
    members = [ci for ci in range(len(cells)) if part_of[ci] == P and ci not in clock_cells]
    member_set = set(members)
    context = compute_context(member_set) if CONTEXT and P != 'top' else set()
    used_nets = set()
    di_cnt = [0]
    const_nets = {}
    def emit(ci, with_faults):
        path, ref, conn = cells[ci]
        ins, outs = CELLS[ref]
        # input pins -> BUFF pin nodes
        pin_node = {}
        for p in ins:
            n = conn.get(p)
            if ref == 'DFFPOSX1' and p == 'CLK':
                di_cnt[0] += 2; continue
            if n is None:
                stats['unconnected_input_pins'] += 1
                n = "1'b0"
            if n.startswith("1'b"):
                if n not in const_nets:
                    c = f'const{n[-1]}'; const_nets[n] = c
                    lines.append(f'{c}_a = NOT(constsrc)')
                    lines.append(f'{c} = ' + ('AND(constsrc, ' if n[-1] == '0' else 'OR(constsrc, ') + f'{c}_a)')
                src_name = const_nets[n]
            else:
                used_nets.add(n); src_name = nid(n)
            if with_faults:
                pn = f'p{len(faults)}'
                lines.append(f'{pn} = BUFF({src_name})')
                pin_node[p] = pn
                faults.append((pn, f'{path}/{p}'))
            else:
                pin_node[p] = src_name
        for o, fn in outs.items():
            n = conn.get(o)
            if n is None or n.startswith("1'b"): continue
            if fn == 'DFF':
                # Q net is a PPI; D pin node is a PPO
                q = nid(n); pis.append(q); pi_names.append(('PPI', path, n))
                faults.append((q, f'{path}/Q'))
                pos.append(pin_node['D']); po_names.append(('PPO', path))
                continue
            y = nid(n); a = [pin_node[p] for p in ins]
            if fn in ('AND', 'OR', 'NAND', 'NOR', 'XOR', 'NOT', 'BUFF') and fn != 'XOR':
                lines.append(f'{y} = {fn}({", ".join(a)})')
            elif fn == 'XOR':
                lines.append(f'{y} = XOR({a[0]}, {a[1]})')
            elif fn == 'XNOR':
                t = node(0); lines.append(f'{t} = XOR({a[0]}, {a[1]})'); lines.append(f'{y} = NOT({t})')
            elif fn == 'AOI21':
                t = node(0); lines.append(f'{t} = AND({a[0]}, {a[1]})'); lines.append(f'{y} = NOR({t}, {a[2]})')
            elif fn == 'AOI22':
                t1, t2 = node(0), node(0)
                lines.extend([f'{t1} = AND({a[0]}, {a[1]})', f'{t2} = AND({a[2]}, {a[3]})', f'{y} = NOR({t1}, {t2})'])
            elif fn == 'OAI21':
                t = node(0); lines.append(f'{t} = OR({a[0]}, {a[1]})'); lines.append(f'{y} = NAND({t}, {a[2]})')
            elif fn == 'OAI22':
                t1, t2 = node(0), node(0)
                lines.extend([f'{t1} = OR({a[0]}, {a[1]})', f'{t2} = OR({a[2]}, {a[3]})', f'{y} = NAND({t1}, {t2})'])
            elif fn == 'MUXN':   # Y = !(S ? A : B)
                A, B, S = a
                sn, t1, t2 = node(0), node(0), node(0)
                lines.extend([f'{sn} = NOT({S})', f'{t1} = AND({S}, {A})', f'{t2} = AND({sn}, {B})', f'{y} = NOR({t1}, {t2})'])
            elif fn == 'XOR3':
                t = node(0); lines.append(f'{t} = XOR({a[0]}, {a[1]})'); lines.append(f'{y} = XOR({t}, {a[2]})')
            elif fn == 'MAJ':
                t1, t2, t3 = node(0), node(0), node(0)
                lines.extend([f'{t1} = AND({a[0]}, {a[1]})', f'{t2} = AND({a[1]}, {a[2]})', f'{t3} = AND({a[2]}, {a[0]})',
                              f'{y} = OR({t1}, {t2}, {t3})'])
            else:
                sys.exit(fn)
            if with_faults: faults.append((y, f'{path}/{o}'))
            used_nets.add(n)
    for ci in members: emit(ci, True)
    for ci in sorted(context): emit(ci, False)
    here = member_set | context
    # boundary: nets used here but driven elsewhere (or by a chip PI) -> PI
    for n in sorted(used_nets, key=lambda x: ids.get(x, '')):
        d = driver.get(n)
        driven_here = d is not None and d[0] in here and cells[d[0]][1] != 'DFFPOSX1'
        is_ppi = d is not None and d[0] in member_set and cells[d[0]][1] == 'DFFPOSX1'
        if not driven_here and not is_ppi:
            pis.append(nid(n))
            dpath = cells[d[0]][0] if d is not None else ''
            kind = 'PI' if n in chip_in else ('CLOCK' if n in clock_nets else
                    ('XPPI' if d is not None and cells[d[0]][1] == 'DFFPOSX1' else ('XPI' if d is not None else 'UNDRIVEN')))
            pi_names.append((kind, dpath, n)); stats[f'{P}_{kind}'] += 1
    # outputs: chip outputs, or nets driven here that are loaded outside the partition
    for n in sorted(used_nets):
        d = driver.get(n)
        if d is None or d[0] not in here or cells[d[0]][1] == 'DFFPOSX1': continue
        ext = n in chip_out or any(ci not in here or ci in clock_cells or (ci not in member_set and cells[ci][1] == 'DFFPOSX1')
                                   for ci, _ in loads[n])
        if ext:
            pos.append(nid(n)); stats[f'{P}_XPO'] += 1
            obs = [cells[ci][0] for ci, pp in loads[n] if cells[ci][1] == 'DFFPOSX1' and pp == 'D' and ci not in member_set]
            po_names.append(('XPO', ';'.join(obs) if obs else ('CHIPOUT:' + n if n in chip_out else 'OTHER:' + n)))
    if const_nets:
        pis.insert(0, 'constsrc'); pi_names.insert(0, ('CONSTSRC', '', ''))
    with open(f'{OUT}/{P}.bench', 'w') as f:
        f.write(f'# {P}\n')
        for p in pis: f.write(f'INPUT({p})\n')
        for p in pos: f.write(f'OUTPUT({p})\n')
        f.write('\n'.join(lines) + '\n')
    with open(f'{OUT}/{P}.flt', 'w') as f:
        for node_name, _ in faults:
            f.write(f'{node_name} /0\n{node_name} /1\n')
    with open(f'{OUT}/{P}.faultnames', 'w') as f:
        for node_name, pin in faults: f.write(f'{node_name} {pin}\n')
    with open(f'{OUT}/{P}.pomap', 'w') as f:
        for p, (kind, what) in zip(pos, po_names): f.write(f'{p} {kind} {what}\n')
    with open(f'{OUT}/{P}.map', 'w') as f:
        for p, (kind, inst, n) in zip(pis, pi_names): f.write(f'{p} {kind} {inst} {n}\n')
    summary.append((P, len(members), len(pis), len(pos), 2 * len(faults), di_cnt[0]))
    print(f"{P}: cells={len(members)} context={len(context)} PI={len(pis)} PO={len(pos)} faults={2*len(faults)} clockpin_faults={di_cnt[0]}", flush=True)

clock_pin_faults = sum(2 * (1 + len(CELLS[cells[ci][1]][1])) for ci in clock_cells)
with open(f'{OUT}/summary.txt', 'w') as f:
    f.write(f"leaf_cells {len(cells)}\nclock_cells {len(clock_cells)}\nclock_cell_pin_faults {clock_pin_faults}\n")
    for s in summary: f.write(' '.join(map(str, s)) + '\n')
    for k, v in sorted(stats.items()): f.write(f'{k} {v}\n')
print(f"clock-tree cells excluded: {len(clock_cells)} ({clock_pin_faults} pin faults)")
print(dict(stats))
