
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

    if {[parse_json_cfg -cfg_file $parsed_args(cfg_file) -output proj_cfg] != 0} {
        puts "ERROR: There was a problem while parsing the project file $parsed_args(cfg_file)"
    }

    ## Create the dictionary
    set output [dict create "cfg_file" $parsed_args(cfg_file)]

    ## Get the project name
    dict set output "project_name" [dict get $proj_cfg project_name]
    
    ## Get the project root
    if {[dict get $proj_cfg project_root] == "git_root"} {
        set project_root [get_git_root]
    } else {
        ## TODO
    }
    dict set output "project_root" $project_root
 
    ## Get the project core configurations
    dict set output cores {}
    foreach core_path [dict get $proj_cfg project_cores] {
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
        "core_info" {"store"       ""  "required"   0}
        "output"    {"store"       ""  "required"   0}
        "variable"  {"store"       ""  "required"   0}
        "override"  {"store_true"  0   "optional"   0}
        "debug"     {"store_true"  0   "optional"   0}
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
}

