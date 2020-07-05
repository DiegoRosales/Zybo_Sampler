## Base script for Synth/PAR/Lint/Simulation

set_param general.maxThreads 8

## Create the project
create_project ${project_name} ${project_impl_path} -part ${ZYBO_FPGA_PART_NUMBER} -force

## Set the project properties
set_property board_part digilentinc.com:zybo:part0:1.0 [current_project]

## Add the files to the design
# Core files
source $filelists_path/core_file_lists.f
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
if {[file exists ${filelists_path}/integ_gen_rtl_filelist.f]} {
    source ${filelists_path}/integ_gen_rtl_filelist.f
    read_verilog -library gen_rtl_lib -sv $integ_gen_rtl_filelist
}

# Add generated XCI Files from the integration stage
if {[file exists $filelists_path/all_gen_xci_filelist.f]} {
    source $filelists_path/all_gen_xci_filelist.f
    read_ip $all_gen_xci_filelist
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