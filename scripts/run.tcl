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
    "stage_args"  {"store"      "" "optional"   0}
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
foreach core_root_dir $project_cores {
    ## Source all the core variables
    set core_root [file normalize $core_root_dir]

    source ${core_root}/cfg/core.cfg
    lappend core_file_lists   [list ${core_name} ${core_root} "${core_root}/cfg/${core_filelist}"]
    lappend core_pack_scripts [list ${core_name} ${core_root} "${core_root}/cfg/${core_pack_script}"]
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
    process_stages -stage_list $stages -input_stages $parsed_args(stages)
} else {
    process_stages -stage_list $stages -input_stages "ALL"
}

########## VITIS FLOWS ############

if {$tool == "xsct"} {
    if {$STAGE_BUILD_WS} {
        setws ${workspace_project_path}
        repo -set ${fw_source_path}/repo
        app create -name ${app_project_name} -hw ${workspace_project_path}/${platform_project_name}.xsa -proc {ps7_cortexa9_0} -os freertos10_xilinx_sampler -lang C -template {Empty Application}
        driver -peripheral ps7_sd_0 -name sdps -ver 3.5
        platform generate

        file link -symbolic ${workspace_project_path}/${app_project_name}/src/src ${project_root}/source/fw/src/
        app config -name ${app_project_name} -add include-path {${workspace_loc:/${ProjName}/src/src/FreeRTOS-Plus-CLI}}
        app config -name ${app_project_name} -add include-path {${workspace_loc:/${ProjName}/src/src/FreeRTOS-Plus-FAT}}
        app config -name ${app_project_name} -add include-path {${workspace_loc:/${ProjName}/src/src/ZyboCLI}}
        app config -name ${app_project_name} -add include-path {${workspace_loc:/${ProjName}/src/src/ZyboSD}}
        app config -name ${app_project_name} -add include-path {${workspace_loc:/${ProjName}/src/src/nco}}
        app config -name ${app_project_name} -add include-path {${workspace_loc:/${ProjName}/src/src/jsmn}}
        app config -name ${app_project_name} -add include-path {${workspace_loc:/${ProjName}/src/src/sampler}}
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
        lappend generated_xilinx_ips [generate_xilinx_ips_tcl -ip_list $xilinx_ip_list  -part_number $ZYBO_FPGA_PART_NUMBER -dest_dir $xilinx_ip_tcl_path]
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
                read_verilog -library $libname -sv ${core_root}/$synth_file
            }
        }

        # Generated RTL files
        if {[file exists ${integ_project_dir}/gen_rtl_filelist.f]} {
            source ${integ_project_dir}/gen_rtl_filelist.f
            read_verilog -library gen_rtl_lib -sv $gen_rtl_filelist
        }

        # Generated XCI Files from the integration stage
        if {[file exists $results_dir/gen_xci_filelist.f]} {
            source $results_dir/gen_xci_filelist.f
            read_ip $gen_xci_filelist
        }

        ######################################################
        ## START THE BUILD PROCESS
        ######################################################

        ## Run Elaboration
        synth_design -rtl -name rtl_elaboration -top $integ_project_top

        ## Load constraints
        read_xdc -unmanaged $constraints_synth

        ## Run synthesis
        synth_design -name rtl_synthesis -top $integ_project_top
        
        read_xdc -unmanaged $constraints_par
        ## Run place and route
        # Opt Desgin
        opt_design
        # Place Desgin
        place_design
        # Physical Optimization
        phys_opt_design
        # Route design
        route_design

        write_hw_platform -fixed -force  -include_bit -file ${workspace_project_path}/${platform_project_name}.xsa

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
        set cmd "$xsct [file normalize [info script]] -cfg [file normalize $parsed_args(cfg)] -stages \"BUILD_WS\""

        ## Run the command
        puts "Running command \'$cmd\'"
        exec [split $cmd]

        puts "\n"
        puts "Done!"
    }
}

