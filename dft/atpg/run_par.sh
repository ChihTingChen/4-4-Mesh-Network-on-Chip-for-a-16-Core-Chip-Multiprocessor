#!/bin/bash
# usage: run_val.sh <partition> <npat> [inject]
# gate-level validation of ATPG patterns on the post-route scan netlist + SDF
set -e
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
source $ROOT/setup_ee577b_v26.sh
P=$1; NP=$2; INJ=${3:-0}
O=$ROOT/pnr/scan_1.15_p1.5_v2/out
SUF=""; if [ "$INJ" = 1 ]; then SUF=_inj; fi
D=$ROOT/dft/atpg/val/par_$P$SUF; mkdir -p $D; cd $D
V=$ROOT/dft/atpg/val
DEFS="+define+NPAT=$NP +define+LOADFILE=\"$V/$P.pload\" +define+NFF_W=66304 +define+FLOPFILE=\"$V/par_flops.vh\" +define+PIFILE=\"$V/$P.pi\" +define+CAPFILE=\"$D/cap.txt\" +define+SDF_FILE=\"$O/cardinal_cmp_pnr_sim.sdf\""
[ "$INJ" = 1 ] && DEFS="$DEFS +define+INJECT +define+FAULTFILE=\"$V/${P}_faults.vh\""
xrun -64bit -q -timescale 1ns/1ps -access +rw -neg_tchk -nowarn SDFNCAP -nowarn CUVWSP -nowarn CUVMPW \
     -incdir $ROOT/dft/atpg $DEFS $ROOT/include/gscl45nm.v $O/cardinal_cmp_pnr.v $ROOT/dft/atpg/tb_par.v -top tb_par > xrun.log 2>&1 || true
echo "timing violations: $(grep -c 'Timing violation' xrun.log)"; grep -E "\*E" xrun.log | head -5
