namespace eval proj_utils {
    ## Configuration
    variable cfg_file
    variable cfg
    variable project_root
    variable project_name
    variable cores

    ## FPGA Part Variables
    variable FPGA_PART_NUMBER
    variable BOARD_PART_NUMBER

    ## Xilinx variables
    variable vivado_install_path
    variable vivado_interface_path

    ## Project Path Variables
    variable project_name
    variable project_root
    variable results_dirname
    variable gen_xilinx_ip_tcl_dirname
    variable gen_xilinx_ip_xci_dirname
    variable workspace_project_name
    variable integ_project_name
    variable integ_project_top
    variable results_dir
    variable xilinx_ip_tcl_path
    variable xilinx_ip_xci_path
    variable project_impl_path
    variable workspace_project_path
    variable filelists_path

    ## Packaged cores variables
    variable packaged_cores_dirname
    variable user_interfaces_dir

    ## Project integration variables
    variable integ_project_dir

    ## Block Design Variables
    variable block_design_name
    variable block_design_hdf

    ## Vitis SDK Design Variables
    variable processor
    variable platform_project_name
    variable app_project_name
    variable fw_source_path

    ## Build Stages
    variable build_stages_path
}

## Clean JSON decoder output
proc clean_json_parse {args} {
    array set my_arglist {
        "parsed_info" {"store"       ""  "required"   0}
        "debug"       {"store_true"  0   "optional"   0}
    }

    set status [arg_parser my_arglist parsed_args args]

    if {$status != 0} {
        puts "ERROR: There was an error processing the arguments"
        return 1
    }

    #############################
    foreach {name json_data} $parsed_args(parsed_info) {
        lassign $json_data type data
        if {$type == "__array__"} {
            set final_list {}
            foreach array_data $data {
                foreach {list_type list_elem} $array_data {
                    lappend final_list $list_elem
                }
            }
            set clean_data $final_list
        } else {
            puts "$name has [llength $data]"
            if {[llength $data] > 1} {
                puts "$name has more json data ([llength $data])"
                # Recurse
                set clean_data [clean_json_parse -parsed_info $data]
            } else {
                set clean_data $data
            }
        }
        dict set output $name $clean_data
    }

    if {$parsed_args(debug)} {
        foreach item [dict keys $output] {
            set value [dict get $output $item]
            if {[llength $value] > 1} {
                puts "$item:"
                foreach elem $value {
                    puts "  $elem"
                }
            } else {
                puts "$item: $value"
            }
        }
    }
    return $output

}

## Parse the core configuration
proc parse_json_cfg {args} {

    array set my_arglist {
        "cfg_file" {"store"       ""  "required"   0}
        "output"   {"store"       ""  "optional"   0}
        "override" {"store_true"  0   "optional"   0}
        "debug"    {"store_true"  0   "optional"   0}
    }

    set status [arg_parser my_arglist parsed_args args]

    if {$status != 0} {
        puts "ERROR: There was an error processing the arguments"
        return 1
    }

    #############################
    if {$parsed_args(output) != ""} {
        upvar 1 $parsed_args(output) output
        set return_err_code 1

        if {[info exists output] && $parsed_args(override) == 0} {
            puts "ERROR: Output variable already exists $parsed_args(output). Use -override to override it"
            return $return_err_code
        }
    } else {
        set return_err_code ""
    }

    if {[read_file -file $parsed_args(cfg_file) -output core_cfg] != 0} {
        puts "ERROR: There was a problem while reading the file $parsed_args(cfg_file)"
        return $return_err_code
    }

    set decoded_cfg [::json::decode $core_cfg]
    if {$decoded_cfg == {}} {
        puts "ERROR: There was a problem while decoding the JSON config file $parsed_args(cfg_file)"
        return $return_err_code
    }

    ## Create the dictionary
    set output [dict create "cfg_file" $parsed_args(cfg_file)]
    set output [dict merge $output [clean_json_parse -parsed_info [lindex $decoded_cfg 1]]]

    if {$parsed_args(debug)} {
        foreach item [dict keys $output] {
            set value [dict get $output $item]
            if {[llength $value] > 1} {
                puts "$item:"
                foreach elem $value {
                    puts "  $elem"
                }
            } else {
                puts "$item: $value"
            }
        }
    }
    if {$parsed_args(output) != ""} {
        return 0
    } else {
        return $output
    }
}

