#!/bin/bash
# usage: run_scan_sim.sh <name> <chain_len> <netlist> [sdf] [shift_period_ns]
set -e
ROOT=$(cd "$(dirname "$0")/.." && pwd)
source $ROOT/setup_ee577b_v26.sh
NAME=$1; L=$2; NET=$3; SDF=$4; PER=${5:-10}
D=$ROOT/sim/$NAME; mkdir -p $D; cd $D
HALF=$(python3 -c "print($PER/2)")
DEFS="+define+CHAIN_LEN=$L +define+CLK_HALF=$HALF"
[ -n "$SDF" ] && DEFS="$DEFS +define+SDF_FILE=\"$SDF\""
xrun -64bit -q -timescale 1ns/1ps -access +r -nowarn SDFNCAP -nowarn CUVWSP -nowarn CUVMPW -neg_tchk \
     $DEFS $ROOT/include/gscl45nm.v $NET $ROOT/tb/tb_scan.v -top tb_scan > xrun.log 2>&1 || true
nviol=$(grep -c "Timing violation" xrun.log || true)
r=$(grep "SCAN FLUSH TEST" xrun.log || echo "SCAN FLUSH TEST: did not finish")
echo "[$NAME] $r  timing-check messages=$nviol" | tee result.txt
