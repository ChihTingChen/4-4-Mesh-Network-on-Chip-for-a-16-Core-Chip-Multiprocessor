#!/bin/bash
# usage: run_sim.sh <name> <period_ns> <netlist-or-"rtl"> [sdf]
#   runs tb_cmp on RTL or a gate-level netlist (+ SDF), compares 16 dumps to golden/
set -e
ROOT=$(cd "$(dirname "$0")/.." && pwd)
source $ROOT/setup_ee577b_v26.sh
NAME=$1; PER=$2; NET=$3; SDF=$4
D=$ROOT/sim/$NAME; rm -rf $D; mkdir -p $D/dump; cd $D
HALF=$(python3 -c "print($PER/2)")
if [ "$NET" = rtl ]; then
  SRC="$ROOT/design/alu.v $ROOT/design/sfu.v $ROOT/design/register_file.v $ROOT/design/cardinal_cpu.v $ROOT/design/cardinal_nic.v $ROOT/design/cardinal_router.v $ROOT/design/cardinal_mesh.v $ROOT/design/cardinal_cmp.v"
else
  SRC="$ROOT/include/gscl45nm.v $NET"
fi
DEFS="+define+CLK_HALF=$HALF $EXTRA_DEFS"
[ -n "$SDF" ] && DEFS="$DEFS +define+SDF_FILE=\"$SDF\""
ln -sf $ROOT/testcase testcase
xrun -64bit -q -timescale 1ns/1ps -access +r -nowarn SDFNCAP -nowarn CUVWSP -nowarn CUVMPW \
     -sdf_verbose -neg_tchk $DEFS \
     $SRC $ROOT/design/imem.v $ROOT/design/dmem.v $ROOT/tb/tb_cmp.v -top tb_cmp > xrun.log 2>&1 || true
fail=0
for f in $ROOT/golden/*.dump; do
  b=$(basename $f)
  if ! cmp -s $f dump/$b; then echo "MISMATCH $b"; fail=1; fi
done
nviol=$(grep -c "Timing violation" xrun.log || true)
echo "[$NAME] period=$PER  timing-check messages=$nviol  result=$([ $fail = 0 ] && echo PASS || echo FAIL)" | tee result.txt