## Parse the main project.cfg.json file
proc proj_utils::parse_project_cfg {args} {
    array set my_arglist {
        "cfg_file" {"store"       ""  "optional"   0}
        "output"   {"store"       ""  "optional"   0}
        "override" {"store_true"  0   "optional"   0}
    }

    set status [arg_parser my_arglist parsed_args args]

    if {$status != 0} {
        puts "ERROR: There was an error processing the arguments"
        return 1
    }

    #############################
    if {$parsed_args(output) != ""} {
        upvar 1 $parsed_args(output) output
        if {[info exists output] && $parsed_args(override) == 0} {
            puts "ERROR: Output variable already exists $parsed_args(output). Use -override to override it"
            return 1
        }
    }

    if {$parsed_args(cfg_file) == "" && $proj_utils::cfg_file == ""} {
        puts "ERROR: Please specify the project cfg file"
        return 1
    } elseif {$parsed_args(cfg_file) != ""} {
        set proj_utils::cfg_file $parsed_args(cfg_file)
    }

    if {[parse_json_cfg -cfg_file $proj_utils::cfg_file -output output] != 0} {
        puts "ERROR: There was a problem while parsing the project file $proj_utils::cfg_file"
        return 1
    }

    ## Resolve the global variables
    upvar 0 proj_utils::project_root project_root
    upvar 0 proj_utils::project_name project_name
    set git_root [get_git_root]
    set project_root [subst [dict get $output project_root]]
    set project_name [subst [dict get $output project_name]]

    ## Subsitute global variables
    set output [subst $output]

    ## Get the project core configurations
    upvar 0 proj_utils::cores cores
    dict set output "cores" {}
    foreach core_path [dict get $output project_cores] {
        set core_cfg_path "[subst $core_path]/cfg/core.cfg.json"
        if {[file exists $core_cfg_path]} {
            puts "Parsing $core_cfg_path"
            if {[parse_json_cfg -cfg_file $core_cfg_path -output core_cfg -override] != 0} {
                puts "ERROR: There was a problem while parsing the project file $proj_utils::cfg_file"
            } else {
                set cores     [dict get $output cores]
                set core_root [subst $core_path]
                set core_cfg  [subst $core_cfg]
                dict set core_cfg core_root $core_root
                lappend cores $core_cfg
                dict set output "cores" $cores
            }
        } else {
            puts "ERROR: Core config file not found: $core_cfg_path"
        }
    }

    set proj_utils::cfg $output
    update_general_variables
    #extract_from_all_cores -core_info [dict get $output cores] -variable synthesis_rtl_file_list -output synth_filelist
    #extract_from_all_cores -core_info [dict get $output cores] -variable xilinx_ip_tcl_list      -output ip_tcl_scripts

}

## Extract a variable from a single core
proc proj_utils::extract_from_core {args} {
    array set my_arglist {
        "core"     {"store"       ""  "required"   0}
        "variable" {"store"       ""  "required"   0}
        "debug"    {"store_true"  0   "optional"   0}
    }

    set status [arg_parser my_arglist parsed_args args]

    if {$status != 0} {
        puts "ERROR: There was an error processing the arguments"
        return ""
    }

    #############################
    set core     $parsed_args(core)
    set variable $parsed_args(variable)
    set core_contents ""

    if {$core == ""} {
        if {$parsed_args(debug)} {
            puts "INFO: Core is empty"
        }
        return ""
    }

    if {$variable == ""} {
        puts "ERROR: Please specify a variable"
        return ""
    }

    if {[dict exists $core $variable]} {
        set core_contents [dict get $core $variable]
    } else {
        if {$parsed_args(debug)} {
            puts "INFO: $variable for [dict get $core core_name] doesn't exist"
        }
    }

    if {$parsed_args(debug)} {
        foreach content $core_contents {
            puts "$content"
        }
    }

    return $core_contents

}

