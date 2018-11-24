
###############################
## This script generates the .xci files
###############################

########################
## AXI Streaming FIFO
########################
## Variables for the settings

set audio_data_fifo_component_name "audio_data_fifo"

create_ip -name axis_data_fifo -vendor xilinx.com -library ip -version 1.1 -module_name ${audio_data_fifo_component_name} -dir ${generated_ip_path}

## Configuration Parameters
set audio_data_fifo_configuration_parameters [list \
                                                CONFIG.TDATA_NUM_BYTES {8} \
                                                CONFIG.IS_ACLK_ASYNC   {1} \
                                                CONFIG.Component_Name ${audio_data_fifo_component_name}\
                                            ]
set_property -dict ${audio_data_fifo_configuration_parameters} [get_ips ${audio_data_fifo_component_name}]

## Generate all the verilog files
generate_target all [get_files  ${generated_ip_path}/${audio_data_fifo_component_name}/${audio_data_fifo_component_name}.xci]

## Append the .xci to the filelist
set generated_ip_file_list [lappend generated_ip_file_list ${generated_ip_path}/${audio_data_fifo_component_name}/${audio_data_fifo_component_name}.xci]

########################
## Audio PLL
########################
## Variables for the settings
# Module name - This should match the RTL
set audio_pll_component_name        "codec_audio_clock_generator"

# Input clock frequency (MHz)
set audio_pll_input_clock_frequency 125
# Input Clock Port - This should match the RTL
set audio_pll_input_clock_port_name "clock_in_125"

# Output clock frequency (MHz)
set audio_pll_output_clock_frequency 12
# Output Clock Port - This should match the RTL
set audio_pll_output_clock_port_name "codec_mclk"

## Configuration parameters
# Note - Some of these are just calculations from the GUI
# Whenever attempting to change the clock frequencies, re-run the IP Generator with the GUI and copy the new ones
set audio_pll_configuration_parameters [list \
                                            CONFIG.Component_Name             ${audio_pll_component_name} \
                                            CONFIG.PRIMITIVE                  {PLL} \
                                            CONFIG.JITTER_SEL                 {Min_O_Jitter} \
                                            CONFIG.PRIM_SOURCE                {Global_buffer} \
                                            CONFIG.PRIM_IN_FREQ               ${audio_pll_input_clock_frequency} \
                                            CONFIG.PRIMARY_PORT               ${audio_pll_input_clock_port_name} \
                                            CONFIG.CLK_OUT1_PORT              ${audio_pll_output_clock_port_name} \
                                            CONFIG.CLKOUT1_REQUESTED_OUT_FREQ ${audio_pll_output_clock_frequency} \
                                            CONFIG.USE_SAFE_CLOCK_STARTUP     {true} \
                                            CONFIG.FEEDBACK_SOURCE            {FDBK_AUTO} \
                                            CONFIG.CLKIN1_JITTER_PS           {80.0} \
                                            CONFIG.CLKOUT1_DRIVES             {BUFGCE} \
                                            CONFIG.CLKOUT2_DRIVES             {BUFGCE} \
                                            CONFIG.CLKOUT3_DRIVES             {BUFGCE} \
                                            CONFIG.CLKOUT4_DRIVES             {BUFGCE} \
                                            CONFIG.CLKOUT5_DRIVES             {BUFGCE} \
                                            CONFIG.CLKOUT6_DRIVES             {BUFGCE} \
                                            CONFIG.CLKOUT7_DRIVES             {BUFGCE} \
                                            CONFIG.MMCM_DIVCLK_DIVIDE         {1} \
                                            CONFIG.MMCM_BANDWIDTH             {HIGH} \
                                            CONFIG.MMCM_CLKFBOUT_MULT_F       {12} \
                                            CONFIG.MMCM_CLKIN1_PERIOD         {8.000} \
                                            CONFIG.MMCM_COMPENSATION          {ZHOLD} \
                                            CONFIG.MMCM_CLKOUT0_DIVIDE_F      {125} \
                                            CONFIG.CLKOUT1_JITTER             {142.005} \
                                            CONFIG.CLKOUT1_PHASE_ERROR        {73.940} \
                                            ] 

create_ip -name clk_wiz -vendor xilinx.com -library ip -version 5.4 -module_name ${audio_pll_component_name} -dir ${generated_ip_path}

## Set the configuration settings
set_property -dict ${audio_pll_configuration_parameters} [get_ips ${audio_pll_component_name}]

## Generate all the verilog files
generate_target all [get_files  ${generated_ip_path}/${audio_pll_component_name}/${audio_pll_component_name}.xci]

## Append the .xci to the filelist
set generated_ip_file_list [lappend generated_ip_file_list ${generated_ip_path}/${audio_pll_component_name}/${audio_pll_component_name}.xci]
