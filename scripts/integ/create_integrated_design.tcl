##################################
## Integrated Project Generator ##
##################################

###########################################

## Source the Vivado Initialization Script to get the board files
source scripts/vivado_init.tcl

## Set the project Variables
source scripts/common_variables.tcl

###########################################

## Set Block Design Variables

set bd_output_dirname ${integrated_ip_project_path}/${integrated_ip_project_name}.srcs/sources_1/bd/${block_design_name}

###########################################
if { $skip_project_gen == 0 } {
    set_param general.maxThreads 8

    ## Create the project
    create_project ${integrated_ip_project_name} ${integrated_ip_project_path} -part xc7z010clg400-1 -force

    ## Set the project properties
    set_property board_part digilentinc.com:zybo:part0:1.0 [current_project]

    ###########################################

    ## Add the packaged IP to the design
    set_property  ip_repo_paths  ${packaged_ip_root_dir} [current_project]
    update_ip_catalog

    ###########################################

    ## Create the Block Design
    create_bd_design ${block_design_name}

    ## Run the block design integration
    source ${project_root}/scripts/integ/integrate_design.tcl
    

    ##############################################
    ## Create the HDL Wrapper and add it to the source files
    make_wrapper -files [get_files ${bd_output_dirname}/${block_design_name}.bd] -top
    add_files -norecurse ${bd_output_dirname}/hdl/${block_design_name}_wrapper.v


    ## Add the constraints
    source ${constraints_file_list}
    foreach file $constraints_file_list {
        ## Use [subst ..] because the filielist contains the $project_root variable
        add_files -fileset constrs_1 -norecurse [subst $file]
    }

    set_property synth_checkpoint_mode None [get_files ${bd_output_dirname}/${block_design_name}.bd]
    generate_target -force all [get_files ${bd_output_dirname}/${block_design_name}.bd]
    puts "Finished generating target"

    ###############################################
    set top_module [find_top]

    ### Launch Synthesis
    if { $implement == 1 || $synthesize == 1} {
        ## Synthesis
        synth_design -top $top_module
        write_checkpoint -force ${integrated_ip_project_path}/post_synth.dcp
    }

    ### Launch P&R
    if { $implement == 1 } {

        if { ${enable_debug} == 1 } {
            implement_debug_core
        }
        implement_debug_core
        if { ${enable_debug} == 0 } {
            if { [file exists ${integrated_ip_project_path}/post_route.dcp] != 0} { 
                puts "Found checkpoint. Running incrementally"
                read_checkpoint -incremental ${integrated_ip_project_path}/post_route.dcp
            }
        }

        ## Opt Desgin
        opt_design
        ## Place Desgin
        place_design
        ## Physical Optimization
        phys_opt_design
        ## Route design
        route_design
        write_checkpoint -force ${integrated_ip_project_path}/post_route.dcp
        
        ### Write the bitstream
        write_bitstream -force ${integrated_ip_project_path}/${integrated_ip_project_name}.bit
        ### Write the debug probes
        if { ${enable_debug} == 1 } {
            write_debug_probes -force ${integrated_ip_project_path}/${integrated_ip_project_name}.ltx
        }
        write_debug_probes -force ${integrated_ip_project_path}/${integrated_ip_project_name}.ltx
    }
    ###############################################
}
##############################################
## Load the bitfile into the FPGA
if { $burn_bitfile == 1 } {
    open_hw
    connect_hw_server
    open_hw_target
    set_property PROGRAM.FILE  ${integrated_ip_project_path}/${integrated_ip_project_name}.bit [get_hw_devices xc7z010_1]
    set_property PROBES.FILE {} [get_hw_devices xc7z010_1]
    set_property FULL_PROBES.FILE {} [get_hw_devices xc7z010_1]
    current_hw_device [get_hw_devices xc7z010_1]
    refresh_hw_device -update_hw_probes false [lindex [get_hw_devices xc7z010_1] 0]
    program_hw_devices [get_hw_devices xc7z010_1]
    refresh_hw_device [lindex [get_hw_devices xc7z010_1] 0]
}

if { $export_ws == 1 } {
    ## Open the project if we're running only this flow
    if { $skip_project_gen == 1 } {
        open_project ${integrated_ip_project_path}/${integrated_ip_project_name}.xpr
    } 
    file mkdir ${worskpace_project_path}
    write_hwdef -force  -file ${worskpace_project_path}/${block_design_name}_wrapper.hdf
}

if { $launch_sdk == 1 } {
    ## Launch the SDK
    if { $skip_project_gen == 1 } {
        open_project ${integrated_ip_project_path}/${integrated_ip_project_name}.xpr
    } 
    launch_sdk -workspace  ${worskpace_project_path} -hwspec ${worskpace_project_path}/${block_design_name}_wrapper.hdf
}