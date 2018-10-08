##################################
## Integrated Project Generator ##
##################################

###########################################

## Source the Vivado Initialization Script to get the board files
source scripts/vivado_init.tcl

## Set the project Variables
source scripts/common_variables.tcl

###########################################

## Set the project Variables
set project_name      ${integrated_ip_project_name}
set project_path      "${project_root}/${project_name}"

## Set Block Design Variables
set block_design_name "block_design_1"
set bd_output_dirname ${project_path}/${project_name}.srcs/sources_1/bd/${block_design_name}

###########################################

## Create the project
create_project $project_name $project_path -part xc7z010clg400-1 -force

## Set the project properties
set_property board_part digilentinc.com:zybo:part0:1.0 [current_project]

###########################################

## Add the packaged IP to the design
set_property  ip_repo_paths  ${packaged_ip_root_dir} [current_project]
update_ip_catalog

###########################################

## Create the Block Design
create_bd_design $block_design_name

#############################################
## Add the Zynq Processing Unit and create the automatic connections
create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {make_external "FIXED_IO, DDR" apply_board_preset "1" Master "Disable" Slave "Disable" }  [get_bd_cells processing_system7_0]

## Add the custom IP and make the connections
set packaged_ip_inst_name ${packaged_ip_name}_inst
create_bd_cell -type ip -vlnv xilinx.com:user:${packaged_ip_name}:${packaged_ip_ver} ${packaged_ip_inst_name}

## Clock
create_bd_port -dir I -type clk board_clk
set_property CONFIG.FREQ_HZ 50000000 [get_bd_ports board_clk]
connect_bd_net [get_bd_ports board_clk] [get_bd_pins ${packaged_ip_inst_name}/board_clk]

## I2C
create_bd_port -dir IO i2c_sda
create_bd_port -dir IO i2c_scl
connect_bd_net [get_bd_ports i2c_scl] [get_bd_pins ${packaged_ip_inst_name}/i2c_scl]
connect_bd_net [get_bd_ports i2c_sda] [get_bd_pins ${packaged_ip_inst_name}/i2c_sda]

## GPIO
create_bd_port -dir I -from 3 -to 0 sw
create_bd_port -dir I -from 3 -to 0 btn
create_bd_port -dir O -from 3 -to 0 led
connect_bd_net [get_bd_ports sw]  [get_bd_pins ${packaged_ip_inst_name}/sw]
connect_bd_net [get_bd_ports btn] [get_bd_pins ${packaged_ip_inst_name}/btn]
connect_bd_net [get_bd_ports led] [get_bd_pins ${packaged_ip_inst_name}/led]

#start_gui
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/processing_system7_0/M_AXI_GP0" intc_ip "New AXI Interconnect" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto" }  [get_bd_intf_pins ${packaged_ip_inst_name}/s00_axi]
#apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config {Clk "/processing_system7_0/FCLK_CLK0 (100 MHz)" }  [get_bd_pins ${packaged_ip_inst_name}/board_clk]

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
###############################################
### Launch Synthesis and PAR Jobs
set top_module [find_top]
## Synthesis
synth_design -top $top_module
## Opt Desgin
opt_design
## Place Desgin
place_design
## Physical Optimization
phys_opt_design
## Route design
route_design

### Write the bitstream
write_bitstream -force ${project_path}/${project_name}.bit

##############################################
## Load the bitfile into the FPGA
open_hw
connect_hw_server
open_hw_target
set_property PROGRAM.FILE  ${project_path}/${project_name}.bit [get_hw_devices xc7z010_1]
set_property PROBES.FILE {} [get_hw_devices xc7z010_1]
set_property FULL_PROBES.FILE {} [get_hw_devices xc7z010_1]
current_hw_device [get_hw_devices xc7z010_1]
refresh_hw_device -update_hw_probes false [lindex [get_hw_devices xc7z010_1] 0]
program_hw_devices [get_hw_devices xc7z010_1]
refresh_hw_device [lindex [get_hw_devices xc7z010_1] 0]
