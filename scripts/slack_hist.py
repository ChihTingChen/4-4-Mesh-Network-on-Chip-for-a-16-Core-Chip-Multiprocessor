#!/usr/bin/env python3
"""usage: slack_hist.py out.png title file1:label1 [file2:label2 ...]  (endpoint slack lists from pt_sta.tcl)"""
import sys
import matplotlib; matplotlib.use('Agg')
import matplotlib.pyplot as plt
out, title = sys.argv[1], sys.argv[2]
plt.figure(figsize=(7, 4))
for spec in sys.argv[3:]:
    f, lab = spec.split(':')
    v = [float(l.split()[1]) for l in open(f) if len(l.split()) == 2]
    plt.hist(v, bins=40, alpha=0.6, label=f"{lab} (n={len(v)}, worst={min(v):.3f} ns)")
plt.axvline(0, color='k', lw=0.8); plt.xlabel('endpoint slack (ns)'); plt.ylabel('# endpoints')
plt.title(title); plt.legend(fontsize=8); plt.tight_layout(); plt.savefig(out, dpi=130)
