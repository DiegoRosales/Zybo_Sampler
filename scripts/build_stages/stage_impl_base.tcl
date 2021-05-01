## Base script for Synth/PAR/Lint/Simulation

## Gather all sources
parse_json_cfg -cfg_file ${filelists_path}/synthesis_xci_file_list.f.json -output xci_filelist     -override -debug
parse_json_cfg -cfg_file ${filelists_path}/synthesis_rtl_file_list.f.json -output rtl_filelist     -override -debug
parse_json_cfg -cfg_file ${filelists_path}/integ_gen_rtl_filelist.f.json  -output gen_rtl_filelist -override -debug

set_param general.maxThreads 8

## Create the project
create_project ${project_name} ${project_impl_path} -part ${FPGA_PART_NUMBER} -force

## Set the project properties
set_property board_part digilentinc.com:zybo:part0:1.0 [current_project]

## Add the files to the design
read_verilog -sv [dict get $rtl_filelist     synthesis_rtl_file_list]
read_verilog -sv [dict get $gen_rtl_filelist integ_gen_rtl_filelist]
read_ip          [dict get $xci_filelist     synthesis_xci_file_list]
# Core files
#source $filelists_path/core_file_lists.f
#set all_include_dirs ""
## TODO ## foreach core_info $core_file_lists {
## TODO ##    set synthesis_rtl_file_list            ""
## TODO ##    set uvm_simulation_file_list       ""
## TODO ##    set uvm_simulation_env_file_list   ""
## TODO ##    set uvm_simulation_tc_file_list    ""
## TODO ##    set uvm_simulation_env_incdir_list ""
## TODO ##
## TODO ##    lassign $core_info core_name core_root core_filelist
## TODO ##    set libname     "${core_name}_lib"
## TODO ##    set sim_libname "uvm_simulation_lib"
## TODO ##
## TODO ##
## TODO ##    ## Add the simulation files
## TODO ##    set fileset uvm_simulation
## TODO ##    if {[get_filesets -quiet $fileset] == {}} {
## TODO ##      create_fileset -simset $fileset
## TODO ##    }
## TODO ##    ## Main files
## TODO ##    if {$uvm_simulation_file_list != ""} {
## TODO ##      foreach sim_file ${uvm_simulation_file_list} {
## TODO ##          set sim_file [subst $sim_file]
## TODO ##          add_files -fileset $fileset -norecurse $sim_file
## TODO ##          set_property file_type {SystemVerilog} [get_files  $sim_file]
## TODO ##          set_property library $sim_libname [get_files  $sim_file]
## TODO ##      }
## TODO ##    }
## TODO ##
## TODO ##    ## Include files
## TODO ##    if {$uvm_simulation_env_file_list != ""} {
## TODO ##      foreach sim_file ${uvm_simulation_env_file_list} {
## TODO ##          set sim_file [subst $sim_file]
## TODO ##          add_files -fileset $fileset -norecurse $sim_file
## TODO ##          set_property library   $sim_libname     [get_files  $sim_file]
## TODO ##          set_property file_type {Verilog Header} [get_files  $sim_file]
## TODO ##      }
## TODO ##    }
## TODO ##
## TODO ##    ## Include directories
## TODO ##    if {$uvm_simulation_env_incdir_list != ""} {
## TODO ##      foreach incdir ${uvm_simulation_env_incdir_list} {
## TODO ##          append all_include_dirs "[subst $incdir] "
## TODO ##      }
## TODO ##    }
## TODO ##
## TODO ##    ## Testcases
## TODO ##    if {$uvm_simulation_tc_file_list != ""} {
## TODO ##      foreach sim_file ${uvm_simulation_tc_file_list} {
## TODO ##          set sim_file [subst $sim_file]
## TODO ##          add_files -fileset $fileset -norecurse $sim_file
## TODO ##          set_property library   $sim_libname         [get_files  $sim_file]
## TODO ##          set_property file_type {Verilog Header} [get_files  $sim_file]
## TODO ##      }
## TODO ##    }
## TODO ## }


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

######################################################
## START THE BUILD PROCESS (Project Mode)
######################################################
set_property top $integ_project_top [current_fileset]
update_compile_order