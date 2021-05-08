##############################
## TCL utilities
##############################
set utils_script_dir [file normalize [file dirname [info script]]]

proc lshift {inputlist} {
  upvar $inputlist argv
  set arg  [lindex $argv 0]
  set argv [lrange $argv 1 end]
  return $arg
}

## Get the git root
proc get_git_root {} {
    set git_root [exec git rev-parse --show-toplevel]
    if {$git_root == ""} {
        puts "ERROR: Failed getting git root"
    }

    return $git_root
}

## Parse arguments
## Argument list
##    array set my_arglist {
##        "arg_name1" {"action" "default_value" "required/optional" <positional=POS#|non-positional=0>}
##        "arg_name2" {"action" "default_value" "required/optional" <positional=POS#|non-positional=0>}
##    }
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

        #puts "arg = $arg"

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
                    puts "Adding argument $arg to $curr_list_arg"
                    lappend parsed_args_int($curr_list_arg) $arg
                }
            }

            incr cur_arg_pos
        }
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

## Generate a variable for every stage
proc process_stages {args} {
    array set my_arglist {
        "stage_list"        {"store"         ""       "required"   0}
        "input_stages"      {"store"         ""       "required"   0}
        "input_stage_args"  {"store"         ""       "required"   0}
    }

    set status [arg_parser my_arglist parsed_args args]

    if {$status != 0} {
        puts "ERROR: There was an error processing the arguments"
        return 1
    }

    set input_stages_split [split $parsed_args(input_stages) "+"]

    if {[lsearch -exact $input_stages_split "ALL"] != -1} {
        puts "Enabling all stages"
        set enable_all 1
    } else {
        set enable_all 0
    }

    foreach stage $parsed_args(stage_list) {
        ## Create a variable a level up
        upvar STAGE_${stage}      curr_stage
        upvar STAGE_${stage}_ARGS curr_stage_args


        ## Find the stage in the stage list
        if { ([lsearch -exact $input_stages_split $stage] != -1) || ($enable_all == 1) } {
            puts "Running $stage"
            set curr_stage 1
        } else {
            puts "Disabling $stage"
            set curr_stage 0
        }

        ## Find all stage arguments for this stage
        set stage_args [lsearch -all -regexp -inline $parsed_args(input_stage_args) "^${stage}_"]

        ## Process each argument
        if {$stage_args != {}} {
            foreach stage_arg $stage_args {
                set arg_split [split $stage_arg "="]
                set arg_name  [lindex $arg_split 0]
                if {[llength $arg_split] == 1} {
                    lappend curr_stage_args($arg_name) 1
                } else {
                    lappend curr_stage_args($arg_name) [lindex $arg_split 1]
                }
                puts "\$STAGE_${stage}_ARGS($arg_name) = $curr_stage_args($arg_name)"
            }
        }
    }
}


