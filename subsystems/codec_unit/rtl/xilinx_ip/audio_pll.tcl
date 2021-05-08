#################################################################
## Audio PLL
#################################################################
# Xilinx IP Settings
set ip_name        "clk_wiz"
set ip_vendor      "xilinx.com"
set ip_library     "ip"
set ip_version     6.0

## FIFO Settings
# Input clock frequency (MHz)
set input_clock_frequency 125
# Input Clock Port - This should match the RTL
set input_clock_port_name "clock_in_125"

# Output clock frequency (MHz)
set output_clock_frequency 12
# Output Clock Port - This should match the RTL
set output_clock_port_name "codec_mclk"

## Configuration parameters
# Note - Some of these are just calculations from the GUI
# Whenever attempting to change the clock frequencies or upgrade the IP, 
# re-run the IP Generator with the GUI and copy the new settings
lappend {*}configuration_parameters CONFIG.PRIMITIVE                  {PLL}
lappend {*}configuration_parameters CONFIG.JITTER_SEL                 {Min_O_Jitter}
lappend {*}configuration_parameters CONFIG.PRIM_SOURCE                {Global_buffer}
lappend {*}configuration_parameters CONFIG.PRIM_IN_FREQ               ${input_clock_frequency}
lappend {*}configuration_parameters CONFIG.PRIMARY_PORT               ${input_clock_port_name}
lappend {*}configuration_parameters CONFIG.CLK_OUT1_PORT              ${output_clock_port_name}
lappend {*}configuration_parameters CONFIG.CLKOUT1_REQUESTED_OUT_FREQ ${output_clock_frequency}
lappend {*}configuration_parameters CONFIG.USE_SAFE_CLOCK_STARTUP     {true}
lappend {*}configuration_parameters CONFIG.FEEDBACK_SOURCE            {FDBK_AUTO}
lappend {*}configuration_parameters CONFIG.CLKIN1_JITTER_PS           {80.0}
lappend {*}configuration_parameters CONFIG.CLKOUT1_DRIVES             {BUFGCE}
lappend {*}configuration_parameters CONFIG.CLKOUT2_DRIVES             {BUFGCE}
lappend {*}configuration_parameters CONFIG.CLKOUT3_DRIVES             {BUFGCE}
lappend {*}configuration_parameters CONFIG.CLKOUT4_DRIVES             {BUFGCE}
lappend {*}configuration_parameters CONFIG.CLKOUT5_DRIVES             {BUFGCE}
lappend {*}configuration_parameters CONFIG.CLKOUT6_DRIVES             {BUFGCE}
lappend {*}configuration_parameters CONFIG.CLKOUT7_DRIVES             {BUFGCE}
lappend {*}configuration_parameters CONFIG.MMCM_DIVCLK_DIVIDE         {1}
lappend {*}configuration_parameters CONFIG.MMCM_BANDWIDTH             {HIGH}
lappend {*}configuration_parameters CONFIG.MMCM_CLKFBOUT_MULT_F       {12}
lappend {*}configuration_parameters CONFIG.MMCM_CLKIN1_PERIOD         {8.000}
lappend {*}configuration_parameters CONFIG.MMCM_COMPENSATION          {ZHOLD}
lappend {*}configuration_parameters CONFIG.MMCM_CLKOUT0_DIVIDE_F      {125}
lappend {*}configuration_parameters CONFIG.CLKOUT1_JITTER             {142.005}
lappend {*}configuration_parameters CONFIG.CLKOUT1_PHASE_ERROR        {73.940}