## Extract a variable from all cores and combine them in a list
proc proj_utils::extract_from_all_cores {args} {
    array set my_arglist {
        "cores"      {"store"       ""  "optional"   0}
        "output"     {"store"       ""  "optional"   0}
        "variable"   {"store"       ""  "required"   0}
        "write_file" {"store"       ""  "optional"   0}
        "override"   {"store_true"  0   "optional"   0}
        "debug"      {"store_true"  0   "optional"   0}
        "split"      {"store_true"  0   "optional"   0}
    }

    set status [arg_parser my_arglist parsed_args args]

    if {$status != 0} {
        puts "ERROR: There was an error processing the arguments"
        return 1
    }

    #############################
    set return_string   0
    set return_err_code 1
    if {$parsed_args(output) == "" && $parsed_args(write_file) == ""} {
        set return_string   1
        set return_err_code ""
    }

    if {$parsed_args(cores) == "" && $proj_utils::cores == ""} { 
        puts "ERROR: No core information provided"
        return $return_err_code
    } elseif {$parsed_args(cores) != ""} {
        set cores $parsed_args(cores)
    } else {
        set cores $proj_utils::cores
    }

    if {$parsed_args(output) != ""} {
        upvar 1 $parsed_args(output) output

        if {[info exists output] && $parsed_args(override) == 0} {
            puts "ERROR: Output variable already exists $parsed_args(output). Use -override to override it"
            return $return_err_code
        }
    }

    set output {}

    ## Get the hierarchy of the variable
    set var_hier [split $parsed_args(variable) "."]

    ## Get all the core contents from the specified variable
    foreach core $cores {
        set core_contents $core
        ## Get the variable from the core
        foreach var $var_hier {
            set core_contents [extract_from_core -core $core_contents -variable $var]
        }

        ## If it exists, add it
        if {$core_contents != ""} {
            if {$parsed_args(split)} {
                dict set output [dict get $core core_name] $core_contents
            } else {
                lappend output {*}$core_contents
            }
        } else {
            if {$parsed_args(debug)} {
                puts "INFO: $parsed_args(variable) for [dict get $core core_name] doesn't exist"
            }
        }
    }

    ## Assemble the file
    append file_output "////////////////////////////////////////////////////////////////////////////////////////\n"
    append file_output "// THIS FILE WAS GENERATED FROM   : [file normalize [info script]]\n"
    append file_output "// USING PROC                     : [lindex [info level 1] 0]\n"
    append file_output "// AT TIME                        : [clock format [clock seconds] -format %Y/%m/%d-%H:%M:%S]\n"
    append file_output "////////////////////////////////////////////////////////////////////////////////////////\n"
    append file_output "// Writing compiled list of $parsed_args(variable)\n"
    append file_output "////////////////////////////////////////////////////////////////////////////////////////\n"
    append file_output "\n"
    append file_output "\{\n"
    if {$parsed_args(split)} {
        set i 0
        foreach core [dict keys $output] {
            append file_output "  // Core: $core\n"
            if {[expr $i == [expr [llength [dict keys $output]] - 1]]} {
                append file_output [format_json_list -list [dict get $output $core] -list_name $core]
            } else {
                append file_output [format_json_list -list [dict get $output $core] -list_name $core -add_comma]
            }
            append file_output "\n\n"
            incr i
        }
        append file_output "\n"
    } else {
        append file_output [format_json_list -list $output -list_name $parsed_args(variable)]
    }
    append file_output "\}"

    if {$parsed_args(debug)} {
        puts $file_output
    }

    if {$parsed_args(write_file) != ""} {
        ## Write file
        puts "Writing filelist for $parsed_args(variable) to $parsed_args(write_file)"
        if {$parsed_args(override)} {
            write_file -file $parsed_args(write_file) -output file_output -force
        } else {
            write_file -file $parsed_args(write_file) -output file_output
        }
    } elseif {$return_string} {
        return $output
    }
}

