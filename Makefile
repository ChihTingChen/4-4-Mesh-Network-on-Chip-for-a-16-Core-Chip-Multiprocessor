###########################################################################
# Cardinal CMP (EE577B Phase 4) — full RTL-to-GDS flow
#
#   make rtl_sim                     RTL simulation vs golden dumps
#   make syn        P=1.15           DC bottom-up + in-context synthesis   -> syn/run_$(P)
#   make syn_sim    P=1.15 SP=1.3    post-syn gate sim (no-edge SDF) at SP ns
#   make lec        P=1.15           Conformal RTL vs netlist (+ negative test)
#   make sta_syn    P=1.15           PrimeTime on the synthesis netlist
#   make dft        P=1.15 DP=1.3    mux-D scan insertion (16 chains)      -> dft/run_$(DP)
#   make scan_sim   DP=1.3 L=<len>   scan-chain flush test
#   make pnr        P=1.15 PP=1.8    Innovus P&R of syn/run_$(P)            -> pnr/run_$(P)_p$(PP)
#   make pnr_sim / sta_pnr / ir       post-route sim, PT signoff, static IR
#
# One DC job at a time (shared server). Innovus is capped at 8 threads.
###########################################################################
SHELL := /bin/bash
ROOT  := $(CURDIR)
ENV   := source $(ROOT)/setup_ee577b_v26.sh
P  ?= 1.15
SP ?= 1.3
DP ?= 1.3
PP ?= 1.8
SYN := $(ROOT)/syn/run_$(P)
PNR := $(ROOT)/pnr/run_$(P)_p$(PP)

rtl_sim:
	sim/run_sim.sh rtl 10 rtl

syn:
	mkdir -p $(SYN) && cp -r design cardinal_cmp.tcl $(SYN)/
	cd $(SYN) && $(ENV) && CLK_PERIOD=$(P) dc_shell -f cardinal_cmp.tcl > syn.log 2>&1
	grep -m1 slack $(SYN)/report/cardinal_cmp.timing; grep "Total cell area" $(SYN)/report/cardinal_cmp.area

syn_sim:
	sim/run_sim.sh syn_$(P)_p$(SP) $(SP) $(SYN)/netlist/cardinal_cmp_syn.v $(SYN)/netlist/cardinal_cmp_syn_noedge.sdf

lec:
	scripts/run_lec.sh lec/syn_$(P) $(SYN)/netlist/cardinal_cmp_syn.v
	scripts/run_lec.sh lec/syn_$(P)_bug $(SYN)/netlist/cardinal_cmp_syn.v 1

sta_syn:
	mkdir -p sta/syn_$(P) && cd sta/syn_$(P) && $(ENV) && PT_NETLIST=$(SYN)/netlist/cardinal_cmp_syn.v PT_PERIOD=$(P) \
	    pt_shell -f $(ROOT)/scripts/pt_sta.tcl > pt.log 2>&1

dft:
	mkdir -p dft/run_$(DP) && cd dft/run_$(DP) && $(ENV) && SYN_DIR=$(SYN) CLK_PERIOD=$(DP) \
	    dc_shell -f $(ROOT)/scripts/dc_scan_insert.tcl > dft.log 2>&1

scan_sim:
	sim/run_scan_sim.sh scan_$(DP) $(L) $(ROOT)/dft/run_$(DP)/netlist/cardinal_cmp_scan.v

pnr:
	mkdir -p $(PNR) && cd $(PNR) && $(ENV) && PNR_PERIOD=$(PP) PNR_NETLIST=$(SYN)/netlist/cardinal_cmp_syn.v \
	    PNR_QRC=$(ROOT)/lib/freepdk45.qrcTechFile innovus -no_gui -overwrite -files $(ROOT)/scripts/pnr.tcl -log innovus.log > innovus.out 2>&1

pnr_sim:
	sim/run_sim.sh pnr_$(P)_p$(PP) $(PP) $(PNR)/out/cardinal_cmp_pnr.v $(PNR)/out/cardinal_cmp_pnr_noedge.sdf

sta_pnr:
	mkdir -p sta/pnr_$(P)_p$(PP) && cd sta/pnr_$(P)_p$(PP) && $(ENV) && PT_NETLIST=$(PNR)/out/cardinal_cmp_pnr.v \
	    PT_PERIOD=$(PP) PT_SPEF=$(PNR)/out/cardinal_cmp.spef pt_shell -f $(ROOT)/scripts/pt_sta.tcl > pt.log 2>&1

.PHONY: rtl_sim syn syn_sim lec sta_syn dft scan_sim pnr pnr_sim sta_pnr
