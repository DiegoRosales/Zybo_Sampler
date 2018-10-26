#####################
## Run design file ##
#####################
set pack             0
set integ            0
set burn_bitfile     0
set skip_project_gen 0
set export_ws        0
set launch_sdk       0

if { $argc > 0 } {
    switch [lindex $argv 0] {
        pack {
            set pack 1
        }
        integ {
            set integ            1
            set burn_bitfile     1
            set skip_project_gen 0
        } 
        all {
            set pack  1
            set integ 1
        }
        burn_only {
            set integ            1
            set skip_project_gen 1
            set burn_bitfile     1
        } 
        export_ws {
            set integ            1
            set skip_project_gen 1
            set export_ws        1
        }
        launch_sdk {
            set integ            1
            set skip_project_gen 1
            set launch_sdk       1
        }
        default {
            puts "You didn't select any options"
        }
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