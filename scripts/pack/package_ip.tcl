## Script that creates a packaged IP

set revision 0
set led_gpio_interface_name LED
set btn_gpio_interface_name BTN
set sw_gpio_interface_name  SW

proc create_gpio_interface {name port_name interface_mode description display_name dir core} {
    # Add the bus interface
    ipx::add_bus_interface ${name} [ipx::current_core]
    # Set the properties
    set_property abstraction_type_vlnv xilinx.com:interface:gpio_rtl:1.0 [ipx::get_bus_interfaces ${name} -of_objects $core]
    set_property bus_type_vlnv         xilinx.com:interface:gpio:1.0     [ipx::get_bus_interfaces ${name} -of_objects $core]
    set_property interface_mode        ${interface_mode}                 [ipx::get_bus_interfaces ${name} -of_objects $core]
    set_property display_name          ${display_name}                   [ipx::get_bus_interfaces ${name} -of_objects $core]
    set_property description           ${description}                    [ipx::get_bus_interfaces ${name} -of_objects $core]
    # Add the LEDs to the port map
    ipx::add_port_map                  ${dir}                            [ipx::get_bus_interfaces ${name} -of_objects $core]
    # Set the name
    set_property physical_name ${port_name} [ipx::get_port_maps ${dir} -of_objects [ipx::get_bus_interfaces ${name} -of_objects $core]]
    
}

###################################################################################################################
###################################################################################################################

##########################
######### STEP 1 #########
##########################
## First check if there was a previously packed IP to get the revision and the version
if { [file exists ${packaged_ip_root_dir}/component.xml] == 1} {
    ipx::open_core ${packaged_ip_root_dir}/component.xml
    set revision [get_property core_revision [ipx::current_core]]
    ipx::unload_core ${packaged_ip_root_dir}/component.xml
}

##########################
######### STEP 2 #########
##########################
## Pack the project
ipx::package_project -root_dir ${packaged_ip_root_dir} -vendor xilinx.com -library user -taxonomy /UserIP -import_files -set_current false

##########################
######### STEP 3 #########
##########################
## Open the IP Core
ipx::open_core ${packaged_ip_root_dir}/component.xml

##########################
######### STEP 4 #########
##########################
## Create the GPIO Interfaces

##########################################
## Create the GPIO interface for the LEDs
create_gpio_interface ${led_gpio_interface_name} led master gpio_led gpio_led TRI_O [ipx::current_core]
##########################################

##########################################
## Create the GPIO interface for the Switches
create_gpio_interface ${sw_gpio_interface_name} sw monitor gpio_sw gpio_sw TRI_I [ipx::current_core]
##########################################

##########################################
## Create the GPIO interface for the Buttons
create_gpio_interface ${btn_gpio_interface_name} btn monitor gpio_btn gpio_btn TRI_I [ipx::current_core]
##########################################

##########################################
## Configure the interrupt pins
ipx::infer_bus_interface DOWNSTREAM_almost_empty xilinx.com:signal:interrupt_rtl:1.0 [ipx::current_core]
##########################################

##########################
######### STEP 5 #########
##########################
## Configure the AXI Slave parameters so that they can be exported to the XSDK

##########################################
## CODEC AXI
set codec_axi_if_name s00_axi

ipx::add_address_block_parameter OFFSET_BASE_PARAM [ipx::get_address_blocks reg0 -of_objects [ipx::get_memory_maps ${codec_axi_if_name} -of_objects [ipx::current_core]]]
ipx::add_address_block_parameter OFFSET_HIGH_PARAM [ipx::get_address_blocks reg0 -of_objects [ipx::get_memory_maps ${codec_axi_if_name} -of_objects [ipx::current_core]]]
set_property Value C_${codec_axi_if_name}_BASEADDR [ipx::get_address_block_parameters OFFSET_BASE_PARAM -of_objects [ipx::get_address_blocks reg0 -of_objects [ipx::get_memory_maps ${codec_axi_if_name} -of_objects [ipx::current_core]]]]
set_property Value C_${codec_axi_if_name}_HIGHADDR [ipx::get_address_block_parameters OFFSET_HIGH_PARAM -of_objects [ipx::get_address_blocks reg0 -of_objects [ipx::get_memory_maps ${codec_axi_if_name} -of_objects [ipx::current_core]]]]
##########################################

##########################################
## Sampler AXI
set sampler_axi_if_name axi_lite_slave

ipx::add_address_block_parameter OFFSET_BASE_PARAM [ipx::get_address_blocks reg0 -of_objects [ipx::get_memory_maps ${sampler_axi_if_name} -of_objects [ipx::current_core]]]
ipx::add_address_block_parameter OFFSET_HIGH_PARAM [ipx::get_address_blocks reg0 -of_objects [ipx::get_memory_maps ${sampler_axi_if_name} -of_objects [ipx::current_core]]]
set_property Value C_${sampler_axi_if_name}_BASEADDR [ipx::get_address_block_parameters OFFSET_BASE_PARAM -of_objects [ipx::get_address_blocks reg0 -of_objects [ipx::get_memory_maps ${sampler_axi_if_name} -of_objects [ipx::current_core]]]]
set_property Value C_${sampler_axi_if_name}_HIGHADDR [ipx::get_address_block_parameters OFFSET_HIGH_PARAM -of_objects [ipx::get_address_blocks reg0 -of_objects [ipx::get_memory_maps ${sampler_axi_if_name} -of_objects [ipx::current_core]]]]
##########################################


##########################
######### STEP 6 #########
##########################
## Set the display name and version
set_property name         ${packaged_ip_name}      [ipx::current_core]
set_property version      ${packaged_ip_ver}       [ipx::current_core]
set_property display_name ${packaged_ip_disp_name} [ipx::current_core]
set_property description  ${packaged_ip_name}      [ipx::current_core]

## Increment the revision
incr revision
set_property core_revision ${revision} [ipx::current_core]


##########################
######### STEP 7 #########
##########################
## Generate collaterals
ipx::create_xgui_files [ipx::current_core]


##########################
######### STEP 8 #########
##########################
## Update and save
ipx::update_checksums  [ipx::current_core]
ipx::save_core         [ipx::current_core]

## Close
ipx::unload_core ${packaged_ip_root_dir}/component.xml