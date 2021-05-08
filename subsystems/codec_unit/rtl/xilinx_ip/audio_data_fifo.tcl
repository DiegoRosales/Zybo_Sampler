#################################################################
## AXI Streaming FIFO for the CODEC output
#################################################################
# Xilinx IP Settings
set ip_name        "axis_data_fifo"
set ip_vendor      "xilinx.com"
set ip_library     "ip"
set ip_version     2.0

## FIFO Settings
lappend {*}configuration_parameters CONFIG.FIFO_DEPTH        {1024}
lappend {*}configuration_parameters CONFIG.TDATA_NUM_BYTES   {8}
lappend {*}configuration_parameters CONFIG.HAS_TLAST         {1}
lappend {*}configuration_parameters CONFIG.IS_ACLK_ASYNC     {1}
lappend {*}configuration_parameters CONFIG.HAS_WR_DATA_COUNT {1}
lappend {*}configuration_parameters CONFIG.HAS_RD_DATA_COUNT {1}