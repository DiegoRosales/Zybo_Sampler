###############################
## Run
###############################
## Initialize
set script_dir [file normalize [file dirname [info script]]]
set ver        [version]

if {[regexp "Vivado" $ver]} {
    set tool "vivado"
} elseif {[regexp "xsct" $ver]} {
    set tool "xsct"
}

puts "Tool = $tool"

################################################################################
source ${script_dir}/utils/utils.tcl
source ${script_dir}/pack/pack_utils.tcl
source ${script_dir}/pack/pack_utils_if_templates.tcl
source ${script_dir}/integ/integ_utils.tcl

array set my_arglist {
    "cfg"         {"store"      "" "required"   1}
    "stages"      {"store"      "" "optional"   0}
    "stage_args"  {"store_list" "" "optional"   0}
    "debug"       {"store_true" 0  "optional"   0}
}

set status [arg_parser my_arglist parsed_args argv]

if {$status != 0} {
    puts "ERROR: There was an error processing the arguments"
    return 1
}

if {[file exists $parsed_args(cfg)] == 0} {
    puts "ERROR: Project Configuration File doesn't exist $parsed_args(cfg)"
}

################################################################################
## Parse the project config file
#source $parsed_args(cfg)
parse_project_cfg -cfg_file $parsed_args(cfg) -output project_cfg
source ${script_dir}/common_variables.tcl

################################################################################
## Get the stages to run
#########################################
## Stages
#########
## 1) Package
## 2) Integrate
## 3) Generate Xilinx IPs
## 4) Synthesis
## 5) Place and Route
#########################################
set stages { PACK INTEG GEN_XILINX_IP IMPL LINT EXPORT_WS BUILD_WS SIM REG_GEN }
set default_stages "PACK+INTEG+GEN_XILINX_IP+IMPL+EXPORT_WS"

if {$parsed_args(stages) != ""} {
    set stage_error [process_stages -stage_list $stages -input_stages $parsed_args(stages) -input_stage_args $parsed_args(stage_args)]
} else {
    set stage_error [process_stages -stage_list $stages -input_stages $default_stages -input_stage_args $parsed_args(stage_args)]
}

################################################################################
## Run the stages
set core_info [dict get $project_cfg cores]
## Extract information from the cores' config files
#extract_core_file_info -project_cores $project_cores -filelists_path $filelists_path
set variables {}
lappend variables synthesis_file_list
lappend variables xilinx_ip_list
write_compiled_filelists -core_info [dict get $project_cfg cores] \
                         -output_dir ${results_dir}/filelists     \
                         -override                                \
                         -variables $variables
## Run the stages
if {$stage_error == 1} {
    puts "ERROR: There was an error processing the stages"
} else {
    ########## VITIS FLOWS ############
    if {$tool == "xsct"} {
        if {$STAGE_BUILD_WS} {
            source $build_stages_path/stage_build_ws.tcl
        }
    }

    ########## VIVADO FLOWS ############

    if {$tool == "vivado"} {
## TODO ##        ## Register Generation
## TODO ##        if {$STAGE_REG_GEN} {
## TODO ##            source $build_stages_path/stage_reg_gen.tcl
## TODO ##        }
## TODO ##
        # Package
        if {$STAGE_PACK} {
            source $build_stages_path/stage_pack.tcl
        }
## TODO ##
## TODO ##        ## Integrate
## TODO ##        if {$STAGE_INTEG} {
## TODO ##            source $build_stages_path/stage_integ.tcl
## TODO ##        }
## TODO ##
## TODO ##        ## Generate Xilinx IPs
## TODO ##        if {$STAGE_GEN_XILINX_IP} {
## TODO ##            source $build_stages_path/stage_gen_xilinx_ip.tcl
## TODO ##        }
## TODO ##
## TODO ##        ## Run synthesis and place and route
## TODO ##        if {$STAGE_IMPL} {
## TODO ##            source $build_stages_path/stage_impl.tcl
## TODO ##        } 
## TODO ##        
## TODO ##        ## Lint
## TODO ##        if {$STAGE_LINT} {
## TODO ##            source $build_stages_path/stage_lint.tcl
## TODO ##        }
## TODO ##
## TODO ##        ## Simulation
## TODO ##        if {$STAGE_SIM} {
## TODO ##            source $build_stages_path/stage_run_simulation.tcl
## TODO ##        }
## TODO ##
## TODO ##        ## If the BUILD_WS stage is passed, then execute this script using xsct
## TODO ##        if {$STAGE_BUILD_WS} {
## TODO ##            source $build_stages_path/stage_build_ws_vivado.tcl
## TODO ##        }
    }
} 
