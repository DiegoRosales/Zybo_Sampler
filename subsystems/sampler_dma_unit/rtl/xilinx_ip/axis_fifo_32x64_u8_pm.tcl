#################################################################
## AXI Streaming FIFO
#######
## Data width = 32bit
## Depth      = 64
## TUSER      = 8bit
## Packet Mode Enabled
#################################################################
# Xilinx IP Settings
set ip_name        "axis_data_fifo"
set ip_vendor      "xilinx.com"
set ip_library     "ip"
set ip_version     2.0

## FIFO Settings
lappend {*}configuration_parameters CONFIG.TDATA_NUM_BYTES {4}
lappend {*}configuration_parameters CONFIG.FIFO_DEPTH      {64}
lappend {*}configuration_parameters CONFIG.FIFO_MODE       {2}
lappend {*}configuration_parameters CONFIG.HAS_TLAST       {1}
lappend {*}configuration_parameters CONFIG.TUSER_WIDTH     {8}
lappend {*}configuration_parameters CONFIG.Component_Name  ${component_name}
