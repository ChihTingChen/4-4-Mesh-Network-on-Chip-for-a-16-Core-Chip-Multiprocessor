###################################################################
# Floorplan helpers for Cardinal CMP (sourced by pnr.tcl)
#
#  * 4x4 tile plan that mirrors the mesh topology: node "YX" sits in
#    tile column X, row Y (Y=0 at the bottom), so every router link is
#    a short tile-to-tile hop. Each tile is a soft instance-group guide
#    holding that node's router + NIC + CPU.
#  * Pin plan: every node's 226 I/Os sit on the die edge next to its
#    tile. Each edge is cut into 4 tile-wide segments; corner nodes get
#    two segments, inner nodes share a segment with the edge node they
#    sit behind (rotationally symmetric):
#        bottom: c0=00  c1=01+11  c2=02     c3=03
#        right : r0=03  r1=13+12  r2=23     r3=33
#        top   : c3=33  c2=32+22  c1=31     c0=30
#        left  : r3=30  r2=20+21  r1=10     r0=00
#    Top/bottom pins alternate metal4/metal6 (vertical layers),
#    left/right pins alternate metal5/metal3 (horizontal layers). clk/reset (+ test_se) sit at the middle of the
#    left edge, between rows 1 and 2.
###################################################################

proc node_list {} { return {00 01 02 03 10 11 12 13 20 21 22 23 30 31 32 33} }

# pins of node n (bus bits expanded), in a stable bus order
proc node_pins {n} {
    set pins {}
    foreach pat [list imem_addr_$n imem_data_$n dmem_addr_$n dmem_data_out_$n dmem_data_in_$n dmem_wrEn_$n dmem_en_$n] {
        set bits [dbGet -e top.terms.name "${pat}\\\[*"]
        if {$bits eq ""} { set bits [dbGet -e top.terms.name $pat] }
        set pins [concat $pins $bits]
    }
    # scan variant: this node's chain index k
    set k [lsearch [node_list] $n]
    # DC writes the scan ports as scalars test_si_<k>_ / test_so_<k>_
    set pins [concat $pins [dbGet -e top.terms.name "test_si_${k}_"] [dbGet -e top.terms.name "test_so_${k}_"]]
    return $pins
}

# segment table: side index -> list of {segment-index nodes}
proc pin_segments {} {
    return {
        Bottom {{0 00} {1 {01 11}} {2 02} {3 03}}
        Right  {{0 03} {1 {13 12}} {2 23} {3 33}}
        Top    {{3 33} {2 {32 22}} {1 31} {0 30}}
        Left   {{3 30} {2 {20 21}} {1 10} {0 00}}
    }
}

