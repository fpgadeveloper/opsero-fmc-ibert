# Opsero Electronic Design Inc. (C) 2025
#
# IBERT helper: opens Vivado Hardware Manager, creates per-lane SIO links for
# 1:1 external loopback, runs 2D eye scans, and writes per-lane CSVs plus a
# link_status.json summary. Called from scripts/ibert_test.py as:
#
#   vivado -mode batch -source scripts/ibert_helper.tcl \
#          -tclargs <run_context.json> <results_dir>
#
# The PDI must already be programmed. This script only does the IBERT side.
#
# Per-channel property-name caveat (Versal GTY/GTYP):
#   Each SIO TX/RX/link object has its property names prefixed with the
#   channel number, e.g. CH0_TX_PATTERN on Quad_201.CH_0, CH1_TX_PATTERN on
#   Quad_201.CH_1, CH2_TX_PATTERN on Quad_201.CH_2, etc. The pass-through
#   properties in data.json can either give the full name (e.g.
#   "CH0_TX_DIFF_CTRL") or just the suffix (e.g. "TX_DIFF_CTRL") — this script
#   resolves the correct per-channel name at set time.

if { $argc != 2 } {
    puts "ERROR: usage: ibert_helper.tcl <run_context.json> <results_dir>"
    exit 1
}
set ctx_path [lindex $argv 0]
set out_dir  [lindex $argv 1]

# ---------------- JSON reader (tcllib json is bundled with Vivado) ----------------
if { [catch { package require json } err] } {
    puts "ERROR: Tcl json package not available in this Vivado: $err"
    exit 1
}

proc read_file_text {path} {
    set fd [open $path r]
    set txt [read $fd]
    close $fd
    return $txt
}

proc dict_get_default {d key default} {
    if { [dict exists $d $key] } { return [dict get $d $key] }
    return $default
}

# Resolve a property name on an object. Accepts a suffix like "TX_PATTERN" or
# a full name like "CH0_TX_PATTERN". Returns the full name that exists on the
# object, or "" if none match.
proc resolve_prop_name {obj name} {
    set all [list_property $obj]
    # Direct match first
    if { [lsearch -exact $all $name] >= 0 } { return $name }
    # Suffix match: look for *_<name>
    foreach p $all {
        if { [string match "CH?_${name}"  $p] } { return $p }
        if { [string match "CH??_${name}" $p] } { return $p }
    }
    # Case-insensitive / contains fallback
    set up_name [string toupper $name]
    foreach p $all {
        if { [string toupper $p] eq $up_name } { return $p }
        if { [string match -nocase "CH?_${name}"  $p] } { return $p }
        if { [string match -nocase "CH??_${name}" $p] } { return $p }
    }
    return ""
}

proc set_resolved_prop {obj name value} {
    set resolved [resolve_prop_name $obj $name]
    if { $resolved eq "" } {
        return [list 0 "property '$name' not found on $obj"]
    }
    if { [catch { set_property $resolved $value $obj } err] } {
        return [list 0 "set_property $resolved=$value failed: $err"]
    }
    return [list 1 $resolved]
}

# ---------------- context ----------------
if { ![file isfile $ctx_path] } {
    puts "ERROR: run_context.json not found: $ctx_path"
    exit 1
}
set ctx [::json::json2dict [read_file_text $ctx_path]]

set target         [dict_get_default $ctx target         "unknown"]
set num_lanes      [dict_get_default $ctx num_lanes      8]
set part           [dict_get_default $ctx part           ""]
set tx_pattern     [dict_get_default $ctx tx_pattern     "PRBS 31"]
set rx_pattern     [dict_get_default $ctx rx_pattern     "PRBS 31"]
set settle_sec     [dict_get_default $ctx settle_sec     10]
set scan_cfg       [dict_get_default $ctx scan           [dict create]]
set tx_props       [dict_get_default $ctx tx_properties  [dict create]]
set rx_props       [dict_get_default $ctx rx_properties  [dict create]]

