###########################
## Package codec_unit
###########################

source ${project_root}/scripts/pack/pack_utils.tcl

set script_dir           [file normalize [file dirname [info script]]]
set rtl_top              "codec_unit_top"
set rtl_top_file         "${core_root}/rtl/codec_unit_top.sv"
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
##########################
######### STEP 4 #########
##########################
set axi_interfaces ""

## Create AXIS Interfaces
source ${script_dir}/config_axis_if.tcl
## Create AXI4 Lite Interface
source ${script_dir}/config_axi4_if.tcl
## Create I2S Interface
source ${script_dir}/config_i2s_if.tcl

## Create the GPIO interface for the LEDs
pack_utils::create_xilinx_gpio_interface led_status \
                                        -rtl_port_name led_status \
                                        -mode master -description \
                                        "LED Status" -display_name \
                                        "led_status" -direction "out"

## Create the interrupt interface
pack_utils::create_xilinx_interrupt_interface DOWNSTREAM_almost_empty_intr \
                                              -rtl_port_name DOWNSTREAM_almost_empty \
                                              -mode master \
                                              -description "Downstream interrupt signaling FIFO is almost empty" \
                                              -display_name "DOWNSTREAM_almost_empty" \
                                              -sensitivity "LEVEL_HIGH" \

## Create the clocks
# Board Clock (50MHz)
set clk_associated_if ""
set clk_frequency     50000000
set clk_name          "board_clk"
set clk_description   "Board Clock"
pack_utils::create_xilinx_clock_interface $clk_name \
                                          -rtl_port_name $clk_name \
                                          -mode          slave \
                                          -description   $clk_description \
                                          -display_name  $clk_name \
                                          -frequency     $clk_frequency \
                                          -associated_if $clk_associated_if

# AXI Clock (120MHz)
set clk_associated_if $axi_interfaces
set clk_frequency     125000000
set clk_name          "axi_clk"
set clk_description   "AXI Clock"
pack_utils::create_xilinx_clock_interface $clk_name \
                                          -rtl_port_name $clk_name \
                                          -mode          slave \
                                          -description   $clk_description \
                                          -display_name  $clk_name \
                                          -frequency     $clk_frequency \
                                          -associated_if $clk_associated_if

pack_utils::finalize_packaging