proc place_io_pins {} {
    set W [dbGet top.fPlan.box_urx]
    set H [dbGet top.fPlan.box_ury]
    set core [lindex [dbGet top.fPlan.coreBox] 0]
    lassign $core cx1 cy1 cx2 cy2
    set tw [expr ($cx2-$cx1)/4.0]
    set th [expr ($cy2-$cy1)/4.0]

    # how many segments each node owns (corners own 2) -> split its pins
    array set nseg {}
    foreach {side segs} [pin_segments] {
        foreach s $segs { foreach n [lindex $s 1] { incr nseg($n) } }
    }
    array set used {}
    foreach n [node_list] { set used($n) 0 ; set allpins($n) [node_pins $n] }

    # batch mode: ~1 s per editPin otherwise (explicit -assign coordinates are kept)
    setPinAssignMode -pinEditInBatch true
    foreach {side segs} [pin_segments] {
        # two layers per edge, pins alternate between them
        set layer [expr {($side eq "Bottom" || $side eq "Top") ? {4 6} : {5 3}}]
        foreach s $segs {
            lassign $s idx nodes
            # pins that go on this segment
            set plist {}
            foreach n $nodes {
                set all $allpins($n)
                set per [expr int(ceil([llength $all] / double($nseg($n))))]
                set chunk [lrange $all $used($n) [expr $used($n)+$per-1]]
                incr used($n) [llength $chunk]
                set plist [concat $plist $chunk]
            }
            if {[llength $plist] == 0} continue
            # segment range on the die edge, 3 um in from the tile borders
            switch $side {
                Bottom { set a [list [expr $cx1+$idx*$tw+3] 0]   ; set b [list [expr $cx1+($idx+1)*$tw-3] 0] }
                Top    { set a [list [expr $cx1+$idx*$tw+3] $H]  ; set b [list [expr $cx1+($idx+1)*$tw-3] $H] }
                Left   { set a [list 0 [expr $cy1+$idx*$th+3]]   ; set b [list 0 [expr $cy1+($idx+1)*$th-3]] }
                Right  { set a [list $W [expr $cy1+$idx*$th+3]]  ; set b [list $W [expr $cy1+($idx+1)*$th-3]] }
            }
            # keep the clk/reset window on the left edge free
            if {$side eq "Left" && $idx == 1} { set b [list 0 [expr $cy1+2*$th-12]] }
            if {$side eq "Left" && $idx == 2} { set a [list 0 [expr $cy1+2*$th+12]] }
            puts "Info: pins $side seg$idx nodes {$nodes}: [llength $plist] pins on metal$layer"
            assign_pins_on_segment $plist $side $layer $a $b
        }
    }
    # clock / reset / scan-enable: centre of the left edge, 4 um apart
    set ymid [expr $cy1 + 2*$th]
    set ctl [list clk reset]
    if {[dbGet -e top.terms.name test_se] ne ""} { lappend ctl test_se }
    set i 0
    foreach p $ctl {
        editPin -pin $p -layer 5 -assign [list 0 [expr $ymid - 4 + 4*$i]] \
                -pinWidth 0.14 -pinDepth 0.56 -fixedPin 1 -snap TRACK
        incr i
    }
    setPinAssignMode -pinEditInBatch false
}

# Spread pins between points a and b on one die edge, alternating between
# the two given layers. The step is an integer number (>=2) of 0.285 um
# tracks, so on each layer pins are >=4 tracks apart after track snapping;
# the pin block is centred in the segment.
proc assign_pins_on_segment {plist side layer a b} {
    set trk 0.285
    set n [llength $plist]
    lassign $a ax ay ; lassign $b bx by
    set L [expr hypot($bx-$ax, $by-$ay)]
    set k [expr max(2, int(floor($L / $n / $trk)))]
    set step [expr $k * $trk]
    set off [expr ($L - ($n-1)*$step) / 2.0]
    set ux [expr ($bx-$ax)/$L] ; set uy [expr ($by-$ay)/$L]
    set i 0
    foreach p $plist {
        set d [expr $off + $i*$step]
        editPin -pin $p -layer [lindex $layer [expr $i % 2]] -assign [list [expr $ax + $d*$ux] [expr $ay + $d*$uy]] \
                -pinWidth 0.14 -pinDepth 0.56 -fixedPin 1 -snap TRACK
        incr i
    }
}

# soft guides: one instance group per tile (router + nic + cpu)
proc tile_guides {} {
    set core [lindex [dbGet top.fPlan.coreBox] 0]
    lassign $core cx1 cy1 cx2 cy2
    set tw [expr ($cx2-$cx1)/4.0]
    set th [expr ($cy2-$cy1)/4.0]
    foreach n [node_list] {
        set y [string index $n 0]
        set x [string index $n 1]
        set gx1 [expr $cx1 + $x*$tw] ; set gx2 [expr $gx1 + $tw]
        set gy1 [expr $cy1 + $y*$th] ; set gy2 [expr $gy1 + $th]
        createInstGroup tile_$n -guide $gx1 $gy1 $gx2 $gy2
        foreach h [list cpu_$n nic_$n] { addInstToInstGroup tile_$n $h }
        # router: mesh was ungrouped in synthesis -> its hier inst is mesh_node<n> or mesh/node<n>
        foreach cand [list mesh_node$n mesh/node$n] {
            if {[dbGet -e top.hInst.hInsts.name $cand] ne ""} { addInstToInstGroup tile_$n $cand }
        }
    }
}

