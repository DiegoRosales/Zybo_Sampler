#################################################################
## AXI Streaming FIFO
#######
## Data width = 32bit
## Depth      = 64
## TUSER      = 8bit
## Packet Mode Enabled
#################################################################
## Configuration Parameters
set component_name "axis_fifo_32x64_u8_pm"
set component_xci_path       ${generated_ip_path}/${component_name}/${component_name}.xci

# Xilinx IP Settings
set component_ip_name        "axis_data_fifo"
set component_ip_vendor      "xilinx.com"
set component_ip_library     "ip"
set component_ip_version     2.0

## FIFO Settings
set component_configuration_parameters  [list \
                                            CONFIG.TDATA_NUM_BYTES {4}  \
                                            CONFIG.FIFO_DEPTH      {64} \
                                            CONFIG.FIFO_MODE       {2}  \
                                            CONFIG.HAS_TLAST       {1}  \
                                            CONFIG.TUSER_WIDTH     {8}  \
                                            CONFIG.Component_Name  ${component_name}\
                                        ]


generate_new_ip ${generated_ip_path}                  \
                ${component_ip_name}                  \
                ${component_ip_version}               \
                ${component_ip_vendor}                \
                ${component_ip_library}               \
                ${component_name}                     \
                ${component_configuration_parameters}

