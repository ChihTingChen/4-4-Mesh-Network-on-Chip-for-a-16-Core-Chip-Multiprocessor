###################################################################
# Cardinal CMP — Place & Route (Innovus 25.1, legacy UI)
#
#   init -> floorplan (4x4 tile guides, tile-aligned pin plan)
#        -> PDN (ring + M10/M9/M6 mesh + M1 rails)
#        -> place_opt_design (timing/congestion driven)
#        -> CTS (ccopt) -> postCTS setup/hold opt
#        -> NanoRoute -> postRoute setup/hold opt (+SI when capTbl/QRC)
#        -> fillers -> DRC / connectivity / antenna / PG checks
#        -> netlist, SDF, SPEF, DEF, GDS, reports
#
# Environment:
#   PNR_PERIOD   clock period for P&R (ns)              default 2.0
#   PNR_NETLIST  gate-level netlist                      default netlist/cardinal_cmp_syn.v
#   PNR_VARIANT  func | scan  (scan adds the shift mode)  default func
#   PNR_UTIL     target core utilization                 default 0.65
#   PNR_CPUS     threads (license allows 8)               default 8
#   PNR_QRC      optional qrcTechFile for extraction
#   PNR_START    resume stage: floorplan|place|cts|route|signoff
# Run from the run directory (outputs land there).
###################################################################

set ROOT [file normalize [file dirname [info script]]/..]
proc envd {n d} { if {[info exists ::env($n)] && $::env($n) ne ""} { return $::env($n) } ; return $d }
set period  [envd PNR_PERIOD 2.0]
set netlist [envd PNR_NETLIST $ROOT/netlist/cardinal_cmp_syn.v]
set variant [envd PNR_VARIANT func]
set util    [envd PNR_UTIL 0.65]
set ncpu    [envd PNR_CPUS 8]
set qrc     [envd PNR_QRC ""]
puts "Info: P&R period=$period variant=$variant util=$util netlist=$netlist"

source $ROOT/scripts/pnr_floorplan.tcl
file mkdir rpt out db

setMultiCpuUsage -localCpu $ncpu -keepLicense true
suppressMessage ENCEXT-2799 IMPEXT-2773 IMPEXT-2766

# ------------------------------------------------------------------
# 1. Constraints (spec: I/O delay 1 ns, clock latency 0.5 ns)
#    func  : test_se = 0
#    shift : (scan variant) test_se = 1, 10 ns shift clock
# ------------------------------------------------------------------
proc gen_sdc {file per se} {
    # I/O is constrained against a virtual clock carrying the spec's 0.5 ns
    # latency, so the synthesis I/O budget is kept after CTS, when clk itself
    # becomes propagated (real insertion delay replaces the ideal 0.5 ns).
    set fp [open $file w]
    puts $fp "create_clock -name clk  -period $per -waveform {0 [expr $per/2.0]} \[get_ports clk\]"
    puts $fp "create_clock -name vclk -period $per -waveform {0 [expr $per/2.0]}"
    puts $fp "set_clock_latency 0.5 \[get_clocks {clk vclk}\]"
    puts $fp "set_clock_uncertainty 0.05 \[get_clocks {clk vclk}\]"
    puts $fp "set_input_delay 1.0 -clock vclk \[remove_from_collection \[all_inputs\] \[get_ports clk\]\]"
    puts $fp "set_output_delay 1.0 -clock vclk \[all_outputs\]"
    puts $fp "set_max_transition 0.5 \[current_design\]"
    if {$se ne ""} { puts $fp "set_case_analysis $se \[get_ports test_se\]" }
    close $fp
}
gen_sdc out/func.sdc $period [expr {$variant eq "scan" ? 0 : ""}]
if {$variant eq "scan"} { gen_sdc out/shift.sdc 10.0 1 }

set fp [open out/mmmc.view w]
puts $fp "create_library_set -name ls_typ -timing {$ROOT/lib/gscl45nm_fixed.lib}"
if {$qrc ne ""} {
    puts $fp "create_rc_corner -name rc_typ -T 25 -qx_tech_file {$qrc}"
} else {
    puts $fp "create_rc_corner -name rc_typ -T 25"
}
puts $fp "create_delay_corner -name dc_typ -library_set ls_typ -rc_corner rc_typ"
puts $fp "create_constraint_mode -name func -sdc_files {out/func.sdc}"
if {$variant eq "scan"} {
    puts $fp "create_constraint_mode -name shift -sdc_files {out/shift.sdc}"
    puts $fp "create_analysis_view -name av_func  -constraint_mode func  -delay_corner dc_typ"
    puts $fp "create_analysis_view -name av_shift -constraint_mode shift -delay_corner dc_typ"
    puts $fp "set_analysis_view -setup {av_func av_shift} -hold {av_func av_shift}"
} else {
    puts $fp "create_analysis_view -name av_func -constraint_mode func -delay_corner dc_typ"
    puts $fp "set_analysis_view -setup {av_func} -hold {av_func}"
}
close $fp