set hor_inc   [dict_get_default $scan_cfg horizontal_increment "2"]
set ver_inc   [dict_get_default $scan_cfg vertical_increment   "2"]
set hor_range [dict_get_default $scan_cfg horizontal_range     "-0.500 UI to 0.500 UI"]
set ver_range [dict_get_default $scan_cfg vertical_range       "100%"]
set dwell_ber [dict_get_default $scan_cfg dwell_ber            "1e-6"]

puts "== ibert_helper =="
puts "  target         : $target"
puts "  part           : $part"
puts "  num_lanes      : $num_lanes"
puts "  tx_pattern     : $tx_pattern"
puts "  rx_pattern     : $rx_pattern"
puts "  settle_sec     : $settle_sec"
puts "  scan           : hor_inc=$hor_inc ver_inc=$ver_inc dwell_ber=$dwell_ber"
puts "  scan range     : horz='$hor_range' vert='$ver_range'"
puts "  out_dir        : $out_dir"

# ---------------- connect to hardware ----------------
puts "\n-- Opening hardware manager --"
open_hw_manager
if { [catch { connect_hw_server -quiet } err] } {
    puts "ERROR: connect_hw_server failed: $err"
    close_hw_manager
    exit 1
}

set targets [get_hw_targets]
if { [llength $targets] == 0 } {
    puts "ERROR: no hw_targets visible. Is the JTAG cable connected?"
    disconnect_hw_server
    close_hw_manager
    exit 1
}
current_hw_target [lindex $targets 0]
puts "hw_target   : [current_hw_target]"

open_hw_target

# ---- select the FPGA device (skip arm_dap and similar debug access ports) ----
# Versal targets expose both arm_dap_0 and xcvc*/xcve*; we want the FPGA.
set chosen_dev ""
set fpga_prefixes {xcv xczu xc7z xc7v xcku xcvu}
foreach dev [get_hw_devices] {
    set dev_part [string tolower [get_property PART $dev]]
    foreach pfx $fpga_prefixes {
        if { [string match "${pfx}*" $dev_part] } {
            # If the design specifies a part, prefer an exact match.
            if { $part ne "" && [string match "${part}*" [get_property PART $dev]] } {
                set chosen_dev $dev
                break
            }
            # Otherwise remember the first FPGA we see.
            if { $chosen_dev eq "" } { set chosen_dev $dev }
        }
    }
    if { $chosen_dev ne "" && $part ne "" && [string match "${part}*" [get_property PART $chosen_dev]] } { break }
}
if { $chosen_dev eq "" } {
    puts "ERROR: no FPGA hw_device found. Available devices:"
    foreach dev [get_hw_devices] {
        puts "  $dev  PART=[get_property PART $dev]"
    }
    close_hw_target
    disconnect_hw_server
    close_hw_manager
    exit 1
}
current_hw_device $chosen_dev
puts "hw_device   : $chosen_dev ([get_property PART $chosen_dev])"

refresh_hw_device -quiet $chosen_dev
# Give the SIO cores a moment to enumerate
after 2000

# ---------------- enumerate SIO GTs ----------------
set all_gts [get_hw_sio_gts]
set all_gts [lsort -dictionary $all_gts]
puts "\n-- SIO GTs found: [llength $all_gts] --"
foreach gt $all_gts { puts "  $gt" }

if { [llength $all_gts] < $num_lanes } {
    puts "ERROR: expected $num_lanes GT channels, found [llength $all_gts]"
    close_hw_target
    disconnect_hw_server
    close_hw_manager
    exit 1
}
if { [llength $all_gts] > $num_lanes } {
    puts "NOTE: [llength $all_gts] GTs available, using first $num_lanes"
}
set lane_gts [lrange $all_gts 0 [expr {$num_lanes - 1}]]

# ---------------- create one SIO link per lane (1:1 external loopback) ----------------
puts "\n-- Creating SIO links (1:1 external loopback) --"
set lane_objs [list]   ;# list of dicts: lane, gt, tx, rx, link
set lane_idx 0
foreach gt $lane_gts {
    set tx [lindex [get_hw_sio_txs -of_objects $gt] 0]
    set rx [lindex [get_hw_sio_rxs -of_objects $gt] 0]
    if { $tx eq "" || $rx eq "" } {
        puts "WARNING: GT $gt has no TX or RX SIO object; skipping lane $lane_idx"
        incr lane_idx
        continue
    }
    set link [create_hw_sio_link -description "lane_$lane_idx" $tx $rx]
    puts [format "  lane %02d: %s" $lane_idx $gt]
    lappend lane_objs [dict create lane $lane_idx gt $gt tx $tx rx $rx link $link]
    incr lane_idx
}

