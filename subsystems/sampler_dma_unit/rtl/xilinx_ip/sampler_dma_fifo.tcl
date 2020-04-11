#################################################################
## AXI Streaming FIFO for the DMA Input
#################################################################
## Configuration Parameters
set sample_dma_fifo_component_name "sampler_dma_fifo"
set sample_dma_fifo_xci_path       ${generated_ip_path}/${sample_dma_fifo_component_name}/${sample_dma_fifo_component_name}.xci

# Xilinx IP Settings
set sample_dma_fifo_ip_name        "fifo_generator"
set sample_dma_fifo_ip_vendor      "xilinx.com"
set sample_dma_fifo_ip_library     "ip"
set sample_dma_fifo_ip_version     13.2

## FIFO Settings
set sample_dma_fifo_configuration_parameters [list  CONFIG.INTERFACE_TYPE                    {Native} \
                                                    CONFIG.Performance_Options               {First_Word_Fall_Through} \
                                                    CONFIG.Input_Data_Width                  {32} \
                                                    CONFIG.Input_Depth                       {64} \
                                                    CONFIG.Output_Data_Width                 {32} \
                                                    CONFIG.Output_Depth                      {64} \
                                                    CONFIG.Reset_Type                        {Asynchronous_Reset} \
                                                    CONFIG.Full_Flags_Reset_Value            {1} \
                                                    CONFIG.Use_Extra_Logic                   {true} \
                                                    CONFIG.Data_Count                        {true} \
                                                    CONFIG.Data_Count_Width                  {7} \
                                                    CONFIG.Write_Data_Count_Width            {7} \
                                                    CONFIG.Read_Data_Count_Width             {7} \
                                                    CONFIG.Full_Threshold_Assert_Value       {63} \
                                                    CONFIG.Full_Threshold_Negate_Value       {62} \
                                                    CONFIG.Empty_Threshold_Assert_Value      {4} \
                                                    CONFIG.Empty_Threshold_Negate_Value      {5} \
                                                    CONFIG.FIFO_Implementation_wach          {Common_Clock_Distributed_RAM} \
                                                    CONFIG.Full_Threshold_Assert_Value_wach  {15} \
                                                    CONFIG.Empty_Threshold_Assert_Value_wach {14} \
                                                    CONFIG.FIFO_Implementation_wrch          {Common_Clock_Distributed_RAM} \
                                                    CONFIG.Full_Threshold_Assert_Value_wrch  {15} \
                                                    CONFIG.Empty_Threshold_Assert_Value_wrch {14} \
                                                    CONFIG.FIFO_Implementation_rach          {Common_Clock_Distributed_RAM} \
                                                    CONFIG.Full_Threshold_Assert_Value_rach  {15} \
                                                    CONFIG.Empty_Threshold_Assert_Value_rach {14} \
                                                    CONFIG.Enable_Safety_Circuit             {false}]

lappend sample_dma_fifo_run [generate_new_ip ${generated_ip_path} \
                                             ${sample_dma_fifo_ip_name} \
                                             ${sample_dma_fifo_ip_version} \
                                             ${sample_dma_fifo_ip_vendor} \
                                             ${sample_dma_fifo_ip_library} \
                                             ${sample_dma_fifo_component_name} \
                                             ${sample_dma_fifo_configuration_parameters} \
                                             ]

### Append the .xci to the filelist
#set generated_ip_file_list [lappend generated_ip_file_list ${sample_dma_fifo_xci_path}]
#
### Append the IP Run
#set ip_runs [ lappend ip_runs ${sample_dma_fifo_run}]