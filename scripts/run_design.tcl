#####################
## Run design file ##
#####################
set pack             0
set integ            0
set burn_bitfile     0
set skip_project_gen 0

if { $argc > 0 } {
    if { [lindex $argv 0] == "pack" } {
        set pack 1
    } elseif { [lindex $argv 0] == "integ" } {
        set integ 1
        set burn_bitfile     1
        set skip_project_gen 0
    } elseif { [lindex $argv 0] == "all" } {
        set pack 1
        set integ 1
    } elseif { [lindex $argv 0] == "burn_only" } {
        set integ 1
        set skip_project_gen 1
        set burn_bitfile     1
    }
}

if { $pack == 1 } {
    puts "Running the Pack IP Flow..."
    source scripts/create_packaged_ip.tcl
}

if { $integ == 1 } {
    puts "Running the Design Integration Flow..."
    source scripts/create_integrated_design.tcl
}