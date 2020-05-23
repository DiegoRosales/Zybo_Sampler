###############################
## Run
###############################

set script_dir [file normalize [file dirname [info script]]]

## Initialize
source ${script_dir}/utils.tcl
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

set core_file_lists  {}
set core_pack_scripts {}

## Extract information from the cores' config files
set xilinx_ip_list_all ""
foreach core_root_dir $project_cores {
    ## Source all the core variables
    set core_root [file normalize $core_root_dir]

    source ${core_root}/cfg/core.cfg

    if {$core_filelist != ""} {
        lappend core_file_lists   [list ${core_name} ${core_root} ${core_filelist}]
    }

    if {$core_pack_script != ""} {
        lappend core_pack_scripts [list ${core_name} ${core_root} ${core_pack_script}]
    }

    ## Get the Xilinx IP TCL filelist
    if {$core_xilinx_ip_tcl_filelist != ""} {
        source $core_xilinx_ip_tcl_filelist
        lappend xilinx_ip_list_all [subst $xilinx_ip_list]
    }
}

#########################################
## Stages
#########
## 1) Package
## 2) Integrate
## 3) Generate Xilinx IPs
## 4) Synthesis
## 5) Place and Route
#########################################
set stages { PACK INTEG GEN_XILINX_IP IMPL EXPORT_WS BUILD_WS }

if {$parsed_args(stages) != ""} {
    set stage_error [process_stages -stage_list $stages -input_stages $parsed_args(stages) -input_stage_args $parsed_args(stage_args)]
} else {
    set stage_error [process_stages -stage_list $stages -input_stages "ALL" -input_stage_args $parsed_args(stage_args)]
}

