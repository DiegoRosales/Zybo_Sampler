## Generate all xilinx IPs of a given list of TCL scripts
proc generate_xilinx_ips_tcl {args} {
    array set my_arglist {
        "ip_list"           {"store"         ""       "required"   0}
        "part_number"       {"store"         ""       "required"   0}
        "dest_dir"          {"store"         ""       "required"   0}
        "output_list"       {"store"         ""       "optional"   0}
        "override"          {"store_true"    0        "optional"   0}
        "force"             {"store_true"    0        "optional"   0}
    }

    set status [arg_parser my_arglist parsed_args args]

    if {$status != 0} {
        puts "ERROR: There was an error processing the arguments"
        return 1
    }

    ######################

    if {$parsed_args(output_list) == ""} {
        puts "ERROR: Please provide an output list"
        return 1
    }

    upvar 1 $parsed_args(output_list) output_list

    if {[info exists output] && $parsed_args(override) == 0} {
        puts "ERROR: Output variable already exists $parsed_args(output_list). Use -override to override it"
        return 1
    }

    if {![file exists $parsed_args(ip_list)]} {
        puts "ERROR: IP Filelist doesn't exist: $parsed_args(ip_list)"
        return 1
    }

    ## Override the destination directory
    if {$parsed_args(dest_dir) != ""} {
        set generated_ip_path $parsed_args(dest_dir)
    } else {
        puts "ERROR: Please specify the destination directory"
        return 1
    }

    ######################
    ## Parse json file
    parse_json_cfg -cfg_file $parsed_args(ip_list) -output tcl_filelist -override -debug
    
    if {![dict exists $tcl_filelist xilinx_ip_tcl_list]} {
        puts "ERROR: No XCI files inside $parsed_args(ip_list)"
        return 1
    }

    set tcl_list [dict get $tcl_filelist xilinx_ip_tcl_list]


    ######################
    ## Variables to be set by the TCL scripts
    set xilinx_ip_file_list    ""
    set xilinx_ip_runs         ""
    set xilinx_ip_project_name "xilinx_ip_gen"

    ## Step 0 - Create a dummy project
    ## Check if project exists
    if {[file exist ${generated_ip_path}] == 0} {
        file mkdir ${generated_ip_path}
    }

    create_project  "xilinx_ip_gen" \
                    ${generated_ip_path} \
                    -part $parsed_args(part_number) \
                    -force


    ## Step 1 - Source the TCL scripts to generate 
    foreach ip $tcl_list {
        set ip_path [subst ${ip}]
        puts "sourcing ${ip_path} ..."
        source ${ip_path}
    }

    ## Step 2 - Launch all IP runs
    foreach ip_run ${xilinx_ip_runs} {
       if { ${ip_run} != "none" } {
            puts "launching ${ip_run} ..."
            launch_runs ${ip_run}
        }
    }

    ## Step 3 - Wait for the runs to finish
    foreach ip_run ${xilinx_ip_runs} {
        if { ${ip_run} != "none" } {
            puts "Waiting on ${ip_run}"
            wait_on_run ${ip_run}
            puts "IP Run ${ip_run} is done!"
        }
    }

    ## Write the filelist
    write_filelist -filelist    $xilinx_ip_file_list \
                   -description "Synthesis XCI from TCL filelist" \
                   -list_name   "syn_tcl_xci_filelist" \
                   -output      "${generated_ip_path}/syn_tcl_xci_filelist.f.json"

    set output_list ${generated_ip_path}/syn_tcl_xci_filelist.f.json

    ## Step 4 - Close the project
    close_project
}

