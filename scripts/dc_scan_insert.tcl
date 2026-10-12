######################################################################
# DFT: mux-D scan insertion in Design Compiler — Cardinal CMP
#
# gscl45nm has no scan flip-flop (no test_cell), so DFT Compiler's
# insert_dft cannot scan-replace. Instead every DFFPOSX1 gets a
# mux-D scan front end built from library cells:
#
#      D_func ──B┐
#                MUX2X1 (inverting) ──INVX1── D
#      SI ─────A┘  S = scan_en
#
#   D = scan_en ? SI : D_func   (non-inverting chain)
#
# Hierarchical DFT: each block (router / nic / cpu) is compiled once and
# shared by the 16 tiles, so the block-level chain is inserted once in the
# block design and the 16 copies are stitched at the top:
#
#   test_si[k] -> router(node k) -> nic_k -> cpu_k -> test_so[k]   k = 0..15
#
# Test ports added to cardinal_cmp: test_se, test_si[15:0], test_so[15:0]
#
# Functional timing is optimized with set_case_analysis 0 on scan_en;
# test_se is an ideal network here and is buffered in P&R.
#
# Inputs : env SYN_DIR  (a finished functional run, uses db/<block>.ddc)
#          env CLK_PERIOD
# Outputs: netlist/cardinal_cmp_scan.v, .sdf, .sdc, report/scan_*,
#          report/scan_chains.txt (per-block chain order)
######################################################################

set design_name cardinal_cmp
set clk_period  $env(CLK_PERIOD)
set syn_dir     $env(SYN_DIR)
puts "Info: DFT run, clock period = $clk_period ns, blocks from $syn_dir"

set search_path [ list . /tools/PDK/NCSU45PDK/FreePDK45/osu_soc/lib/files/ ]
set target_library    { gscl45nm.db }
set synthetic_library [list dw_foundation.sldb standard.sldb]
set link_library      [list * gscl45nm.db dw_foundation.sldb standard.sldb]
set_host_options -max_cores 16
set_app_var verilogout_no_tri true
set_app_var compile_seqmap_enable_output_inversion false

file mkdir db report netlist

# gscl45nm max_capacitance:0 bug (see cardinal_cmp.tcl)
read_db gscl45nm.db
# must run after every link (linked cell pins cache the library value)
proc fix_lib_maxcap {} {
    foreach pin {NAND2X1/Y NAND3X1/Y NOR2X1/Y AOI21X1/Y AOI22X1/Y TBUFX1/Y DFFSR/Q} {
        remove_attribute -quiet [get_lib_pins gscl45nm/$pin] max_capacitance
    }
}
fix_lib_maxcap

