#######################
## Project Generator ##
#######################

## Source the Vivado Initialization Script to get the board files
source scripts/vivado_init.tcl

## Set the project Variables
source scripts/common_variables.tcl

## Create the project
create_project ${packaged_ip_project_name} ${packaged_ip_project_path} -part ${ZYBO_FPGA_PART_NUMBER} -force

## Set the project properties
# This comes from Digilent (it contains presets for the Zynq ARM processor)
set_property board_part digilentinc.com:zybo:part0:1.0 [current_project]

## Add all the files
source $rtl_file_list

## Generate all the required IPs (FIFOs, PLLs, etc.)
source ${project_root}/scripts/pack/generate_collateral_ips.tcl

## Use [subst ..] because the filielist contains the $project_root variable
add_files                -norecurse [subst ${synthesis_file_list}   ] -scan_for_includes
#add_files                -norecurse [subst ${generated_ip_file_list}] -scan_for_includes
add_files -fileset sim_1 -norecurse [subst ${simulation_file_list}  ] -scan_for_includes

## Package the IP
source ${project_root}/scripts/pack/package_ip.tcl

puts "===== PACKAGE IP DONE ======"