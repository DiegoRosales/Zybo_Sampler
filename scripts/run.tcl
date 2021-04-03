###############################
## Run
###############################

set script_dir [file normalize [file dirname [info script]]]

## Initialize
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
## Source the project config file
source $parsed_args(cfg)
source ${script_dir}/common_variables.tcl

set ver [version]

if {[regexp "Vivado" $ver]} {
    set tool "vivado"
} elseif {[regexp "xsct" $ver]} {
    set tool "xsct"
}
puts "Tool = $tool"

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

## Extract information from the cores' config files
extract_core_file_info -project_cores $project_cores -filelists_path $filelists_path

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
        ## Register Generation
        if {$STAGE_REG_GEN} {
            source $build_stages_path/stage_reg_gen.tcl
        }

        # Package
        if {$STAGE_PACK} {
            source $build_stages_path/stage_pack.tcl
        }

        ## Integrate
        if {$STAGE_INTEG} {
            source $build_stages_path/stage_integ.tcl
        }

        ## Generate Xilinx IPs
        if {$STAGE_GEN_XILINX_IP} {
            source $build_stages_path/stage_gen_xilinx_ip.tcl
        }

        ## Run synthesis and place and route
        if {$STAGE_IMPL} {
            source $build_stages_path/stage_impl.tcl
        } 
        
        ## Lint
        if {$STAGE_LINT} {
            source $build_stages_path/stage_lint.tcl
        }

        ## Simulation
        if {$STAGE_SIM} {
            source $build_stages_path/stage_run_simulation.tcl
        }

        ## If the BUILD_WS stage is passed, then execute this script using xsct
        if {$STAGE_BUILD_WS} {
            source $build_stages_path/stage_build_ws_vivado.tcl
        }
    }
} 
