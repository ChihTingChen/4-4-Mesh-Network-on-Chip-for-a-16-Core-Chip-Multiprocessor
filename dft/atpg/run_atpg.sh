#!/bin/bash
# usage: run_atpg.sh <rundir> <partition> [atalanta options...]
D=$1; P=$2; shift 2
mkdir -p $D; cd $D
B=${BENCH:-bench}; ln -sf ../$B/$P.bench $P.bench
/usr/bin/time -f "%e s %M KB" ~/tools/atalanta_q/atalanta -f ../$B/$P.flt "$@" -t $P.test -l $P.log -U $P.ufaults -v $P.bench > $P.out 2> $P.err
