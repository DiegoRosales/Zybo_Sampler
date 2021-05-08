###########################
## Package Sampler Mixer
###########################

source ${project_root}/scripts/pack/pack_utils.tcl

set script_dir           [file normalize [file dirname [info script]]]
set rtl_top              "sampler_mixer"
set rtl_top_file         "${core_root}/rtl/sampler_mixer.sv"
set package_project_name ${core_name}_pack
set package_project_dir  ${packaged_cores_dirname}/${package_project_name}
set revision             1
set vendor               zybo_sampler
set library              user
set bus_definition_list  [list ${vivado_interface_path}/gpio_v1_0/gpio.xml           \
                               ${vivado_interface_path}/axis_v1_0/axis.xml           \
                               ${vivado_interface_path}/aximm_v1_0/aximm.xml         \
                               ${vivado_interface_path}/interrupt_v1_0/interrupt.xml \
                               ${vivado_interface_path}/clock_v1_0/clock.xml         \
                               ${vivado_interface_path}/reset_v1_0/reset.xml         \
                               ${user_interfaces_dir}/i2s/i2s.xml                    \
                               ]

## Load bus definitions
pack_utils::init -project_name $package_project_name  \
                 -project_dir  $package_project_dir   \
                 -part_number  $FPGA_PART_NUMBER      \
                 -revision     $revision              \
                 -vendor       $vendor                \
                 -library      $library               \
                 -rtl_filelist $rtl_top_file

pack_utils::load_bus_def $bus_definition_list
set_property ip_repo_paths $user_interfaces_dir [current_project]
update_ip_catalog

## Create the configurations
set axi_interfaces ""

## Create AXIS Interfaces
source ${script_dir}/config_axis_if.tcl

## AXI Clock (120MHz)
set clk_associated_if {"axis_interface_master" "axis_interface_slave"}
set clk_frequency     125000000
set clk_name          clk
set clk_description   "AXI Clock"
pack_utils::create_xilinx_clock_interface $clk_name \
                                          -rtl_port_name $clk_name \
                                          -description   $clk_description \
                                          -display_name  $clk_name \
                                          -frequency     $clk_frequency \
                                          -associated_if $clk_associated_if \
                                          -mode          slave

pack_utils::finalize_packaging