## Extracts the core file information
proc extract_core_file_info {args} {
    array set my_arglist {
        "project_cores"    {"store"         ""       "required"   0}
        "filelists_path"   {"store"         ""       "required"   0}
    }

    set status [arg_parser my_arglist parsed_args args]

    set xilinx_ip_tcl_list_all ""
    set fw_incdirs         ""
    set fw_softlinks       ""
    ## Get all the files necessary for building
    foreach core_root_dir $parsed_args(project_cores) {
        ## Source all the core variables
        set core_root [file normalize $core_root_dir]

        ## These variables should be defined in the core.cfg file
        set core_filelist               ""
        set core_pack_script            ""
        set core_xilinx_ip_tcl_filelist ""
        set core_fw_incdirs             ""
        set core_registers              ""

        source ${core_root}/cfg/core.cfg

        ## Get the RTL filelists
        if {$core_filelist != ""} {
            lappend core_file_lists   [list ${core_name} ${core_root} ${core_filelist}]
        }

        ## Get the package script
        if {$core_pack_script != ""} {
            lappend core_pack_scripts [list ${core_name} ${core_root} ${core_pack_script}]
        }

        ## Get the Xilinx IP TCL filelist
        if {$core_xilinx_ip_tcl_filelist != ""} {
            source $core_xilinx_ip_tcl_filelist
            lappend xilinx_ip_tcl_list_all [subst $xilinx_ip_tcl_list]
        }

        ## Get the register maps
        if {$core_registers != ""} {
            lappend core_reg_maps [list ${core_name} ${core_root} ${core_registers}]
        }

        ## Get the FW directories
        if {$core_fw_incdirs != ""} {
            source $core_fw_incdirs
            if {[info exists fwdir]} {
                foreach elem $fwdir {
                    ## Get the softlink target directories
                    lappend fw_softlinks [subst $elem]

                    ## Foreach softlink target directory, include dirs may be defined
                    set softlink_target_name [lindex $elem 0]
                    if {[info exists ${softlink_target_name}_incdir]} {
                        foreach incdir [set ${softlink_target_name}_incdir] {
                            lappend fw_incdirs "${softlink_target_name}/$incdir"
                        }
                    }
                }
            }
        }
    }

    if {![info exists $parsed_args(filelists_path)]} {
        file mkdir $parsed_args(filelists_path)
    }

    # Write all the Xilinx IPs that are going to be generated from TCL scripts
    write_filelist -filelist [join $xilinx_ip_tcl_list_all] -list_name "xilinx_ip_tcl"      -description "Xilinx IPs to be generated from TCL scripts" -output $parsed_args(filelists_path)/xilinx_ip_tcl.f
    # Write all the core filelist files
    write_filelist -filelist $core_file_lists           -list_name "core_file_lists"    -description "Core Filelists"                              -output $parsed_args(filelists_path)/core_file_lists.f
    # Write all the core pack scripts
    write_filelist -filelist $core_pack_scripts         -list_name "core_pack_scripts"  -description "Core package scripts"                        -output $parsed_args(filelists_path)/core_pack_scripts.f
    # Write all the core register maps
    write_filelist -filelist $core_reg_maps             -list_name "core_reg_maps"      -description "Core register maps"                          -output $parsed_args(filelists_path)/core_reg_maps.f
    # Write all the FW directories
    write_filelist -filelist [join $fw_incdirs]         -list_name "fw_incdirs"         -description "Firmware include directories"                -output $parsed_args(filelists_path)/fw_incdirs.f
    write_filelist -filelist $fw_softlinks              -list_name "fw_softlinks"       -description "Firmware softlink directories"               -output $parsed_args(filelists_path)/fw_softlinks.f

    return 0
}

## Write a file
proc write_file {args} {
    array set my_arglist {
        "file"   {"store"       "" "required"   0}
        "output" {"store"       "" "required"   0}
        "force"  {"store_true"  0  "optional"   0}
    }

    set status [arg_parser my_arglist parsed_args args]

    if {$status != 0} {
        puts "ERROR: There was an error processing the arguments"
        return 1
    }

    #############################
    upvar $parsed_args(output) output

    if {![info exists output]} {
        puts "ERROR: Output variable doesn't exist: $parsed_args(output)"
        return 1
    }

    if {[file exists $parsed_args(file)] && $parsed_args(force) == 0} {
        puts "ERROR: File $parsed_args(file) already exists. Use -force to overwrite it"
        return 1
    }

    puts "Writing $parsed_args(file)"
    set fd [open $parsed_args(file) w+]
    puts $fd $output
    close $fd
}

## Read a file and store its contents in a variable
proc read_file {args} {
    array set my_arglist {
        "file"   {"store"  "" "required"   0}
        "output" {"store"  "" "required"   0}
    }

    set status [arg_parser my_arglist parsed_args args]

    if {$status != 0} {
        puts "ERROR: There was an error processing the arguments"
        return 1
    }

    #############################
    upvar $parsed_args(output) output

    if {[info exists output]} {
        puts "ERROR: Output variable already exists $parsed_args(output)"
        return 1
    }

    if {![file exists $parsed_args(file)]} {
        puts "ERROR: File $parsed_args(file) doesn't exist"
        return 1
    }

    puts "Reading $parsed_args(file)"
    set fd [open $parsed_args(file) r]
    set output [read $fd]
    close $fd

    return 0
}

source "${utils_script_dir}/json_parser.tcl"
source "${utils_script_dir}/xil_ip_utils.tcl"
source "${utils_script_dir}/proj_utils.tcl"
