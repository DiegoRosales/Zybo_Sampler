
## Parse the core configuration
proc parse_json_cfg {args} {

    array set my_arglist {
        "cfg_file" {"store"       ""  "required"   0}
        "output"   {"store"       ""  "required"   0}
        "override" {"store_true"  0   "optional"   0}
        "debug"    {"store_true"  0   "optional"   0}
    }

    set status [arg_parser my_arglist parsed_args args]

    if {$status != 0} {
        puts "ERROR: There was an error processing the arguments"
        return 1
    }

    #############################
    upvar 1 $parsed_args(output) output

    if {[info exists output] && $parsed_args(override) == 0} {
        puts "ERROR: Output variable already exists $parsed_args(output). Use -override to override it"
        return 1
    }

    if {[read_file -file $parsed_args(cfg_file) -output core_cfg] != 0} {
        puts "ERROR: There was a problem while reading the file $parsed_args(cfg_file)"
        return 1
    }

    set decoded_cfg [::json::decode $core_cfg]
    if {$core_cfg == {}} {
        puts "ERROR: There was a problem while decoding the JSON config file $parsed_args(cfg_file)"
        return 0
    }

    ## Create the dictionary
    set output [dict create "cfg_file" $parsed_args(cfg_file)]

    ## Find the core data
    foreach {name data} [lindex $decoded_cfg 1] {
        if {[lindex $data 0] != "array"} {
            dict set output $name [lindex $data 1]
        } else {
            set final_list {}
            foreach list_elem [lindex $data 1] {
                lappend final_list [lindex $list_elem 1]
            }
            dict set output $name $final_list
        }
    }

    if {$parsed_args(debug)} {
        foreach item [dict keys $output] {
            set value [dict get $output $item]
            puts "$item: $value"
        }
    }
    return 0
}

proc parse_project_cfg {args} {
    array set my_arglist {
        "cfg_file" {"store"       ""  "required"   0}
        "output"   {"store"       ""  "required"   0}
        "override" {"store_true"  0   "optional"   0}
    }

    set status [arg_parser my_arglist parsed_args args]

    if {$status != 0} {
        puts "ERROR: There was an error processing the arguments"
        return 1
    }

    #############################
    upvar 1 $parsed_args(output) output

    if {[info exists output] && $parsed_args(override) == 0} {
        puts "ERROR: Output variable already exists $parsed_args(output). Use -override to override it"
        return 1
    }

    if {[parse_json_cfg -cfg_file $parsed_args(cfg_file) -output output -debug] != 0} {
        puts "ERROR: There was a problem while parsing the project file $parsed_args(cfg_file)"
    }

    ## Create the dictionary
    dict set output "cfg_file" $parsed_args(cfg_file)
    
    ## Resolve the project root
    set git_root [get_git_root]
    set project_root [subst [dict get $output project_root]]
    dict set output "project_root" $project_root

    ## Get the project core configurations
    dict set output cores {}
    foreach core_path [dict get $output project_cores] {
        set core_cfg_path "[subst $core_path]/cfg/core.cfg.json"
        if {[file exists $core_cfg_path]} {
            puts "Parsing $core_cfg_path"
            if {[parse_json_cfg -cfg_file $core_cfg_path -output core_cfg -override] != 0} {
                puts "ERROR: There was a problem while parsing the project file $parsed_args(cfg_file)"
            } else {
                set cores [dict get $output cores]
                set core_root [subst $core_path]
                set core_cfg [subst $core_cfg]
                lappend cores $core_cfg
                dict set output "cores" $cores
            }
        } else {
            puts "ERROR: Core config file not found: $core_cfg_path"
        }
    }

    extract_from_all_cores -core_info [dict get $output cores] -variable synthesis_file_list -output synth_filelist
    extract_from_all_cores -core_info [dict get $output cores] -variable xilinx_ip_list      -output ip_tcl_scripts

}

