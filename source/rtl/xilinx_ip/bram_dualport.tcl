#################################################################
## BRAM for the Sampler DMA Controller
#################################################################
## Configuration Parameters
set dma_bram_A_rd_wr_width    32
set dma_bram_A_rd_wr_depth    256
set dma_bram_B_rd_wr_width    128
set dma_bram_B_rd_wr_depth    [expr ( ${dma_bram_A_rd_wr_depth} * ${dma_bram_A_rd_wr_width} ) / ${dma_bram_B_rd_wr_width}]
set dma_bram_rd_wr_init_value {00000000}
set dma_bram_component_name   "bram_dualport_i${dma_bram_A_rd_wr_width}x${dma_bram_A_rd_wr_depth}_o${dma_bram_B_rd_wr_width}x${dma_bram_B_rd_wr_depth}"
set dma_bram_xci_path         ${generated_ip_path}/${dma_bram_component_name}/${dma_bram_component_name}.xci

# Xilinx IP Settings
set dma_bram_ip_name        "blk_mem_gen"
set dma_bram_ip_vendor      "xilinx.com"
set dma_bram_ip_library     "ip"
set dma_bram_ip_version     8.4

##set_property -dict [list     CONFIG.Use_Byte_Write_Enable {true} 
##                             CONFIG.Write_Width_A {32} 
##                             CONFIG.Read_Width_A {32} 
##                             CONFIG.Write_Width_B {128} 
##                             CONFIG.Read_Width_B {128} 
##                             CONFIG.Byte_Size {8} 
##                             CONFIG.Operating_Mode_A {WRITE_FIRST} 
##                             CONFIG.Operating_Mode_B {WRITE_FIRST} 
##                             CONFIG.Enable_B {Always_Enabled}
##                             
##                             ] [get_ips bram_dualport_i32x256_o128x64]
##

set dma_bram_configuration_parameters [list CONFIG.Component_Name                             ${dma_bram_component_name} \
                                            CONFIG.Write_Depth_A                              ${dma_bram_A_rd_wr_depth} \
                                            CONFIG.Read_Width_A                               ${dma_bram_A_rd_wr_width} \
                                            CONFIG.Write_Width_A                              ${dma_bram_A_rd_wr_width} \
                                            CONFIG.Read_Width_B                               ${dma_bram_B_rd_wr_width} \
                                            CONFIG.Write_Width_B                              ${dma_bram_B_rd_wr_width} \
                                            CONFIG.Remaining_Memory_Locations                 ${dma_bram_rd_wr_init_value} \
                                            CONFIG.Use_Byte_Write_Enable                      {true} \
                                            CONFIG.Byte_Size                                  {8} \
                                            CONFIG.Memory_Type                                {True_Dual_Port_RAM} \
                                            CONFIG.Enable_A                                   {Always_Enabled} \
                                            CONFIG.Enable_B                                   {Always_Enabled} \
                                            CONFIG.Assume_Synchronous_Clk                     {true}\
                                            CONFIG.Operating_Mode_A                           {WRITE_FIRST} \
                                            CONFIG.Operating_Mode_B                           {WRITE_FIRST} \
                                            CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
                                            CONFIG.Register_PortB_Output_of_Memory_Primitives {true} \
                                            CONFIG.Register_PortB_Output_of_Memory_Core       {false} \
                                            CONFIG.Fill_Remaining_Memory_Locations            {true} \
                                            CONFIG.Port_B_Clock                               {100} \
                                            CONFIG.Port_B_Write_Rate                          {50} \
                                            CONFIG.Port_B_Enable_Rate                         {100}\
                                            ]

lappend dma_bram_run [generate_new_ip   ${generated_ip_path} \
                                        ${dma_bram_ip_name} \
                                        ${dma_bram_ip_version} \
                                        ${dma_bram_ip_vendor} \
                                        ${dma_bram_ip_library} \
                                        ${dma_bram_component_name} \
                                        ${dma_bram_configuration_parameters} \
                                        ]

### Append the .xci to the filelist
#set generated_ip_file_list [lappend generated_ip_file_list ${dma_bram_xci_path}]
#
### Append the IP Run
#set ip_runs [ lappend generated_ip_file_list ${dma_bram_run}]