# ------------------------------------------------------------------
# Insert one scan chain into the current (flattened) block design.
# Returns the chain length; chain order is written to $fp.
# ------------------------------------------------------------------
proc insert_block_chain {blk fp} {
    current_design $blk
    ungroup -all -flatten
    set ffs [get_cells -filter "ref_name==DFFPOSX1"]
    set other [get_cells -filter "is_sequential==true && ref_name!=DFFPOSX1"]
    if {[sizeof_collection $other] > 0} {
        puts "Error: $blk has non-DFFPOSX1 sequential cells: [get_object_name $other]"
    }
    set names [lsort -dictionary [get_object_name $ffs]]
    puts "Info: $blk : [llength $names] flops -> 1 scan chain"

    create_port -direction in  scan_en
    create_port -direction in  scan_in
    create_port -direction out scan_out
    create_net scan_en_net ; connect_net scan_en_net [get_ports scan_en]
    create_net scan_in_net ; connect_net scan_in_net [get_ports scan_in]

    set prev scan_in_net
    set i 0
    foreach ff $names {
        set dnet [get_nets -of_objects [get_pins $ff/D]]
        disconnect_net $dnet [get_pins $ff/D]
        set m sdft_mux_$i
        set v sdft_inv_$i
        create_cell $m gscl45nm/MUX2X1
        create_cell $v gscl45nm/INVX1
        connect_net $dnet        [get_pins $m/B]
        connect_net $prev        [get_pins $m/A]
        connect_net scan_en_net  [get_pins $m/S]
        create_net sdft_mn_$i ; connect_net sdft_mn_$i [get_pins $m/Y] ; connect_net sdft_mn_$i [get_pins $v/A]
        create_net sdft_dn_$i ; connect_net sdft_dn_$i [get_pins $v/Y] ; connect_net sdft_dn_$i [get_pins $ff/D]
        set qnet [get_nets -of_objects [get_pins $ff/Q]]
        if {[sizeof_collection $qnet] == 0} {
            create_net sdft_qn_$i ; connect_net sdft_qn_$i [get_pins $ff/Q]
            set qnet [get_nets sdft_qn_$i]
        }
        set prev [get_object_name $qnet]
        puts $fp "$blk $i $ff"
        incr i
    }
    # scan_out through a buffer: last Q net may already drive a functional port
    create_cell sdft_so_buf gscl45nm/BUFX2
    connect_net $prev [get_pins sdft_so_buf/A]
    create_net scan_out_net
    connect_net scan_out_net [get_pins sdft_so_buf/Y]
    connect_net scan_out_net [get_ports scan_out]
    return $i
}

proc block_constraints {period ext_in ext_out} {
    create_clock -name clk -period $period -waveform [list 0 [expr $period/2.0]] [get_ports clk]
    set_clock_latency 0.5 [get_clocks clk]
    set budget [expr 0.35 * $period]
    set_input_delay  $budget -clock clk [remove_from_collection [all_inputs] [get_ports clk]]
    set_output_delay $budget -clock clk [all_outputs]
    if {[llength $ext_in]}  { set_input_delay  1.0 -clock clk [get_ports $ext_in] }
    if {[llength $ext_out]} { set_output_delay 1.0 -clock clk [get_ports $ext_out] }
    # functional mode; scan_en is a static test signal (buffered in P&R)
    set_case_analysis 0 [get_ports scan_en]
    set_ideal_network [get_ports scan_en]
    set_max_transition 0.5 [current_design]
    set_max_area 0
}

# ==================================================================
# 1. Blocks: insert chain, re-optimize functional timing
# ==================================================================
read_file -format ddc [list $syn_dir/db/cardinal_router.ddc $syn_dir/db/cardinal_nic.ddc $syn_dir/db/cardinal_cpu.ddc]

set fp [open report/scan_chains.txt w]
array set chain_len {}
foreach {blk ein eout} [list \
        cardinal_router {} {} \
        cardinal_nic    {} {} \
        cardinal_cpu    {reset inst_in* dmem_data_out*} {imem_pc_out* dmem_addr_out* memEn memWrEn dmem_data_in*} ] {
    set chain_len($blk) [insert_block_chain $blk $fp]
    current_design $blk
    link
    fix_lib_maxcap
    block_constraints $clk_period $ein $eout
    set_fix_multiple_port_nets -all -buffer_constants
    report_timing -max_paths 1 > report/$blk.scan_pre_incr.timing
    compile_ultra -incremental
    report_timing -max_paths 5 > report/$blk.scan.timing
    report_area                > report/$blk.scan.area
    write -format ddc -hierarchy -output db/$blk.scan.ddc
}
close $fp

# ==================================================================
# 2. Top: link scanned blocks, stitch 16 chains
# ==================================================================
remove_design -all
read_file -format ddc {db/cardinal_router.scan.ddc db/cardinal_nic.scan.ddc db/cardinal_cpu.scan.ddc}
file mkdir toplib
define_design_lib TOPLIB -path ./toplib
analyze -format verilog -library TOPLIB [list $syn_dir/design/cardinal_mesh.v $syn_dir/design/cardinal_cmp.v]
elaborate $design_name -library TOPLIB
current_design $design_name
link
fix_lib_maxcap
ungroup mesh
set_dont_touch [get_designs {cardinal_router cardinal_nic cardinal_cpu}] true