## Generate Xilinx IPs from XCI files
proc generate_xilinx_ips_xci {args} {
    array set my_arglist {
        "ip_list"           {"store"         ""       "required"   0}
        "part_number"       {"store"         ""       "required"   0}
        "dest_dir"          {"store"         ""       "required"   0}
        "board_part"        {"store"         ""       "optional"   0}
        "output_list"       {"store"         ""       "optional"   0}
        "override"          {"store_true"    0        "optional"   0}
        "force"             {"store_true"    0        "optional"   0}
    }

    set status [arg_parser my_arglist parsed_args args]

    if {$status != 0} {
        puts "ERROR: There was an error processing the arguments"
        return 1
    }

    ######################

    if {$parsed_args(output_list) == ""} {
        puts "ERROR: Please provide an output list"
        return 1
    }

    upvar 1 $parsed_args(output_list) output_list

    if {[info exists output] && $parsed_args(override) == 0} {
        puts "ERROR: Output variable already exists $parsed_args(output_list). Use -override to override it"
        return 1
    }

    if {![file exists $parsed_args(ip_list)]} {
        puts "ERROR: IP Filelist doesn't exist: $parsed_args(ip_list)"
        return 1
    }

    ## Override the destination directory
    if {$parsed_args(dest_dir) != ""} {
        set generated_ip_path $parsed_args(dest_dir)
    } else {
        puts "ERROR: Please specify the destination directory"
        return 1
    }

    ######################
    ## Parse json file
    parse_json_cfg -cfg_file $parsed_args(ip_list) -output xci_filelist -override -debug
    
    if {![dict exists $xci_filelist integ_gen_xci_filelist]} {
        puts "ERROR: No XCI files inside $parsed_args(ip_list)"
        return 1
    }

    set xci_list [dict get $xci_filelist integ_gen_xci_filelist]

    ######################
    ## Variables to be set by the TCL scripts
    set xilinx_ip_file_list    ""
    set xilinx_ip_runs         ""
    set xilinx_ip_project_name "xilinx_ip_gen"

    ## Step 0 - Create a dummy project
    ## Check if project exists
    if {[file exist ${generated_ip_path}] == 0} {
        file mkdir ${generated_ip_path}
    }

    create_project  "xilinx_ip_gen" \
                    ${generated_ip_path} \
                    -part $parsed_args(part_number) \
                    -force

    if {$parsed_args(board_part) != ""} {
        puts "Setting board part as $parsed_args(board_part)"
        set_property board_part $parsed_args(board_part) [current_project]
    }

    ## Step 1 - Source the TCL scripts to generate 
    foreach ip $xci_list {
        set new_ip [add_files -force -norecurse ${ip}]
        generate_target all [get_files ${new_ip}]
        lappend xilinx_ip_file_list ${new_ip}
    }

    foreach ip [get_files -filter {FILE_TYPE == IP && GENERATE_SYNTH_CHECKPOINT == True}] {
        puts "Generating synth checkpoint for $ip"
        lappend xilinx_ip_runs [create_ip_run $ip]
    }

    ## Step 2 - Launch all IP runs
    foreach ip_run ${xilinx_ip_runs} {
       if { ${ip_run} != "" } {
            puts "launching ${ip_run} ..."
            launch_runs ${ip_run}
        }
    }

    ## Step 3 - Wait for the runs to finish
    foreach ip_run ${xilinx_ip_runs} {
        if { ${ip_run} != "" } {
            puts "Waiting on ${ip_run}"
            wait_on_run ${ip_run}
            puts "IP Run ${ip_run} is done!"
        }
    }

    ## Write the filelist
    write_filelist -filelist    $xilinx_ip_file_list \
                   -description "Synthesis XCI filelist" \
                   -list_name   "syn_xci_filelist" \
                   -output      "${generated_ip_path}/syn_xci_filelist.f.json"

    set output_list ${generated_ip_path}/syn_xci_filelist.f.json
    ## Step 4 - Close the project
    close_project
}

####################################
## PROCEDURE TO GENERATE A NEW IP ##
## AND RETURN THE IP RUN FOR      ##
## SYNTHESIS                      ##
####################################
proc generate_new_ip {path ip_name ip_version ip_vendor ip_library component_name ip_parameters} {
    ## Upper Variables
    upvar xilinx_ip_file_list generated_ip_file_list
    upvar xilinx_ip_runs      ip_runs
    ## IP Variables
    set ip_xci_path ${path}/${component_name}/${component_name}.xci
    set ip_dcp_path ${path}/${component_name}/${component_name}.dcp
    set ip_run "none"

    ## If it doesn't exist, create it
    if { [file exists ${ip_dcp_path}] == 0 } {
        ## Step 1 - Create the IP if it doesn't exist
        if { [file exists ${ip_xci_path}] == 0 } {
            ## Step 1.1 - Create the IP
            create_ip -name ${ip_name} -vendor ${ip_vendor} -library ${ip_library} -version ${ip_version} -module_name ${component_name} -dir ${path}

            ## Step 1.2 - Configure the IP
            set_property -dict ${ip_parameters} [get_ips ${component_name}]

            ## Step 1.3 - Generate the collateral files
            generate_target all  [get_files ${ip_xci_path}]
        } else {
            ## Import the IP if it already exists
            add_files ${ip_xci_path}
        }

        ## Step 2 - Create the IP run for synthesis
        set ip_run [create_ip_run [get_files ${ip_xci_path}]]
        puts ${ip_run}
    } else {
        ## Import the IP if it already exists
        add_files ${ip_xci_path}
    }

    ## Append the .xci to the filelist
    set generated_ip_file_list [lappend generated_ip_file_list [file normalize ${ip_xci_path}]]
    ## Append the IP Run
    set ip_runs [ lappend ip_runs ${ip_run}]

    return ${ip_run}
}