## Populate all variables
proc proj_utils::update_general_variables {} {
    ## FPGA Part Variables
    set proj_utils::FPGA_PART_NUMBER          [dict get $proj_utils::cfg fpga_part]
    set proj_utils::BOARD_PART_NUMBER         [dict get $proj_utils::cfg board_part]

    ## Xilinx variables
    if {[info exists ::env(XILINX_VIVADO)]} {
        set proj_utils::vivado_install_path        $::env(XILINX_VIVADO)
        set proj_utils::vivado_interface_path      ${proj_utils::vivado_install_path}/data/ip/interfaces
    }

    ## Project Path Variables
    set proj_utils::project_name               [dict get $proj_utils::cfg project_name]
    set proj_utils::project_root               [dict get $proj_utils::cfg project_root]
    set proj_utils::results_dirname            [dict get $proj_utils::cfg results_dirname]
    set proj_utils::gen_xilinx_ip_tcl_dirname  [dict get $proj_utils::cfg gen_xilinx_ip_tcl_dirname]
    set proj_utils::gen_xilinx_ip_xci_dirname  [dict get $proj_utils::cfg gen_xilinx_ip_xci_dirname]
    set proj_utils::workspace_project_name     [dict get $proj_utils::cfg workspace_project_name]
    set proj_utils::integ_project_name         [dict get $proj_utils::cfg integ_project_name]
    set proj_utils::integ_project_top          [dict get $proj_utils::cfg integ_project_top]
    set proj_utils::results_dir                "${proj_utils::project_root}/${proj_utils::results_dirname}"
    set proj_utils::xilinx_ip_tcl_path         "${proj_utils::results_dir}/${proj_utils::gen_xilinx_ip_tcl_dirname}"
    set proj_utils::xilinx_ip_xci_path         "${proj_utils::results_dir}/${proj_utils::gen_xilinx_ip_xci_dirname}"
    set proj_utils::project_impl_path          "${proj_utils::results_dir}/${proj_utils::project_name}"
    set proj_utils::workspace_project_path     "${proj_utils::results_dir}/${proj_utils::workspace_project_name}"
    set proj_utils::filelists_path             "${proj_utils::results_dir}/filelists"

    ## Packaged cores variables
    set proj_utils::packaged_cores_dirname     "${proj_utils::results_dir}/packaged_cores"
    set proj_utils::user_interfaces_dir        [subst [dict get $proj_utils::cfg user_interfaces_dir]]

    ## Project integration variables
    set proj_utils::integ_project_dir          ${proj_utils::results_dir}/${proj_utils::integ_project_name}

    ## Block Design Variables
    set proj_utils::block_design_name          "audio_sampler_block_design"
    set proj_utils::block_design_hdf           ${proj_utils::block_design_name}_wrapper.hdf

    ## Vitis SDK Design Variables
    set proj_utils::processor                  "ps7_cortexa9_0"
    set proj_utils::platform_project_name      "${proj_utils::project_name}_platform"
    set proj_utils::app_project_name           "${proj_utils::project_name}_app"
    set proj_utils::fw_source_path              ${proj_utils::project_root}/source/common/fw/

    ## Build Stages
    set proj_utils::build_stages_path ${proj_utils::project_root}/scripts/build_stages
}

