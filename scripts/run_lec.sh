#!/bin/bash
# Conformal LEC: RTL (golden) vs gate-level netlist (revised), flat compare.
#
# usage: run_lec.sh <run-dir> <netlist> [inject_bug] [scan]
#   inject_bug : 1 -> insert an inverter on node00 memEn (dmem_en_00) in a copy
#                of the netlist; LEC must report NON-EQUIVALENT (negative test)
#   scan       : 1 -> revised has scan ports; test_se constrained to 0,
#                test_so ignored (functional-mode equivalence)
set -e
ROOT=$(cd "$(dirname "$0")/.." && pwd)
source $ROOT/setup_ee577b_v26.sh
D=$1; NET=$(readlink -f $2); BUG=${3:-0}; SCAN=${4:-0}
mkdir -p $D; cd $D

if [ "$BUG" = 1 ]; then
  # cpu_00 drives top output dmem_en_00 directly: re-route it through an INVX1
  python3 - "$NET" bug_netlist.v <<'EOF'
import sys,re
src,dst=sys.argv[1],sys.argv[2]
s=open(src).read()
top=s.rfind('module cardinal_cmp ')
head,body=s[:top],s[top:]
n=body.count('.memEn(dmem_en_00)')
assert n==1, n
body=body.replace('.memEn(dmem_en_00)','.memEn(lec_bug_en_00_n)')
i=body.index(';')+1           # end of module port list
body=body[:i]+'\n  wire lec_bug_en_00_n;\n  INVX1 lec_bug_inv ( .A(lec_bug_en_00_n), .Y(dmem_en_00) );\n'+body[i:]
open(dst,'w').write(head+body)
print("injected inverter on dmem_en_00")
EOF
  NET=$PWD/bug_netlist.v
fi

RTL="$ROOT/design/alu.v $ROOT/design/sfu.v $ROOT/design/register_file.v $ROOT/design/cardinal_cpu.v $ROOT/design/cardinal_nic.v $ROOT/design/cardinal_router.v $ROOT/design/cardinal_mesh.v $ROOT/design/cardinal_cmp.v"
cat > lec.do <<EOF
set log file lec.log -replace
set parallel option -threads 8
read library -liberty $ROOT/lib/gscl45nm_fixed.lib
read design -golden  -verilog $RTL -root cardinal_cmp
read design -revised -verilog $NET -root cardinal_cmp
set root module cardinal_cmp -both
EOF
if [ "$SCAN" = 1 ]; then
cat >> lec.do <<'EOF'
add pin constraints 0 test_se -revised
add ignored outputs test_so* -revised
EOF
fi
cat >> lec.do <<'EOF'
set flatten model -seq_constant
set analyze option -auto
set mapping method -phase
set system mode lec
// remodel merged / duplicated / constant registers from DC before comparing
analyze setup -verbose
add compared points -all
compare
report verification > verification.rpt
report statistics > statistics.rpt
report unmapped points -summary > unmapped_summary.rpt
report unmapped points -notmapped > unmapped_detail.rpt
report compare data -class nonequivalent > nonequivalent.rpt
report compare data -class abort > aborted.rpt
exit -force
EOF
lec -nogui -xl -dofile lec.do > lec.out 2>&1 || true
echo "== $D"; grep -A12 "Compared points" lec.log | head -14
