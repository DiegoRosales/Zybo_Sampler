
###############################
## This script generates the .xci files
###############################

####################################
## PROCEDURE TO GENERATE A NEW IP ##
## AND RETURN THE IP RUN FOR      ##
## SYNTHESIS                      ##
####################################
proc generate_new_ip {path ip_name ip_version ip_vendor ip_library component_name ip_parameters} {
    ## IP Variables
    set ip_xci_path ${path}/${component_name}/${component_name}.xci
    set ip_dcp_path ${path}/${component_name}/${component_name}.dcp
    set ip_run "none"

    ## If it doesn't exist, create it
    if { [file exists ${ip_dcp_path}] == 0 } {
        ## Step 1 - Create the IP if it doesn't exist
        if { [file exists ${ip_xci_path}] == 0 } {
            ## Step 1.1 - Create the IP
            create_ip -name ${ip_name} -vendor ${ip_vendor} -library ${ip_library} -version ${ip_version} -module_name ${component_name} -dir ${path}

            ## Step 1.2 - Configure the IP
            set_property -dict ${ip_parameters} [get_ips ${component_name}]

            ## Step 1.3 - Generate the collateral files
            generate_target all  [get_files ${ip_xci_path}]
        } else {
            ## Import the IP if it already exists
            add_files ${ip_xci_path}
        }

        ## Step 2 - Create the IP run for synthesis
        set ip_run [create_ip_run [get_files ${ip_xci_path}]]
        puts ${ip_run}
    } else {
        ## Import the IP if it already exists
        add_files ${ip_xci_path}
    }
    return ${ip_run}
}


########################
## AXI Streaming FIFO
########################
## Configuration Parameters
set audio_data_fifo_component_name "audio_data_fifo"
set audio_data_fifo_xci_path       ${generated_ip_path}/${audio_data_fifo_component_name}/${audio_data_fifo_component_name}.xci

# Xilinx IP Settings
set audio_data_fifo_ip_name        "axis_data_fifo"
set audio_data_fifo_ip_vendor      "xilinx.com"
set audio_data_fifo_ip_library     "ip"
set audio_data_fifo_ip_version     1.1

## FIFO Settings
set audio_data_fifo_configuration_parameters [list \
                                                CONFIG.TDATA_NUM_BYTES {8} \
                                                CONFIG.HAS_TLAST       {1} \
                                                CONFIG.IS_ACLK_ASYNC   {1} \
                                                CONFIG.Component_Name ${audio_data_fifo_component_name}\
                                            ]
lappend audio_data_fifo_run [generate_new_ip ${generated_ip_path} \
                                             ${audio_data_fifo_ip_name} \
                                             ${audio_data_fifo_ip_version} \
                                             ${audio_data_fifo_ip_vendor} \
                                             ${audio_data_fifo_ip_library} \
                                             ${audio_data_fifo_component_name} \
                                             ${audio_data_fifo_configuration_parameters} \
                                             ]

## Append the .xci to the filelist
set generated_ip_file_list [lappend generated_ip_file_list ${audio_data_fifo_xci_path}]




########################
## Audio PLL
########################
## Configuration Parameters
set audio_pll_component_name "codec_audio_clock_generator"
set audio_pll_xci_path       ${generated_ip_path}/${audio_pll_component_name}/${audio_pll_component_name}.xci

# Xilinx IP Settings
set audio_pll_ip_name        "clk_wiz"
set audio_pll_ip_vendor      "xilinx.com"
set audio_pll_ip_library     "ip"
set audio_pll_ip_version     6.0

## FIFO Settings
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
# Whenever attempting to change the clock frequencies or upgrade the IP, 
# re-run the IP Generator with the GUI and copy the new settings
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

## Create the IP                                        
lappend audio_pll_run [generate_new_ip ${generated_ip_path} \
                                       ${audio_pll_ip_name} \
                                       ${audio_pll_ip_version} \
                                       ${audio_pll_ip_vendor} \
                                       ${audio_pll_ip_library} \
                                       ${audio_pll_component_name} \
                                       ${audio_pll_configuration_parameters} \
                                       ]


## Append the .xci to the filelist
set generated_ip_file_list [lappend generated_ip_file_list ${audio_pll_xci_path}]

set ip_runs [list ${audio_pll_run} ${audio_data_fifo_run}]

foreach ip_run ${ip_runs} {
    if { ${ip_run} != "none" } {
        launch_runs ${ip_run}
    }
}
#launch_runs -jobs 8 ${audio_data_fifo_run} ${audio_pll_run}

## Wait for the runs to finish
foreach ip_run ${ip_runs} {
    if { ${ip_run} != "none" } {
        wait_on_run ${ip_run}
    }
}
#wait_on_run ${audio_data_fifo_run}
#wait_on_run ${audio_pll_run}