if {$stage_error == 1} {
    puts "ERROR: There was an error processing the stages"
} else {
    ########## VITIS FLOWS ############
    if {$tool == "xsct"} {
        if {$STAGE_BUILD_WS} {
            setws ${workspace_project_path}
            repo -set ${fw_source_path}/repo
            app create -name ${app_project_name} -hw ${workspace_project_path}/${platform_project_name}.xsa -proc {ps7_cortexa9_0} -os freertos10_xilinx_sampler -lang C -template {Empty Application}
            driver -peripheral ps7_sd_0 -name sdps -ver 3.8

            file link -symbolic ${workspace_project_path}/${app_project_name}/src/common ${project_root}/source/fw/src/
            file link -symbolic ${workspace_project_path}/${app_project_name}/src/codec_controller ${project_root}/subsystems/codec_unit/fw/
            file link -symbolic ${workspace_project_path}/${app_project_name}/src/sampler_dma ${project_root}/subsystems/sampler_dma_unit/fw/

            app config -name ${app_project_name} -add include-path {${workspace_loc:/${ProjName}/src/codec_controller/include}}
            app config -name ${app_project_name} -add include-path {${workspace_loc:/${ProjName}/src/sampler_dma/include}}
            app config -name ${app_project_name} -add include-path {${workspace_loc:/${ProjName}/src/common/FreeRTOS-Plus-CLI}}
            app config -name ${app_project_name} -add include-path {${workspace_loc:/${ProjName}/src/common/FreeRTOS-Plus-FAT/include}}
            app config -name ${app_project_name} -add include-path {${workspace_loc:/${ProjName}/src/common/ZyboCLI}}
            app config -name ${app_project_name} -add include-path {${workspace_loc:/${ProjName}/src/common/ZyboSD}}
            app config -name ${app_project_name} -add include-path {${workspace_loc:/${ProjName}/src/common/nco}}
            app config -name ${app_project_name} -add include-path {${workspace_loc:/${ProjName}/src/common/jsmn}}
            app config -name ${app_project_name} -add include-path {${workspace_loc:/${ProjName}/src/common/sampler/FreeRTOS_CLI_Apps/include}}
            app config -name ${app_project_name} -add include-path {${workspace_loc:/${ProjName}/src/common/sampler/include}}

            platform generate
        }
    }

    ########## VIVADO FLOWS ############

    if {$tool == "vivado"} {
        # Package
        if {$STAGE_PACK} {
            foreach core $core_pack_scripts {
                lassign $core core_name core_root pack_script
                puts "Packaging Core $core_name with script $pack_script"
                source $pack_script
            }
        }

        ## Integrate
        if {$STAGE_INTEG} {
            set    integ_script [file normalize ${project_integ_script}]
            puts   "Integrating project using script $integ_script"
            source $integ_script
        }


        ## Generate Xilinx IPs
        set generated_xilinx_ips ""
        if {$STAGE_GEN_XILINX_IP} {
            # IPs from the integration phase
            if {[file exists ${integ_project_dir}/gen_xci_filelist.f]} {
                source ${integ_project_dir}/gen_xci_filelist.f
                lappend generated_xilinx_ips [generate_xilinx_ips_xci -ip_list $gen_xci_filelist -part_number $ZYBO_FPGA_PART_NUMBER -board_part ${ZYBO_BOARD_PART_NUMBER} -dest_dir ${xilinx_ip_xci_path}]
            }

            # IPs from TCL scripts
            lappend generated_xilinx_ips [generate_xilinx_ips_tcl -ip_list [join $xilinx_ip_list_all]  -part_number $ZYBO_FPGA_PART_NUMBER -dest_dir $xilinx_ip_tcl_path]
            write_filelist -filelist [join $generated_xilinx_ips] -list_name "gen_xci_filelist" -description "Generated XCI Files" -output $results_dir/gen_xci_filelist.f
        }

        ## Run synthesis and place and route
        if {$STAGE_IMPL} {
            set_param general.maxThreads 8

            ## Create the project
            create_project ${project_name} ${project_impl_path} -part ${ZYBO_FPGA_PART_NUMBER} -force

            ## Set the project properties
            set_property board_part digilentinc.com:zybo:part0:1.0 [current_project]

            ## Add the files to the design
            # Core files
            foreach core_info $core_file_lists {
                lassign $core_info core_name core_root core_filelist
                set libname "${core_name}_lib"
                # Source the filelist
                source $core_filelist

                foreach synth_file ${synthesis_file_list} {
                    read_verilog -library $libname -sv [subst $synth_file]
                }
            }

            # Add generated RTL files
            if {[file exists ${integ_project_dir}/gen_rtl_filelist.f]} {
                source ${integ_project_dir}/gen_rtl_filelist.f
                read_verilog -library gen_rtl_lib -sv $gen_rtl_filelist
            }

            # Add generated XCI Files from the integration stage
            if {[file exists $results_dir/gen_xci_filelist.f]} {
                source $results_dir/gen_xci_filelist.f
                read_ip $gen_xci_filelist
            }

            ## Add Constraints
            create_fileset -constrset constraints
            # Add synthesis constraints
            set synth_constr_files [add_files $constraints_synth -fileset constraints]
            set_property FILE_TYPE              TCL [get_files $synth_constr_files]
            set_property USED_IN_SIMULATION     0   [get_files $synth_constr_files]
            set_property USED_IN_SYNTHESIS      1   [get_files $synth_constr_files]
            set_property USED_IN_IMPLEMENTATION 1   [get_files $synth_constr_files]
            # Add place and route constraints
            set par_constr_files [add_files $constraints_par -fileset constraints]
            set_property FILE_TYPE              TCL [get_files $par_constr_files]
            set_property USED_IN_SIMULATION     0   [get_files $par_constr_files]
            set_property USED_IN_SYNTHESIS      0   [get_files $par_constr_files]
            set_property USED_IN_IMPLEMENTATION 1   [get_files $par_constr_files]

            ######################################################
            ## START THE BUILD PROCESS (Project Mode)
            ######################################################
            set_property top $integ_project_top [current_fileset]
            update_compile_order

            ## Create the synthesis run
            create_run synthesis -constrset constraints -flow {Vivado Synthesis 2019}

            ## Create the place and route run
            create_run place_and_route -parent_run synthesis -constrset constraints -flow {Vivado Implementation 2019}

            ## Launch Synthesis
            puts "Starting Synthesis"
            launch_runs synthesis -jobs 8
            wait_on_run -run synthesis
            puts "Synthesis Done!"
            ## Launch Place and route
            puts "Starting Place and Route"
            launch_runs place_and_route -jobs 8
            wait_on_run -run place_and_route
            puts "Place and Route Done!"

            ## Open the place and route run
            current_run [get_runs place_and_route]
            open_run place_and_route

            ## Export the HW Platform for the Vitis Workspace
            write_hw_platform -fixed -force  -include_bit -file ${workspace_project_path}/${platform_project_name}.xsa
            if {[get_cells -quiet -filter {REF_NAME =~ dbg_hub}] != {}} {
                puts "Writing debug probes"
                write_debug_probes -force ${workspace_project_path}/${platform_project_name}.ltx
            }

            if {$parsed_args(debug) == 0} {
                close_project
            }
        }

        ## If the BUILD_WS stage is passed, then execute this script using xsct
        if {$STAGE_BUILD_WS} {
            puts "Running FW Workspace build command"

            ## Get the full path of the tool
            set xsct [file normalize $::env(XILINX_VITIS)/bin/xsct.bat]

            ## Make the command
            set cmd "$xsct [file normalize [info script]] -cfg [file normalize $parsed_args(cfg)] -stages BUILD_WS"

            ## Run the command
            puts "Running command \'$cmd\'"
            catch {exec [split $cmd]} output
            puts "Output:"
            puts $output

            puts "\n"
            puts "Done!"
        }
    }
} 
