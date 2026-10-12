###################################################################
# Dump inputs for the static IR-drop solver (scripts/ir_solve.py)
#   ir/pg_wires.txt : net shape layer x1 y1 x2 y2 width
#   ir/pg_vias.txt  : net viaName x y botLayer topLayer nCuts R(db)
#   ir/inst_power.rpt (Innovus report_power, per instance) -> inst_pwr.txt
#                     is built by ir_solve's wrapper (scripts/ir_inst.py)
# Run in Innovus with the routed design loaded.
###################################################################
file mkdir ir
set fp [open ir/pg_wires.txt w]
foreach net {vdd gnd} {
    set n [dbGet -p top.nets.name $net]
    foreach w [dbGet $n.sWires] {
        lassign [lindex [dbGet $w.box] 0] x1 y1 x2 y2
        puts $fp "$net [dbGet $w.shape] [dbGet $w.layer.name] $x1 $y1 $x2 $y2 [dbGet $w.width]"
    }
}
close $fp

set fp [open ir/pg_vias.txt w]
foreach net {vdd gnd} {
    set n [dbGet -p top.nets.name $net]
    foreach v [dbGet -e $n.sVias] {
        lassign [lindex [dbGet $v.pt] 0] x y
        set vd [dbGet $v.via]
        puts $fp "$net [dbGet $vd.name] $x $y [dbGet $vd.botLayer.name] [dbGet $vd.topLayer.name] [expr {[dbGet $vd.cutRows] * [dbGet $vd.cutColumns]}] [dbGet $vd.resistance]"
    }
}
close $fp

# instance centres
set fp [open ir/inst_loc.txt w]
foreach i [dbGet top.insts] {
    lassign [lindex [dbGet $i.box] 0] x1 y1 x2 y2
    puts $fp "[dbGet $i.name] [expr ($x1+$x2)/2.0] [expr ($y1+$y2)/2.0]"
}
close $fp

# power: default activity 0.2 (no VCD) at the P&R clock
set_default_switching_activity -input_activity 0.2 -seq_activity 0.2
report_power -outfile ir/power_summary.rpt
report_power -instances * -outfile ir/inst_power.rpt
puts "Info: IR dump done"