# ------------------------------------------------------------------
# 2. Init
# ------------------------------------------------------------------
set init_lef_file   $ROOT/lib/gscl45nm.lef
set init_verilog    $netlist
set init_top_cell   cardinal_cmp
set init_mmmc_file  out/mmmc.view
set init_pwr_net    vdd
set init_gnd_net    gnd
set init_design_uniquify 1
# optional reporting / config commands must never kill a multi-hour run
proc safe {args} {
    if {[catch {uplevel 1 $args} msg]} { puts "Warning: (safe) '[lindex $args 0]' failed: $msg" }
}
# resume support: PNR_START = floorplan | place | cts | route | signoff
set stages {floorplan place cts route signoff}
set start [envd PNR_START floorplan]
set prevdb [dict create place db/01_floorplan.enc.dat cts db/02_place.enc.dat route db/03_cts.enc.dat signoff db/04_route.enc.dat]
proc run_stage {s} { global stages start; expr {[lsearch $stages $s] >= [lsearch $stages $start]} }

if {$start eq "floorplan"} {
    init_design
} else {
    restoreDesign [dict get $prevdb $start] cardinal_cmp
    setMultiCpuUsage -localCpu $ncpu -keepLicense true
}

setDesignMode -process 45 -topRoutingLayer metal8 -bottomRoutingLayer metal2
setAnalysisMode -analysisType onChipVariation -cppr both
setDelayCalMode -engine aae -SIAware false
setTieHiLoMode -reset

# ------------------------------------------------------------------
# 3. Floorplan, pins, tile guides, PDN
# ------------------------------------------------------------------
if {[run_stage floorplan]} {
    # 50 um core-to-die margin holds the 2 x 20 um M9/M10 core ring
    floorPlan -site CoreSite -r 1.0 $util 50 50 50 50
    puts "Info: die = [dbGet top.fPlan.box]  core = [dbGet top.fPlan.coreBox]"
    place_io_pins
    tile_guides
    build_pdn
    # (verifyConnectivity here makes the following place_opt_design a silent no-op in 25.1)
    safe checkPinAssignment -report_violating_pin > rpt/pin_assignment.rpt
    saveDesign db/01_floorplan.enc
    if {[envd PNR_STOP ""] eq "floorplan"} { exit }
}

# ------------------------------------------------------------------
# 4. Placement + preCTS optimization
# ------------------------------------------------------------------
if {[run_stage place]} {
    setPlaceMode -place_global_place_io_pins false -place_global_cong_effort high \
                 -place_global_timing_effort high -place_global_clock_gate_aware false
    setOptMode -fixCap true -fixTran true -fixFanoutLoad true \
               -usefulSkew false -addInstancePrefix PLC_ -maxDensity 0.85 \
               -setupTargetSlack 0.0 -holdTargetSlack 0.0
    place_opt_design
    if {[llength [dbGet -e top.insts.pStatus unplaced]] > 0} { puts "**ERROR: place_opt_design left cells unplaced" ; exit 1 }
    safe checkPlace rpt/checkPlace.rpt
    safe timeDesign -preCTS -prefix preCTS -outDir rpt/timing
    safe reportCongestion -hotSpot -overflow > rpt/congestion_preCTS.rpt
    saveDesign db/02_place.enc
}

