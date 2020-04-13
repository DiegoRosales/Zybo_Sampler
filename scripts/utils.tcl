##############################
## TCL utilities
##############################

proc lshift {inputlist} {
  # Summary :
  # Argument Usage:
  # Return Value:

  upvar $inputlist argv
  set arg  [lindex $argv 0]
  set argv [lrange $argv 1 end]
  return $arg
}

proc arg_parser { arg_list parsed_args args } {
    upvar $parsed_args  parsed_args_int
    upvar $arg_list     arg_list_int
    upvar $args         args_int

    set   required_list {}
    set   exit_status   0
    
    ## Fill defaults
    foreach arg_name [array names arg_list_int] {
        set default_value     [lindex $arg_list_int($arg_name) 1]
        set argument_req      [lindex $arg_list_int($arg_name) 2]

        if {$argument_req == "optional"} {
            set parsed_args_int($arg_name) $default_value
        } else {
            #puts "$arg_name is required"
            lappend required_list $arg_name
        }
    }

    ## Parse arguments
    set cur_arg_pos   1
    set curr_list_arg ""
    while { [llength $args_int] } {
        set arg           [lshift args_int]
        set found_new_arg 0

        puts "arg = $arg"

        if {$arg != ""} {
            switch -regexp $arg {
                ^-[a-zA-Z]+ {
                    if {$curr_list_arg == ""} {
                        set found_new_arg 1
                        set arg_name      [string range $arg 1 end]

                        ## Search for the argument in the argument list
                        if {[lsearch -exact [array names arg_list_int] "$arg_name"] != -1} {
                            set action        [lindex $arg_list_int($arg_name) 0]
                            #puts "$arg_name is in arg_list"
                            switch -exact -- $action {
                                store {
                                    set parsed_args_int($arg_name) [lshift args_int]
                                    #puts "$arg_name = $parsed_args_int($arg_name)"
                                }
                                store_true {
                                    set parsed_args_int($arg_name) 1
                                }
                                store_false {
                                    set parsed_args_int($arg_name) 0
                                }
                            }
                        }
                    }
                }

                ^--[a-zA-Z]+ {
                    if {$curr_list_arg == ""} {
                        set found_new_arg 1
                        set arg_name      [string range $arg 2 end]

                        ## Search for the argument in the argument list
                        if {[lsearch -exact [array names arg_list_int] "$arg_name"] != -1} {
                            set action        [lindex $arg_list_int($arg_name) 0]
                            #puts "$arg_name is in arg_list"
                            switch -exact -- $action {
                                store_list {
                                    set     curr_list_arg $arg_name
                                    puts    "Starting adding arguments for $curr_list_arg"
                                }
                                default {
                                    puts "WARNING: $arg_name is not of List type"
                                }
                            }
                        }
                    }
                }

                ^--$ {
                    puts "Finished adding arguments for $curr_list_arg"
                    set curr_list_arg ""
                    set found_new_arg 1
                }

                default {
                    set found_new_arg 0
                }
            }

            if {$found_new_arg == 0} {
                if {$curr_list_arg == ""} {
                    ## Check if this is a positional argument
                    set found_arg 0
                    foreach arg_name [array names arg_list_int] {
                        set argument_position [lindex $arg_list_int($arg_name) 3]
                        if {$argument_position == $cur_arg_pos} {
                            set parsed_args_int($arg_name) $arg
                            set found_arg 1
                            #puts "$arg_name = $parsed_args_int($arg_name)"
                            break
                        }
                    }

                    if {$found_arg == 0} {
                        puts "ERROR - Unknown argument $arg"
                        set exit_status 1
                    }
                } else {
                    lappend parsed_args_int($curr_list_arg) $arg
                }
            }
            
        incr cur_arg_pos
    }

    ## Check if there are missing
    #puts "Checking for missing arguments"
    foreach required_arg $required_list {
        #puts "Required arg is $required_arg"
        if {[lsearch -exact [array names parsed_args_int] "$required_arg"] == -1} {
            puts "ERROR: Missing argument $required_arg"
            set exit_status 1
        }
    }

    if {$exit_status != 0} {
        puts "ERROR: Argument parsing failed"
    }
    return $exit_status
}

## Generate all xilinx IPs of a given list of TCL scripts
proc generate_xilinx_ips_tcl {args} {
    array set my_arglist {
        "ip_list"           {"store"         ""       "required"   0}
        "part_number"       {"store"         ""       "required"   0}
        "dest_dir"          {"store"         ""       "required"   0}
        "force"             {"store_true"    0        "optional"   0}
    }

    set status [arg_parser my_arglist parsed_args args]

    if {$status != 0} {
        puts "ERROR: There was an error processing the arguments"
        return ""
    }

    ######################

    ## Override the destination directory
    if {$parsed_args(dest_dir) != ""} {
        set generated_ip_path $parsed_args(dest_dir)
    } else {
        puts "ERROR: Please specify the destination directory"
        return ""
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
    foreach ip $parsed_args(ip_list) {
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

    ## Step 4 - Close the project
    close_project

    return $xilinx_ip_file_list
}

## Generate Xilinx IPs from XCI files
proc generate_xilinx_ips_xci {args} {
    array set my_arglist {
        "ip_list"           {"store"         ""       "required"   0}
        "part_number"       {"store"         ""       "required"   0}
        "dest_dir"          {"store"         ""       "required"   0}
        "board_part"        {"store"         ""       "optional"   0}
        "force"             {"store_true"    0        "optional"   0}
    }

    set status [arg_parser my_arglist parsed_args args]

    if {$status != 0} {
        puts "ERROR: There was an error processing the arguments"
        return ""
    }

    ######################

    ## Override the destination directory
    if {$parsed_args(dest_dir) != ""} {
        set generated_ip_path $parsed_args(dest_dir)
    } else {
        puts "ERROR: Please specify the destination directory"
        return ""
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

    if {$parsed_args(board_part) != ""} {
        puts "Setting board part as $parsed_args(board_part)"
        set_property board_part $parsed_args(board_part) [current_project]
    }

    ## Step 1 - Source the TCL scripts to generate 
    foreach ip $parsed_args(ip_list) {
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

    ## Step 4 - Close the project
    close_project

    return $xilinx_ip_file_list
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

proc process_stages {args} {
    array set my_arglist {
        "stage_list"        {"store"         ""       "required"   0}
        "input_stages"      {"store"         ""       "required"   0}
    }

    set status [arg_parser my_arglist parsed_args args]

    if {$status != 0} {
        puts "ERROR: There was an error processing the arguments"
        return ""
    }

    set input_stages_split [split $parsed_args(input_stages) "+"]

    if {[lsearch -exact $input_stages_split "ALL"] != -1} {
        puts "Enabling all stages"
        set enable_all 1
    } else {
        set enable_all 0
    }

    foreach stage $parsed_args(stage_list) {
        # Create a variable a level up
        upvar STAGE_${stage} curr_stage

        ## Find the stage in the stage list
        if { ([lsearch -exact $input_stages_split $stage] != -1) || ($enable_all == 1) } {
            puts "Running $stage"
            set curr_stage 1
        } else {
            puts "Disabling $stage"
            set curr_stage 0
        }
    }
}

proc write_filelist {args} {
    array set my_arglist {
        "filelist"    {"store"         ""       "required"   0}
        "list_name"   {"store"         ""       "required"   0}
        "description" {"store"         ""       "required"   0}
        "output"      {"store"         ""       "required"   0}
    }

    set status [arg_parser my_arglist parsed_args args]

    if {$status != 0} {
        puts "ERROR: There was an error processing the arguments"
        return ""
    }

    ####################################
    set handle   [open $parsed_args(output) w+]
    puts $handle "################################"
    puts $handle "## THIS FILE WAS GENERATED FROM"
    puts $handle "## [file normalize [info script]]"
    puts $handle "################################"
    puts $handle ""
    puts $handle "## $parsed_args(description)"
    puts $handle "set $parsed_args(list_name) \{"
    foreach elem $parsed_args(filelist) {
        puts $handle "  $elem"
    }
    puts $handle "\}"
    close $handle

    return 0
}