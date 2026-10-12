######################################################################
# Design Compiler synthesis script — Cardinal CMP (bottom-up, one run)
#
#   1. cardinal_router, cardinal_nic, cardinal_cpu are each compiled once
#      (the CMP instantiates them 16x; dont_touch keeps one shared copy)
#   2. the top (cardinal_cmp + cardinal_mesh glue) is compiled on top of them
#
# Reference constraints (Phase 4 spec):
#   input delay = output delay = 1 ns, clock latency = 0.5 ns
#
# Clock period: env CLK_PERIOD (ns), default below. Sweep it to find the
# smallest period with slack >= 0 (minimum area x delay):
#   CLK_PERIOD=1.3 dc_shell -f cardinal_cmp.tcl | tee syn.log
#
# Expected layout:  ./design/*.v  -> RTL,  outputs in ./db ./report ./netlist
######################################################################

set design_name cardinal_cmp
if {[info exists env(CLK_PERIOD)]} {
    set clk_period $env(CLK_PERIOD)
} else {
    set clk_period 1.5
}
puts "Info: clock period = $clk_period ns"

## NCSU FreePDK45 library
set search_path [ list . \
                  /tools/PDK/NCSU45PDK/FreePDK45/osu_soc/lib/files/ \
                  /tools/synopsys/syn/Y-2026.03/dw/sim_ver/ ]
set target_library    { gscl45nm.db }
set synthetic_library [list dw_foundation.sldb standard.sldb]
set link_library      [list * gscl45nm.db dw_foundation.sldb standard.sldb]

file mkdir db report netlist

# gscl45nm bug: these output pins carry max_capacitance 0, which turns every
# net they drive into a max_cap violation (and makes DRV fixing chase
# impossible targets). Remove it; transition limits still bound the load.
read_db gscl45nm.db
# must run after every link (linked cell pins cache the library value)
proc fix_lib_maxcap {} {
    foreach pin {NAND2X1/Y NAND3X1/Y NOR2X1/Y AOI21X1/Y AOI22X1/Y TBUFX1/Y DFFSR/Q} {
        remove_attribute -quiet [get_lib_pins gscl45nm/$pin] max_capacitance
    }
}
fix_lib_maxcap
set_host_options -max_cores 16
set_app_var verilogout_no_tri true
# keep flop polarity = RTL polarity so Conformal LEC maps registers 1:1 (no SVF in Conformal)
set_app_var compile_seqmap_enable_output_inversion false

set rtl_dir ./design
set rtl_blocks [list $rtl_dir/alu.v $rtl_dir/sfu.v $rtl_dir/register_file.v \
                     $rtl_dir/cardinal_cpu.v $rtl_dir/cardinal_nic.v $rtl_dir/cardinal_router.v]
set rtl_top    [list $rtl_dir/cardinal_mesh.v $rtl_dir/cardinal_cmp.v]

# ------------------------------------------------------------------
# Block-level constraints.
#   ext_in / ext_out : ports that become chip pins -> reference 1 ns
#   all other ports  : block-to-block, budgeted at 35% of the period
#                      (every such port is flop-driven / flop-captured
#                       or a single gate away from one)
# ------------------------------------------------------------------
proc block_constraints {period ext_in ext_out} {
    create_clock -name clk -period $period -waveform [list 0 [expr $period/2.0]] [get_ports clk]
    set_clock_latency 0.5 [get_clocks clk]
    set budget [expr 0.35 * $period]
    set_input_delay  $budget -clock clk [remove_from_collection [all_inputs] [get_ports clk]]
    set_output_delay $budget -clock clk [all_outputs]
    if {[llength $ext_in]}  { set_input_delay  1.0 -clock clk [get_ports $ext_in] }
    if {[llength $ext_out]} { set_output_delay 1.0 -clock clk [get_ports $ext_out] }
    set_max_transition 0.5 [current_design]
    set_max_area 0
}

proc compile_block {name period ext_in ext_out} {
    puts "Info: ===== compiling $name ====="
    elaborate $name
    current_design $name
    link
    fix_lib_maxcap
    uniquify
    block_constraints $period $ext_in $ext_out
    # Avoid 'assign' statements / multi-port nets in the netlist (cleaner for Innovus & LEC)
    set_fix_multiple_port_nets -all -buffer_constants
    check_design > report/$name.check_design
    compile_ultra
    compile_ultra -incremental
    report_timing -max_paths 5 > report/$name.timing
    report_area  -hierarchy    > report/$name.area
    write -format ddc -hierarchy -output db/$name.ddc
}

# ==================================================================
# 1. Sub-blocks
# ==================================================================
analyze -format verilog $rtl_blocks

compile_block cardinal_router $clk_period {} {}
compile_block cardinal_nic    $clk_period {} {}
compile_block cardinal_cpu    $clk_period \
    {reset inst_in* dmem_data_out*} \
    {imem_pc_out* dmem_addr_out* memEn memWrEn dmem_data_in*}

# ==================================================================
# 2. Top level: pre-compiled blocks + mesh/top glue
# ==================================================================
remove_design -all
read_file -format ddc {db/cardinal_router.ddc db/cardinal_nic.ddc db/cardinal_cpu.ddc}
# Top RTL goes into its own library so elaborate can only pick up the
# already-compiled blocks from memory (never re-elaborate them from RTL).
file mkdir toplib
define_design_lib TOPLIB -path ./toplib
analyze -format verilog -library TOPLIB $rtl_top
elaborate $design_name -library TOPLIB
current_design $design_name
link
fix_lib_maxcap

set_dont_touch [get_designs {cardinal_router cardinal_nic cardinal_cpu}] true

create_clock -name clk -period $clk_period -waveform [list 0 [expr $clk_period/2.0]] [get_ports clk]
set_clock_latency 0.5 [get_clocks clk]
set_input_delay  1.0 -clock clk [remove_from_collection [all_inputs] [get_ports clk]]
set_output_delay 1.0 -clock clk [all_outputs]
set_max_transition 0.5 [current_design]
set_fix_multiple_port_nets -all -buffer_constants

check_design > report/$design_name.check_design
check_timing > report/$design_name.check_timing
compile_ultra
report_timing > report/$design_name.timing_bottomup

# In-context pass: router <-> NIC <-> router handshakes (ready -> send ->
# capture) are combinational across block boundaries, so the 35% port
# budgets cannot see them. Release router/NIC (small, 16 uniquified copies)
# and re-optimize them in chip context; the CPU stays one shared design.
set_dont_touch [get_designs {cardinal_router cardinal_nic}] false
compile_ultra -incremental
compile_ultra -incremental

# ==================================================================
# 3. Reports and outputs
# ==================================================================
report_timing                      > report/$design_name.timing
report_timing -max_paths 50 -nworst 1 > report/$design_name.timing_top50
report_qor                         > report/$design_name.qor
report_area                        > report/$design_name.area
report_area -hierarchy             > report/$design_name.area_hier
report_power                       > report/$design_name.power
report_constraint -all_violators   > report/$design_name.violators
report_reference -hierarchy        > report/$design_name.reference

change_names -rules verilog -hierarchy
write -format verilog -hierarchy -output netlist/${design_name}_syn.v
write -format ddc     -hierarchy -output db/${design_name}.ddc
write_sdf netlist/${design_name}_syn.sdf
write_sdc netlist/${design_name}_syn.sdc

exit