# Power grid (hierarchical, sized by static IR analysis, scripts/ir_solve.py):
#   ring    : 20 um vdd/gnd, metal9 (H) / metal10 (V)   (supply entry, fed from the periphery)
#   global  : metal10 (V) + metal9 (H) stripes, 14 um wide, vdd+gnd pair every 40 um
#             (35% of each top layer per net), M10<->M9 vias at every crossing
#   bumps   : flip-chip area-array power bumps modelled as 12x12 um vdd/gnd PG
#             pins on the M10 straps, ~200 um pitch (out/pg_bumps.txt)
#   local   : metal6 (V) stripes, 1.2 um, vdd+gnd pair every 20 um;
#             M9 -> M6 stacked vias at M9 x M6 crossings,
#             M6 -> M1 stacked vias at every follow-pin rail crossing
#   rails   : metal1 follow-pins
# Wide M9/M10 straps never stack straight down to M1, so M2-M8 routing
# tracks are only blocked under the narrow M6 straps.
proc build_pdn {} {
    globalNetConnect vdd -type pgpin -pin vdd -inst * -override
    globalNetConnect gnd -type pgpin -pin gnd -inst * -override
    globalNetConnect vdd -type tiehi
    globalNetConnect gnd -type tielo

    addRing -nets {vdd gnd} -type core_rings -follow core -center 1 \
            -layer {top metal9 bottom metal9 left metal10 right metal10} \
            -width 20 -spacing 3 -offset 3

    # local M6 straps first (they own the stacked vias down to the M1 rails)
    setAddStripeMode -reset
    setAddStripeMode -stacked_via_bottom_layer metal1 -stacked_via_top_layer metal6
    addStripe -nets {vdd gnd} -layer metal6 -direction vertical \
              -width 1.2 -spacing 1.0 -set_to_set_distance 20 -start_offset 9

    # global M9 straps: vias down to the M6 straps only
    setAddStripeMode -reset
    setAddStripeMode -stacked_via_bottom_layer metal6 -stacked_via_top_layer metal9
    addStripe -nets {vdd gnd} -layer metal9 -direction horizontal \
              -width 14 -spacing 4 -set_to_set_distance 40 -start_offset 8

    # global M10 straps: vias to M9 only
    setAddStripeMode -reset
    setAddStripeMode -stacked_via_bottom_layer metal9 -stacked_via_top_layer metal10
    addStripe -nets {vdd gnd} -layer metal10 -direction vertical \
              -width 14 -spacing 4 -set_to_set_distance 40 -start_offset 8

    add_power_bumps 200

    # M1 follow-pin rails; they connect to the M6 straps (stacked vias) and the ring
    sroute -connect {corePin} -nets {vdd gnd} -corePinTarget {ring stripe} \
           -allowJogging 0 -allowLayerChange 1 -layerChangeRange {metal1 metal6} \
           -crossoverViaLayerRange {metal1 metal6} -targetViaLayerRange {metal1 metal6}
}

# Area-array power bumps: a vdd/gnd PG pin on the M10 straps every ~pitch um.
# vdd and gnd bumps alternate in a checkerboard; the list feeds ir_solve.py.
proc add_power_bumps {pitch} {
    file mkdir out
    set fp [open out/pg_bumps.txt w]
    lassign [lindex [dbGet top.fPlan.coreBox] 0] cx1 cy1 cx2 cy2
    foreach net {vdd gnd} {
        set xs {}
        foreach w [dbGet [dbGet -p top.nets.name $net].sWires] {
            if {[dbGet $w.layer.name] eq "metal10" && [dbGet $w.shape] eq "stripe"} {
                lassign [lindex [dbGet $w.box] 0] x1 y1 x2 y2
                lappend xs [expr ($x1+$x2)/2.0]
            }
        }
        set xs [lsort -real $xs]
        set step [expr max(1, int(round($pitch / 40.0)))]
        set ix 0
        for {set i [expr {$net eq "vdd" ? 0 : $step/2}]} {$i < [llength $xs]} {incr i $step} {
            set x [lindex $xs $i]
            set iy 0
            for {set y [expr $cy1 + $pitch/2.0 + (($ix % 2) ? $pitch/2.0 : 0)]} {$y < $cy2 - 20} {set y [expr $y + $pitch]} {
                createPGPin ${net}_bump_${ix}_${iy} -net $net -geom metal10 [expr $x-6] [expr $y-6] [expr $x+6] [expr $y+6]
                puts $fp "$net $x $y"
                incr iy
            }
            incr ix
        }
    }
    close $fp
}
