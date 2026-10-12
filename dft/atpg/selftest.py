import sys, random, time
sys.path.insert(0, '.')
from benchsim import Bench, read_patterns
b = Bench(sys.argv[1]); pats = read_patterns(sys.argv[2], len(b.inputs)); flt = sys.argv[3]; K = int(sys.argv[4])
W = len(pats)
words = {}
for i, pi in enumerate(b.inputs):
    words[pi] = int(''.join(p[i] for p in reversed(pats)), 2)   # bit j = pattern j
t = time.time(); good = b.sim(words, W); print(f"{len(b.order)} gates, {W} patterns, good sim {time.time()-t:.1f}s")
faults = [l.split() for l in open(flt)]
random.seed(1); sample = random.sample(faults, K)
det = 0; undet = []
for node, sv in sample:
    v = b.sim(words, W, fault=(node, int(sv[1])))
    if any(v[o] != good[o] for o in b.outputs): det += 1
    else: undet.append(f"{node}{sv}")
print(f"sampled {K} faults: detected {det} ({100*det/K:.2f}%), undetected {undet[:10]}")