# ---------------- set TX/RX patterns ----------------
# Look TX/RX up through the link object. In Vivado HW Manager these return
# the same SIO objects as get_hw_sio_txs -of_objects $gt, but using the link
# matches the idiom that Vivado's own examples use.
puts "\n-- Setting TX/RX patterns --"
for {set i 0} {$i < [llength $lane_objs]} {incr i} {
    set obj [lindex $lane_objs $i]
    set lane [dict get $obj lane]
    set link [dict get $obj link]
    set tx [lindex [get_hw_sio_txs -of_objects $link] 0]
    set rx [lindex [get_hw_sio_rxs -of_objects $link] 0]
    dict set obj tx $tx
    dict set obj rx $rx
    lset lane_objs $i $obj

    set r [set_resolved_prop $tx "TX_PATTERN" $tx_pattern]
    if { [lindex $r 0] == 0 } {
        puts "  lane $lane: TX_PATTERN: [lindex $r 1]"
    } else {
        puts [format "  lane %02d: TX_PATTERN <- %s (via %s)" $lane $tx_pattern [lindex $r 1]]
    }
    set r [set_resolved_prop $rx "RX_PATTERN" $rx_pattern]
    if { [lindex $r 0] == 0 } {
        puts "  lane $lane: RX_PATTERN: [lindex $r 1]"
    } else {
        puts [format "  lane %02d: RX_PATTERN <- %s (via %s)" $lane $rx_pattern [lindex $r 1]]
    }
}

# ---------------- apply pass-through TX/RX properties ----------------
proc apply_props {label props obj} {
    dict for {key value} $props {
        set r [set_resolved_prop $obj $key $value]
        if { [lindex $r 0] == 0 } {
            puts "  $label: $key: [lindex $r 1]"
        } else {
            puts "  $label: $key -> [lindex $r 1] = $value"
        }
    }
}

if { [dict size $tx_props] > 0 || [dict size $rx_props] > 0 } {
    puts "\n-- Applying pass-through TX/RX properties --"
    foreach obj $lane_objs {
        set lane [dict get $obj lane]
        apply_props "lane $lane tx" $tx_props [dict get $obj tx]
        apply_props "lane $lane rx" $rx_props [dict get $obj rx]
    }
}

commit_hw_sio [get_hw_sio_links]

# ---------------- settle window ----------------
# Two things we deliberately do NOT do here, both of which I proved experimentally
# will knock the PRBS checker out of lock on the versal_ibert_bridge IP used by
# these designs:
#
#   1. Toggle RESET_RX. Pulsing the link-level RX reset causes the PMA to drop
#      CDR and restart CTLE/DFE adaptation. At 28 Gbps those adaptive filters
#      take a long time to reconverge and most lanes don't recover cleanly.
#
#   2. Write to RX_PRBS_RESET.ERR_CNT / RX_PRBS_RESET.BER. Despite the name,
#      this is effectively a full PRBS block reset on this IP — after a commit
#      every lane I touched went to "Not locked" and stayed there.
#
# Instead we rely on the RX locking when the TX/RX patterns are configured
# above. The first measurement window therefore reports the *cumulative*
# error count since the pattern write, which includes the initial PRBS sync
# transient. The raw count is not useful for BER; the accompanying BER field
# (errors / bits_received), which Vivado computes for us, is the meaningful
# metric and it asymptotically approaches the real value the longer the
# settle_sec window is. For a cleaner measurement, increase ibert_params.settle_sec
# in config/data.json.
puts "\n-- Waiting ${settle_sec}s for PRBS to sync and settle --"
after [expr {$settle_sec * 1000}]
refresh_hw_sio -quiet [get_hw_sio_links]

