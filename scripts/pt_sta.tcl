#############################################################################
# PrimeTime STA — Cardinal CMP
#   env PT_NETLIST : gate netlist
#   env PT_PERIOD  : clock period (ns)
#   env PT_SPEF    : optional post-route SPEF  (=> propagated clocks)
#   env PT_SDF     : optional SDF instead of SPEF
#   env PT_SCAN    : 1 -> also time scan shift mode (test_se=1, 10 ns)
# Constraints = spec: I/O delay 1 ns, clock latency 0.5 ns (ideal pre-CTS;
# post-route the real clock tree replaces it).
#############################################################################
set netlist $env(PT_NETLIST)
set period  $env(PT_PERIOD)
set spef    [expr {[info exists env(PT_SPEF)] ? $env(PT_SPEF) : ""}]
set sdf     [expr {[info exists env(PT_SDF)]  ? $env(PT_SDF)  : ""}]
set scan    [expr {[info exists env(PT_SCAN)] ? $env(PT_SCAN) : 0}]
set lib     /tools/PDK/NCSU45PDK/FreePDK45/osu_soc/lib/files/gscl45nm.db

set search_path   [list . /tools/PDK/NCSU45PDK/FreePDK45/osu_soc/lib/files/]
set link_path     [list * $lib]
set report_default_significant_digits 3
set timing_report_unconstrained_paths false
file mkdir rpt

read_verilog $netlist
current_design cardinal_cmp
link_design cardinal_cmp

proc constrain {per se} {
    global spef sdf
    # same constraints as P&R: I/O against a virtual clock with the spec's
    # 0.5 ns latency; clk ideal (0.5 ns) pre-layout, propagated post-layout
    create_clock -name clk  -period $per -waveform [list 0 [expr $per/2.0]] [get_ports clk]
    create_clock -name vclk -period $per -waveform [list 0 [expr $per/2.0]]
    set_clock_latency 0.5 [get_clocks vclk]
    if {$spef ne "" || $sdf ne ""} {
        set_propagated_clock [get_clocks clk]
    } else {
        set_clock_latency 0.5 [get_clocks clk]
    }
    set_clock_uncertainty 0.05 [get_clocks {clk vclk}]
    set_input_delay  1.0 -clock vclk [remove_from_collection [all_inputs] [get_ports clk]]
    set_output_delay 1.0 -clock vclk [all_outputs]
    if {$se ne ""} { set_case_analysis $se [get_ports test_se] }
}

if {$spef ne ""} { read_parasitics -format SPEF $spef }
if {$sdf  ne ""} { read_sdf $sdf }

proc reports {tag} {
    update_timing -full
    report_global_timing                                   > rpt/${tag}_global_timing.rpt
    report_timing -delay_type max -max_paths 20 -nworst 1 -input_pins -nets -transition_time -capacitance \
                                                           > rpt/${tag}_setup_top20.rpt
    report_timing -delay_type min -max_paths 20 -nworst 1 -input_pins > rpt/${tag}_hold_top20.rpt
    report_constraint -all_violators -max_delay -min_delay > rpt/${tag}_violators.rpt
    report_analysis_coverage                               > rpt/${tag}_coverage.rpt
    check_timing -verbose                                  > rpt/${tag}_check_timing.rpt
    report_clock -skew -attribute                          > rpt/${tag}_clock.rpt
    # slack of the 1000 worst endpoints (setup + hold) -> histogram
    foreach {dt f} {max setup min hold} {
        set fp [open rpt/${tag}_${f}_endpoint_slack.txt w]
        foreach_in_collection p [get_timing_paths -delay_type $dt -max_paths 100000 -nworst 1 -slack_lesser_than 100] {
            puts $fp "[get_object_name [get_attribute $p endpoint]] [get_attribute $p slack]"
        }
        close $fp
    }
}

if {$scan} { constrain $period 0 } else { constrain $period "" }
reports func
if {$scan} {
    remove_clock [all_clocks]
    remove_case_analysis [get_ports test_se]
    constrain 10.0 1
    reports shift
}
exit
