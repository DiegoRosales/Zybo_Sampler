## Generate all xilinx IPs of a given list of TCL scripts
proc generate_xilinx_ips_tcl {args} {
    array set my_arglist {
        "ip_list"           {"store"         ""       "optional"   0}
        "core_info"         {"store"         ""       "required"   0}
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

    if {$parsed_args(ip_list) != ""} {
        if {![file exists $parsed_args(ip_list)]} {
            puts "ERROR: IP Filelist doesn't exist: $parsed_args(ip_list)"
            return 1
        }
    }

    ## Override the destination directory
    if {$parsed_args(dest_dir) != ""} {
        set generated_ip_path $parsed_args(dest_dir)
    } else {
        puts "ERROR: Please specify the destination directory"
        return 1
    }

    ######################
    set xilinx_ip [proj_utils::extract_from_all_cores -cores $parsed_args(core_info) -variable xilinx_ip -debug]

    ## Get all the TCL IPs
    set tcl_list ""
    foreach {ip ip_info} $xilinx_ip {
        if {[dict get $ip_info type] == "tcl"} {
            lappend tcl_list $ip_info
        }
    }

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
        set ip_name                  ""
        set ip_version               ""
        set ip_vendor                ""
        set ip_library               ""
        set component_name           ""
        set configuration_parameters ""
        set error                    0

        set tcl_path        [dict get $ip src]

        # Get the optional variables
        if {[dict exists $ip vars]} {
            set tcl_vars        [dict get $ip vars]
            foreach {name value} $tcl_vars {
                puts "Setting $name = $value"
                set $name $value
            }
        }

        puts "sourcing $tcl_path ..."
        source $tcl_path
        set component_name  [dict get $ip component_name]

        if { $generated_ip_path == "" } {
            puts "ERROR: Please define generated_ip_path for IP $tcl_path"
            set error 1
        }
        if { $ip_name == "" } {
            puts "ERROR: Please define ip_name for IP $tcl_path"
            set error 1
        }
        if { $ip_version == "" } {
            puts "ERROR: Please define ip_version for IP $tcl_path"
            set error 1
        }
        if { $ip_vendor == "" } {
            puts "ERROR: Please define ip_vendor for IP $tcl_path"
            set error 1
        }
        if { $ip_library == "" } {
            puts "ERROR: Please define ip_library for IP $tcl_path"
            set error 1
        }
        if { $component_name == "" } {
            puts "ERROR: Please define component_name for IP $tcl_path"
            set error 1
        }
        if { $configuration_parameters == "" } {
            puts "ERROR: Please define configuration_parameters for IP $tcl_path"
            set error 1
        }

        if {$error == 0} {
            generate_new_ip  -ip_path        ${generated_ip_path} \
                             -ip_name        $ip_name \
                             -ip_version     $ip_version \
                             -ip_vendor      $ip_vendor \
                             -ip_library     $ip_library \
                             -component_name $component_name \
                             -ip_parameters  $configuration_parameters \
                             -output         generated_ip
            lappend xilinx_ip_file_list  [dict get $generated_ip xci_path]
            lappend xilinx_ip_runs       [dict get $generated_ip ip_run]
        } else {
            puts "ERROR: There was an error while trying to generate the IP ${tcl_path}"
        }
        # Get the optional variables
        if {[dict exists $ip vars]} {
            set tcl_vars        [dict get $ip vars]
            foreach {name value} $tcl_vars {
                puts "Unsetting $name"
                unset $name
            }
        }

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
proc generate_new_ip {args} {
    array set my_arglist {
        "ip_path"         {"store"  ""  "required"   0}
        "ip_name"         {"store"  ""  "required"   0}
        "ip_version"      {"store"  ""  "required"   0}
        "ip_vendor"       {"store"  ""  "required"   0}
        "ip_library"      {"store"  ""  "required"   0}
        "component_name"  {"store"  ""  "required"   0}
        "ip_parameters"   {"store"  ""  "required"   0}
        "output"          {"store"  ""  "required"   0}
    }

    set status [arg_parser my_arglist parsed_args args]

    if {$status != 0} {
        puts "ERROR: There was an error processing the arguments"
        return 1
    }

    ######################

    set ip_path        $parsed_args(ip_path)
    set ip_name        $parsed_args(ip_name)
    set ip_version     $parsed_args(ip_version)
    set ip_vendor      $parsed_args(ip_vendor)
    set ip_library     $parsed_args(ip_library)
    set component_name $parsed_args(component_name)
    set ip_parameters  $parsed_args(ip_parameters)
    set ip_parameters  $parsed_args(ip_parameters)
    ## Upper Variables
    upvar 1 $parsed_args(output) output
    ## IP Variables
    set ip_xci_path ${ip_path}/${component_name}/${component_name}.xci
    set ip_dcp_path ${ip_path}/${component_name}/${component_name}.dcp
    set ip_run "none"

    ## Create the directory if it doesn't exist
    if {![file exists $ip_path]} {
        file mkdir $ip_path
    }

    ## If it doesn't exist, create it
    if { [file exists ${ip_dcp_path}] == 0 } {
        ## Step 1 - Create the IP if it doesn't exist
        if { [file exists ${ip_xci_path}] == 0 } {
            ## Step 1.1 - Create the IP
            puts "Running create_ip -name ${ip_name} -vendor ${ip_vendor} -library ${ip_library} -version ${ip_version} -module_name ${component_name} -dir ${ip_path}"
            create_ip -name ${ip_name} -vendor ${ip_vendor} -library ${ip_library} -version ${ip_version} -module_name ${component_name} -dir ${ip_path}

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

    dict set output "xci_path" [file normalize ${ip_xci_path}]
    dict set output "ip_run"   ${ip_run}
}