## Format a list in JSON form
proc format_json_list {args} {
    array set my_arglist {
        "list"       {"store"       ""   "required"   0}
        "list_name"  {"store"       ""   "required"   0}
        "indent"     {"store"       "0"  "optional"   0}
        "add_comma"  {"store_true"  "0"  "optional"   0}
    }

    set status [arg_parser my_arglist parsed_args args]

    if {$status != 0} {
        puts "ERROR: There was an error processing the arguments"
        return ""
    }

    #############################

    set indent [string repeat "  " $parsed_args(indent)]

    append json_list "  ${indent}\"$parsed_args(list_name)\": \[\n"
    set i 0
    foreach elem $parsed_args(list) {
        if {$i == [expr [llength $parsed_args(list)] - 1]} {
            append json_list "    ${indent}\"${elem}\"\n"
        } else {
            append json_list "    ${indent}\"${elem}\",\n"
        }
        incr i
    }

    
    ## Add a comma at the end
    if {$parsed_args(add_comma)} {
        append json_list "  ${indent}\],"
    } else {
        append json_list "  ${indent}\]"
    }

    return $json_list
}

## Writes a filelist of a variable compiled from all cores
proc proj_utils::write_compiled_filelists {args} {
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
        extract_from_all_cores -cores $parsed_args(core_info) -variable $var -write_file $parsed_args(output_dir)/${var}.f.json -override -debug
    }

}

## Writes a filelist
proc write_filelist {args} {
    array set my_arglist {
        "filelist"      {"store"         ""       "optional"   0}
        "filelist_dict" {"store"         ""       "optional"   0}
        "list_name"     {"store"         ""       "optional"   0}
        "description"   {"store"         ""       "required"   0}
        "output"        {"store"         ""       "required"   0}
    }

    set status [arg_parser my_arglist parsed_args args]

    if {$status != 0} {
        puts "ERROR: There was an error processing the arguments"
        return 1
    }
    ###################################
    if {$parsed_args(filelist) == "" && $parsed_args(filelist_dict) == "" && $parsed_args(list_name) == ""} {
        puts "ERROR: Please specify either a filelist with a name or a filelist_dict"
        return 1
    }
    ###################################
    append file_output "////////////////////////////////////////////////////////////////////////////////////////\n"
    append file_output "// THIS FILE WAS GENERATED FROM   : [file normalize [info script]]\n"
    append file_output "// USING PROC                     : [lindex [info level 1] 0]\n"
    append file_output "// AT TIME                        : [clock format [clock seconds] -format %Y/%m/%d-%H:%M:%S]\n"
    append file_output "////////////////////////////////////////////////////////////////////////////////////////\n"
    append file_output "\n"
    append file_output "// $parsed_args(description)\n"
    append file_output "\{\n"
    ###################################
    # {
    #   list_name: [
    #     <ELEM1>,
    #     <ELEM2>,
    #     <ELEM3>
    #   ]
    # }
    ####################################
    if {$parsed_args(filelist_dict) != ""} {
        set i 0
        foreach {name filelist} $parsed_args(filelist_dict) {
            append file_output "  // $name\n"
            if {$i == [expr [llength [dict keys $parsed_args(filelist_dict)]] - 1]} {
                append file_output [format_json_list -list $filelist -list_name $name]
            } else {
                append file_output [format_json_list -list $filelist -list_name $name -add_comma]
            }
            append file_output "\n\n"
            incr i
        }
    } else {
        append file_output [format_json_list -list $parsed_args(filelist) -list_name $parsed_args(list_name)]
    }
    append file_output "\n\}\n"
    write_file -file $parsed_args(output) -output file_output -force

    return 0
}

proc write_json_list {args} {
    array set my_arglist {
        "list"          {"store"         ""       "optional"   0}
        "description"   {"store"         ""       "required"   0}
        "output"        {"store"         ""       "required"   0}
    }

    set status [arg_parser my_arglist parsed_args args]

    if {$status != 0} {
        puts "ERROR: There was an error processing the arguments"
        return 1
    }
    ###################################

}