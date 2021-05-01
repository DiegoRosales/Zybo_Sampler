#################################################################
## BRAM for the Sampler DMA Controller
#################################################################
## Configuration Parameters
set rd_wr_init_value {00000000}

# Xilinx IP Settings
set ip_name        "blk_mem_gen"
set ip_vendor      "xilinx.com"
set ip_library     "ip"
set ip_version     8.4

lappend {*}configuration_parameters CONFIG.Write_Depth_A                              ${A_rd_wr_depth}
lappend {*}configuration_parameters CONFIG.Read_Width_A                               ${A_rd_wr_width}
lappend {*}configuration_parameters CONFIG.Write_Width_A                              ${A_rd_wr_width}
lappend {*}configuration_parameters CONFIG.Read_Width_B                               ${B_rd_wr_width}
lappend {*}configuration_parameters CONFIG.Write_Width_B                              ${B_rd_wr_width}
lappend {*}configuration_parameters CONFIG.Remaining_Memory_Locations                 ${rd_wr_init_value}
lappend {*}configuration_parameters CONFIG.Use_Byte_Write_Enable                      {true}
lappend {*}configuration_parameters CONFIG.Byte_Size                                  {8}
lappend {*}configuration_parameters CONFIG.Memory_Type                                {True_Dual_Port_RAM}
lappend {*}configuration_parameters CONFIG.Enable_A                                   {Always_Enabled}
lappend {*}configuration_parameters CONFIG.Enable_B                                   {Always_Enabled}
lappend {*}configuration_parameters CONFIG.Assume_Synchronous_Clk                     {true}
lappend {*}configuration_parameters CONFIG.Operating_Mode_A                           {WRITE_FIRST}
lappend {*}configuration_parameters CONFIG.Operating_Mode_B                           {WRITE_FIRST}
lappend {*}configuration_parameters CONFIG.Register_PortA_Output_of_Memory_Primitives {true}
lappend {*}configuration_parameters CONFIG.Register_PortB_Output_of_Memory_Primitives {true}
lappend {*}configuration_parameters CONFIG.Register_PortB_Output_of_Memory_Core       {false}
lappend {*}configuration_parameters CONFIG.Fill_Remaining_Memory_Locations            {true}
lappend {*}configuration_parameters CONFIG.Port_B_Clock                               {100}
lappend {*}configuration_parameters CONFIG.Port_B_Write_Rate                          {50}
lappend {*}configuration_parameters CONFIG.Port_B_Enable_Rate                         {100}
