#################################################################
## AXI Streaming FIFO for the CODEC output
#################################################################
## Configuration Parameters
set audio_data_fifo_component_name "audio_data_fifo"
set audio_data_fifo_xci_path       ${generated_ip_path}/${audio_data_fifo_component_name}/${audio_data_fifo_component_name}.xci

# Xilinx IP Settings
set audio_data_fifo_ip_name        "axis_data_fifo"
set audio_data_fifo_ip_vendor      "xilinx.com"
set audio_data_fifo_ip_library     "ip"
set audio_data_fifo_ip_version     2.0

## FIFO Settings
set audio_data_fifo_configuration_parameters [list \
                                                CONFIG.FIFO_DEPTH        {1024} \
                                                CONFIG.TDATA_NUM_BYTES   {8} \
                                                CONFIG.HAS_TLAST         {1} \
                                                CONFIG.IS_ACLK_ASYNC     {1} \
                                                CONFIG.HAS_WR_DATA_COUNT {1} \
                                                CONFIG.HAS_RD_DATA_COUNT {1} \
                                                CONFIG.Component_Name    ${audio_data_fifo_component_name}\
                                            ]
lappend audio_data_fifo_run [generate_new_ip ${generated_ip_path} \
                                             ${audio_data_fifo_ip_name} \
                                             ${audio_data_fifo_ip_version} \
                                             ${audio_data_fifo_ip_vendor} \
                                             ${audio_data_fifo_ip_library} \
                                             ${audio_data_fifo_component_name} \
                                             ${audio_data_fifo_configuration_parameters} \
                                             ]

### Append the .xci to the filelist
#set generated_ip_file_list [lappend generated_ip_file_list ${audio_data_fifo_xci_path}]
#
### Append the IP Run
#set ip_runs [ lappend ip_runs ${audio_data_fifo_run}]