## Extract a variable from all cores and combine them in a list
proc extract_from_all_cores {args} {
    array set my_arglist {
        "core_info"  {"store"       ""  "required"   0}
        "output"     {"store"       ""  "optional"   0}
        "variable"   {"store"       ""  "required"   0}
        "write_file" {"store"       ""  "optional"   0}
        "override"   {"store_true"  0   "optional"   0}
        "debug"      {"store_true"  0   "optional"   0}
    }

    set status [arg_parser my_arglist parsed_args args]

    if {$status != 0} {
        puts "ERROR: There was an error processing the arguments"
        return 1
    }

    #############################
    if {$parsed_args(output) == "" && $parsed_args(write_file) == ""} {
        puts "ERROR: Specify either an output variable name or a filename"
        return 1
    }

    if {$parsed_args(output) != ""} {
        upvar 1 $parsed_args(output) output

        if {[info exists output] && $parsed_args(override) == 0} {
            puts "ERROR: Output variable already exists $parsed_args(output). Use -override to override it"
            return 1
        }
    }

    set output {}

    ## Get all the core contents from the specified variable
    foreach core $parsed_args(core_info) {
        if {[dict exists $core $parsed_args(variable)]} {
            set core_contents [dict get $core $parsed_args(variable)]
            lappend output {*}$core_contents

            if {$parsed_args(debug)} {
                puts "$parsed_args(variable) for [dict get $core core_name]"
                foreach content $core_contents {
                    puts $content
                }
            }
        } else {
            if {$parsed_args(debug)} {
                puts "INFO: $parsed_args(variable) for [dict get $core core_name] doesn't exist"
            }
        }
    }

    if {$parsed_args(write_file) != ""} {
        append file_output "////////////////////////////////////////////////////////////////////////////////////////\n"
        append file_output "// THIS FILE WAS GENERATED FROM   : [file normalize [info script]]\n"
        append file_output "// USING PROC                     : [lindex [info level 1] 0]\n"
        append file_output "// AT TIME                        : [clock format [clock seconds] -format %Y/%m/%d-%H:%M:%S]\n"
        append file_output "////////////////////////////////////////////////////////////////////////////////////////\n"
        append file_output "// Writing compiled list of $parsed_args(variable)\n"
        append file_output "////////////////////////////////////////////////////////////////////////////////////////\n"
        append file_output "\{\n"
        append file_output "    \"$parsed_args(variable)\": \[\n"
        foreach core [lrange $output 0 [expr [llength $output] - 2]] {
            append file_output "        \"$core\",\n"
        }
        append file_output "        \"[lindex $output [expr [llength $output] - 1]]\"\n"
        append file_output "    \]\n"
        append file_output "\}"
        if {[file exists $parsed_args(write_file)] == 0 || $parsed_args(override)} {
            if {$parsed_args(debug)} {
                puts $file_output
            }
            puts "Writing filelist for $parsed_args(variable) to $parsed_args(write_file)"
            set handle   [open $parsed_args(write_file) w+]
            puts $handle $file_output
            close $handle
        } else {
            puts "ERROR: File output $parsed_args(write_file) already exists. Use -override to override it"
            return 1
        }
    }
}

proc write_compiled_filelists {args} {
    array set my_arglist {
        "core_info"  {"store"       ""  "required"   0}
        "output_dir" {"store"       ""  "required"   0}
        "variables"  {"store"       ""  "required"   0}
        "override"   {"store_true"  0   "optional"   0}
        "debug"      {"store_true"  0   "optional"   0}
    }

    set status [arg_parser my_arglist parsed_args args]

    if {$status != 0} {
        puts "ERROR: There was an error processing the arguments"
        return 1
    }

    #############################

    if {$parsed_args(output_dir) == ""} {
        puts "ERROR: Output dir is empty. Please specify an output directory"
        return 1
    }

    file mkdir $parsed_args(output_dir)
    foreach var $parsed_args(variables) {
        puts "Writing filelist for $var"
        extract_from_all_cores -core_info $parsed_args(core_info) -variable $var -write_file $parsed_args(output_dir)/${var}.f.json -override -debug
    }

}