# ---------------- link / PRBS status ----------------
puts "\n-- Link status --"
for {set i 0} {$i < [llength $lane_objs]} {incr i} {
    set obj [lindex $lane_objs $i]
    set link [dict get $obj link]
    set rx   [dict get $obj rx]
    set locked "?"
    set ber    "?"
    set errcnt "?"
    set status "?"
    set locked_prop [resolve_prop_name $rx "RX_PRBS_LOCKED"]
    if { $locked_prop ne "" } { catch { set locked [get_property $locked_prop $rx] } }
    set ber_prop [resolve_prop_name $rx "RX_PRBS_BER"]
    if { $ber_prop ne "" }    { catch { set ber    [get_property $ber_prop    $rx] } }
    set err_prop [resolve_prop_name $rx "RX_PRBS_ERR_CNT"]
    if { $err_prop ne "" }    { catch { set errcnt [get_property $err_prop    $rx] } }
    set st_prop [resolve_prop_name $rx "RX_STATUS"]
    if { $st_prop ne "" }     { catch { set status [get_property $st_prop     $rx] } }

    dict set obj link_prbs_locked $locked
    dict set obj link_prbs_ber    $ber
    dict set obj link_prbs_errors $errcnt
    dict set obj link_status      $status
    lset lane_objs $i $obj
    puts [format "  lane %02d: prbs_locked=%s ber=%s err_cnt=%s rx_status=%s" \
        [dict get $obj lane] $locked $ber $errcnt $status]
}

# ---------------- create eye scans ----------------
puts "\n-- Creating eye scans --"
set scan_objs [list]
foreach obj $lane_objs {
    set lane [dict get $obj lane]
    set rx [dict get $obj rx]
    if { [catch { set scan [create_hw_sio_scan -description "lane_${lane}_eye" 2d_full_eye $rx] } err] } {
        puts "  lane $lane: create_hw_sio_scan failed: $err"
        continue
    }
    # Configure the scan. Scan objects do NOT get committed — the run command
    # pushes the config before starting the sweep.
    catch { set_property HORIZONTAL_INCREMENT $hor_inc    $scan }
    catch { set_property VERTICAL_INCREMENT   $ver_inc    $scan }
    catch { set_property HORIZONTAL_RANGE     $hor_range  $scan }
    catch { set_property VERTICAL_RANGE       $ver_range  $scan }
    catch { set_property DWELL                "BER"       $scan }
    catch { set_property DWELL_BER            $dwell_ber  $scan }
    lappend scan_objs [dict create lane $lane scan $scan]
}

puts "\n-- Running eye scans --"
set t0 [clock seconds]
foreach item $scan_objs {
    set lane [dict get $item lane]
    set scan [dict get $item scan]
    puts "  lane $lane: starting scan ..."
    if { [catch { run_hw_sio_scan $scan } err] } {
        puts "  lane $lane: run_hw_sio_scan failed: $err"
        continue
    }
    if { [catch { wait_on_hw_sio_scan $scan } err] } {
        puts "  lane $lane: wait_on_hw_sio_scan failed: $err"
        continue
    }
    set status "?"; catch { set status [get_property STATUS $scan] }
    set open_area "?"; catch { set open_area [get_property OPEN_AREA $scan] }
    set open_pct  "?"; catch { set open_pct  [get_property OPEN_PERCENTAGE $scan] }
    puts "  lane $lane: status=$status open_area=$open_area open_pct=$open_pct"
}
set elapsed [expr {[clock seconds] - $t0}]
puts "  total scan time: ${elapsed}s"