create_port -direction in test_se
create_net test_se_net ; connect_net test_se_net [get_ports test_se]
set nodes {00 01 02 03 10 11 12 13 20 21 22 23 30 31 32 33}
set k 0
foreach n $nodes {
    set r [get_cells "mesh/node$n"]
    set r [get_object_name $r]
    create_port -direction in  "test_si[$k]"
    create_port -direction out "test_so[$k]"
    foreach c [list $r nic_$n cpu_$n] { connect_net test_se_net [get_pins $c/scan_en] }
    create_net tsi_$k ; connect_net tsi_$k [get_ports "test_si[$k]"] ; connect_net tsi_$k [get_pins $r/scan_in]
    create_net tc_rn_$k ; connect_net tc_rn_$k [get_pins $r/scan_out] ; connect_net tc_rn_$k [get_pins nic_$n/scan_in]
    create_net tc_nc_$k ; connect_net tc_nc_$k [get_pins nic_$n/scan_out] ; connect_net tc_nc_$k [get_pins cpu_$n/scan_in]
    create_net tso_$k ; connect_net tso_$k [get_pins cpu_$n/scan_out] ; connect_net tso_$k [get_ports "test_so[$k]"]
    incr k
}
set total_len [expr $chain_len(cardinal_router) + $chain_len(cardinal_nic) + $chain_len(cardinal_cpu)]
puts "Info: 16 scan chains, length $total_len each (router $chain_len(cardinal_router) + nic $chain_len(cardinal_nic) + cpu $chain_len(cardinal_cpu))"

create_clock -name clk -period $clk_period -waveform [list 0 [expr $clk_period/2.0]] [get_ports clk]
set_clock_latency 0.5 [get_clocks clk]
set_input_delay  1.0 -clock clk [remove_from_collection [all_inputs] [get_ports clk]]
set_output_delay 1.0 -clock clk [all_outputs]
set_case_analysis 0 [get_ports test_se]
set_ideal_network [get_ports test_se]
set_max_transition 0.5 [current_design]
set_fix_multiple_port_nets -all -buffer_constants

check_design > report/$design_name.scan.check_design
compile_ultra
# in-context pass for the router <-> NIC handshakes (see cardinal_cmp.tcl)
set_dont_touch [get_designs {cardinal_router cardinal_nic}] false
compile_ultra -incremental
compile_ultra -incremental

# ==================================================================
# 3. Reports and outputs
# ==================================================================
set fp [open report/scan_summary.txt w]
puts $fp "scan style      : mux-D (MUX2X1 + INVX1 in front of DFFPOSX1), non-inverting"
puts $fp "scan enable     : test_se (active high)"
puts $fp "chains          : 16 (one per tile: router -> nic -> cpu)"
puts $fp "chain length    : $total_len  (router $chain_len(cardinal_router), nic $chain_len(cardinal_nic), cpu $chain_len(cardinal_cpu))"
puts $fp "scan flops      : [expr 16*$total_len]"
puts $fp "total flops     : [sizeof_collection [get_cells -hier -filter is_sequential==true]]"
close $fp

report_timing                         > report/$design_name.scan.timing
report_timing -max_paths 50 -nworst 1 > report/$design_name.scan.timing_top50
report_qor                            > report/$design_name.scan.qor
report_area                           > report/$design_name.scan.area
report_area -hierarchy                > report/$design_name.scan.area_hier
report_power                          > report/$design_name.scan.power
report_constraint -all_violators      > report/$design_name.scan.violators

change_names -rules verilog -hierarchy
write -format verilog -hierarchy -output netlist/${design_name}_scan.v
write -format ddc     -hierarchy -output db/${design_name}_scan.ddc
write_sdf netlist/${design_name}_scan.sdf
write_sdc netlist/${design_name}_scan.sdc

exit