# ------------------------------------------------------------------
# 5. Clock tree synthesis
# ------------------------------------------------------------------
if {[run_stage cts]} {
    safe set_ccopt_property buffer_cells   {CLKBUF1 CLKBUF2 CLKBUF3 BUFX4 BUFX2}
    safe set_ccopt_property inverter_cells {INVX8 INVX4 INVX2 INVX1}
    safe set_ccopt_property target_max_trans 0.10
    safe set_ccopt_property target_skew 0.05
    # clock nets: trunks on metal5-7, leaves on metal3-5
    safe create_route_type -name clk_trunk -top_preferred_layer metal7 -bottom_preferred_layer metal5 \
                      -preferred_routing_layer_effort high
    safe create_route_type -name clk_leaf  -top_preferred_layer metal5 -bottom_preferred_layer metal3
    safe set_ccopt_property route_type clk_trunk -net_type trunk
    safe set_ccopt_property route_type clk_leaf  -net_type leaf
    create_ccopt_clock_tree_spec -file out/ccopt.spec
    source out/ccopt.spec
    # place_opt_design (V2) leaves the db in PODv2 mode -> CTS + postCTS setup opt via clock_opt_design
    clock_opt_design
    safe report_ccopt_clock_trees -file rpt/clock_trees.rpt
    safe report_ccopt_skew_groups -file rpt/skew_groups.rpt
    safe timeDesign -postCTS -prefix postCTS -outDir rpt/timing
    optDesign -postCTS -hold -outDir rpt/postcts_hold
    safe timeDesign -postCTS -hold -prefix postCTS -outDir rpt/timing
    saveDesign db/03_cts.enc
}

# ------------------------------------------------------------------
# 6. Routing + postRoute optimization
# ------------------------------------------------------------------
if {$qrc ne ""} {
    setExtractRCMode -engine postRoute -effortLevel medium -coupled true
} else {
    setExtractRCMode -engine postRoute -effortLevel low
}
if {[run_stage route]} {
    setNanoRouteMode -routeWithTimingDriven true -routeWithSiDriven false \
                     -routeTopRoutingLayer 8 -routeBottomRoutingLayer 2 \
                     -drouteFixAntenna true -routeInsertAntennaDiode false \
                     -routeWithViaInPin true
    routeDesign -globalDetail -viaOpt -wireOpt
    if {$qrc ne ""} { setDelayCalMode -SIAware true }
    optDesign -postRoute -setup -hold -outDir rpt/postroute_opt
    safe optDesign -postRoute -drv -outDir rpt/postroute_drv
    saveDesign db/04_route.enc
}

# ------------------------------------------------------------------
# 7. Fillers, final route fix, signoff checks, outputs
# ------------------------------------------------------------------
if {$qrc ne ""} { setDelayCalMode -SIAware true }
addFiller -cell FILL -prefix FILL
ecoRoute
# ecoRoute after filler insertion can leave a few ps of hold: fix with fillers removed
setOptMode -holdTargetSlack 0.01
deleteFiller -prefix FILL
safe optDesign -postRoute -hold -outDir rpt/postroute_hold_eco
addFiller -cell FILL -prefix FILL
ecoRoute
safe timeDesign -postRoute       -prefix postRoute -outDir rpt/timing -expandedViews
safe timeDesign -postRoute -hold -prefix postRoute -outDir rpt/timing -expandedViews
safe report_timing -max_paths 200 -nworst 1 -path_type full_clock > rpt/postRoute_top200.tarpt
safe report_timing -early -max_paths 50 -nworst 1 > rpt/postRoute_hold_top50.tarpt

safe verify_drc -limit 100000 -report rpt/verify_drc.rpt
safe verifyConnectivity -type all -error 100000 -report rpt/verify_connectivity.rpt
safe verifyProcessAntenna -reportfile rpt/verify_antenna.rpt
safe checkPlace rpt/checkPlace_final.rpt

safe report_power -outfile rpt/power.rpt
safe report_power -hierarchy all -outfile rpt/power_hier.rpt
safe summaryReport -noHtml -outfile rpt/summaryReport.rpt
safe reportGateCount -level 5 -outfile rpt/gate_count.rpt
safe report_ccopt_skew_groups -file rpt/skew_groups_final.rpt

saveDesign db/05_final.enc
saveNetlist out/cardinal_cmp_pnr.v
safe saveNetlist out/cardinal_cmp_pnr_pg.v -includePowerGround -excludeLeafCell
write_sdf -version 3.0 out/cardinal_cmp_pnr.sdf
safe write_sdf -version 3.0 -edges noedge out/cardinal_cmp_pnr_noedge.sdf
safe rcOut -spef out/cardinal_cmp.spef -rc_corner rc_typ
safe defOut -floorplan -netlist -routing out/cardinal_cmp.def
safe streamOut out/cardinal_cmp.gds -mapFile $ROOT/lib/gds2_encounter.map -merge [glob $ROOT/lib/gds/*.gds] \
          -stripes 1 -units 1000 -mode ALL
safe write_sdc out/cardinal_cmp_pnr_final.sdc
puts "Info: P&R done (period $period ns, variant $variant)"
exit
