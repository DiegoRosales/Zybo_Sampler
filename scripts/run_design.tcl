#####################
## Run design file ##
#####################
set pack             0
set integ            0
set implement        0
set burn_bitfile     0
set skip_project_gen 0
set export_ws        0
set launch_sdk       0

source scripts/common_variables.tcl

if { $argc > 0 } {
    switch [lindex $argv 0] {
        pack {
            set pack 1
        }
        integ {
            set integ 1
        } 
        integ_impl {
            set integ     1
            set implement 1
        }         
        integ_all {
            set integ            1
            set implement        1
            set burn_bitfile     1
            set export_ws        1
        }         
        all {
            set pack             1
            set integ            1
            set implement        1
            set burn_bitfile     1
            set export_ws        1
        }
        all_update {
            set pack             1
            set integ            1
            set implement        1
            set burn_bitfile     0
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

if { [file exists ${results_dir}] == 0} {
    puts "Creating Results Directory: ${results_dir}"
    file mkdir ${results_dir}
}

if { [file exists ${generated_ip_path}] == 0} {
    puts "Creating Generated IP Directory: ${generated_ip_path}"
    file mkdir ${generated_ip_path}
}

if { $pack == 1 } {
    puts "Running the Pack IP Flow..."
    source scripts/pack/create_packaged_ip.tcl
}

if { $integ == 1 } {
    puts "Running the Design Integration Flow..."
    source scripts/integ/create_integrated_design.tcl
}