#################################################################
## Audio PLL
#################################################################
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
