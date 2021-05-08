## Base script for Synth/PAR/Lint/Simulation

## Write filelists for debug
proj_utils::write_compiled_filelists -core_info $proj_utils::cores        \
                                     -output_dir ${results_dir}/filelists \
                                     -override                            \
                                     -variables synthesis_rtl_file_list

## Gather all sources
set gen_rtl_filelist [parse_json_cfg -cfg_file ${filelists_path}/integ_gen_rtl_filelist.f.json]
set xci_filelist     [parse_json_cfg -cfg_file ${filelists_path}/synthesis_xci_file_list.f.json]
set rtl_filelist     [proj_utils::extract_from_all_cores -variable synthesis_rtl_file_list]

set_param general.maxThreads 8

## Create the project
create_project ${project_name} ${project_impl_path} -part ${FPGA_PART_NUMBER} -force

## Set the project properties
set_property board_part digilentinc.com:zybo:part0:1.0 [current_project]

## Add the RTL files to the design
read_verilog -sv $rtl_filelist
## Add the generated RTL files from the integration stage
read_verilog -sv [dict get $gen_rtl_filelist integ_gen_rtl_filelist]
## Add the XCI files
read_ip          [dict get $xci_filelist     synthesis_xci_file_list]

## Add Constraints
create_fileset -constrset constraints
# Add synthesis constraints
set synth_constr_files [add_files [dict get $project_cfg constraints_synth] -fileset constraints]
set_property FILE_TYPE              TCL [get_files $synth_constr_files]
set_property USED_IN_SIMULATION     0   [get_files $synth_constr_files]
set_property USED_IN_SYNTHESIS      1   [get_files $synth_constr_files]
set_property USED_IN_IMPLEMENTATION 1   [get_files $synth_constr_files]
# Add place and route constraints
set par_constr_files [add_files [dict get $project_cfg constraints_par] -fileset constraints]
set_property FILE_TYPE              TCL [get_files $par_constr_files]
set_property USED_IN_SIMULATION     0   [get_files $par_constr_files]
set_property USED_IN_SYNTHESIS      0   [get_files $par_constr_files]
set_property USED_IN_IMPLEMENTATION 1   [get_files $par_constr_files]

## Update compile order
set_property top $integ_project_top [current_fileset]
update_compile_order