# ---------------- write CSV per lane + link_status.json ----------------
puts "\n-- Writing scan CSVs --"
set lane_json [list]
foreach item $scan_objs {
    set lane [dict get $item lane]
    set scan [dict get $item scan]
    set csv_name [format "lane_%02d.csv" $lane]
    set csv_path [file join $out_dir $csv_name]
    if { [catch { write_hw_sio_scan -force $csv_path $scan } err] } {
        puts "  lane $lane: write_hw_sio_scan failed: $err"
        set csv_name ""
    } else {
        puts "  lane $lane: wrote $csv_name"
    }

    set open_area "0"
    set open_pct  "0"
    set horz_open "0"
    set vert_open "0"
    catch { set open_area [get_property OPEN_AREA         $scan] }
    catch { set open_pct  [get_property OPEN_PERCENTAGE   $scan] }
    catch { set horz_open [get_property HORIZONTAL_OPENING $scan] }
    catch { set vert_open [get_property VERTICAL_OPENING   $scan] }

    set gt_name ""
    set link_status "unknown"
    set prbs_locked "unknown"
    set prbs_ber    "?"
    set prbs_errs   "?"
    foreach obj $lane_objs {
        if { [dict get $obj lane] == $lane } {
            set gt_name [dict get $obj gt]
            catch { set link_status [dict get $obj link_status] }
            catch { set prbs_locked [dict get $obj link_prbs_locked] }
            catch { set prbs_ber    [dict get $obj link_prbs_ber] }
            catch { set prbs_errs   [dict get $obj link_prbs_errors] }
            break
        }
    }
    lappend lane_json [dict create \
        lane $lane \
        gt $gt_name \
        tx_pattern $tx_pattern \
        rx_pattern $rx_pattern \
        link_status $link_status \
        prbs_locked $prbs_locked \
        prbs_ber $prbs_ber \
        prbs_errors $prbs_errs \
        open_area $open_area \
        open_percentage $open_pct \
        horizontal_opening $horz_open \
        vertical_opening $vert_open \
        csv $csv_name]
}

# Hand-serialise a small JSON document (avoids dependency on rdi::jsonify).
proc json_escape {s} {
    set s [string map { "\\" "\\\\" "\"" "\\\"" "\n" "\\n" "\r" "\\r" "\t" "\\t" } $s]
    return $s
}

# Pick a JSON value representation: numbers stay bare, anything else is quoted.
proc json_value {v} {
    if { $v eq "" } { return "\"\"" }
    if { [regexp {^-?[0-9]+(\.[0-9]+)?([eE][+-]?[0-9]+)?$} $v] } { return $v }
    return "\"[json_escape $v]\""
}

set status_json_path [file join $out_dir "link_status.json"]
set fd [open $status_json_path w]
puts $fd "\{"
puts $fd "  \"target\": \"[json_escape $target]\","
puts $fd "  \"part\": \"[json_escape $part]\","
puts $fd "  \"tx_pattern\": \"[json_escape $tx_pattern]\","
puts $fd "  \"rx_pattern\": \"[json_escape $rx_pattern]\","
puts $fd "  \"lanes\": \["
set last_idx [expr {[llength $lane_json] - 1}]
set idx 0
foreach lane $lane_json {
    set trailing [expr { $idx == $last_idx ? "" : "," }]
    puts $fd "    \{"
    puts $fd "      \"lane\": [dict get $lane lane],"
    puts $fd "      \"gt\": [json_value [dict get $lane gt]],"
    puts $fd "      \"tx_pattern\": [json_value [dict get $lane tx_pattern]],"
    puts $fd "      \"rx_pattern\": [json_value [dict get $lane rx_pattern]],"
    puts $fd "      \"link_status\": [json_value [dict get $lane link_status]],"
    puts $fd "      \"prbs_locked\": [json_value [dict get $lane prbs_locked]],"
    puts $fd "      \"prbs_ber\": [json_value [dict get $lane prbs_ber]],"
    puts $fd "      \"prbs_errors\": [json_value [dict get $lane prbs_errors]],"
    puts $fd "      \"open_area\": [json_value [dict get $lane open_area]],"
    puts $fd "      \"open_percentage\": [json_value [dict get $lane open_percentage]],"
    puts $fd "      \"horizontal_opening\": [json_value [dict get $lane horizontal_opening]],"
    puts $fd "      \"vertical_opening\": [json_value [dict get $lane vertical_opening]],"
    puts $fd "      \"csv\": [json_value [dict get $lane csv]]"
    puts $fd "    \}$trailing"
    incr idx
}
puts $fd "  \]"
puts $fd "\}"
close $fd
puts "Wrote $status_json_path"

# ---------------- cleanup ----------------
puts "\n-- Cleaning up --"
catch { remove_hw_sio_scan [get_hw_sio_scans] }
catch { remove_hw_sio_link [get_hw_sio_links] }
close_hw_target
disconnect_hw_server
close_hw_manager

puts "\n== ibert_helper done =="
exit 0
