#################################################################
## AXI Streaming FIFO for the DMA Input
#################################################################
# Xilinx IP Settings
set ip_name        "fifo_generator"
set ip_vendor      "xilinx.com"
set ip_library     "ip"
set ip_version     13.2

## FIFO Settings
lappend {*}configuration_parameters CONFIG.INTERFACE_TYPE                    {Native}
lappend {*}configuration_parameters CONFIG.Performance_Options               {First_Word_Fall_Through}
lappend {*}configuration_parameters CONFIG.Input_Data_Width                  {32}
lappend {*}configuration_parameters CONFIG.Input_Depth                       {64}
lappend {*}configuration_parameters CONFIG.Output_Data_Width                 {32}
lappend {*}configuration_parameters CONFIG.Output_Depth                      {64}
lappend {*}configuration_parameters CONFIG.Reset_Type                        {Asynchronous_Reset}
lappend {*}configuration_parameters CONFIG.Full_Flags_Reset_Value            {1}
lappend {*}configuration_parameters CONFIG.Use_Extra_Logic                   {true}
lappend {*}configuration_parameters CONFIG.Data_Count                        {true}
lappend {*}configuration_parameters CONFIG.Data_Count_Width                  {7}
lappend {*}configuration_parameters CONFIG.Write_Data_Count_Width            {7}
lappend {*}configuration_parameters CONFIG.Read_Data_Count_Width             {7}
lappend {*}configuration_parameters CONFIG.Full_Threshold_Assert_Value       {63}
lappend {*}configuration_parameters CONFIG.Full_Threshold_Negate_Value       {62}
lappend {*}configuration_parameters CONFIG.Empty_Threshold_Assert_Value      {4}
lappend {*}configuration_parameters CONFIG.Empty_Threshold_Negate_Value      {5}
lappend {*}configuration_parameters CONFIG.FIFO_Implementation_wach          {Common_Clock_Distributed_RAM}
lappend {*}configuration_parameters CONFIG.Full_Threshold_Assert_Value_wach  {15}
lappend {*}configuration_parameters CONFIG.Empty_Threshold_Assert_Value_wach {14}
lappend {*}configuration_parameters CONFIG.FIFO_Implementation_wrch          {Common_Clock_Distributed_RAM}
lappend {*}configuration_parameters CONFIG.Full_Threshold_Assert_Value_wrch  {15}
lappend {*}configuration_parameters CONFIG.Empty_Threshold_Assert_Value_wrch {14}
lappend {*}configuration_parameters CONFIG.FIFO_Implementation_rach          {Common_Clock_Distributed_RAM}
lappend {*}configuration_parameters CONFIG.Full_Threshold_Assert_Value_rach  {15}
lappend {*}configuration_parameters CONFIG.Empty_Threshold_Assert_Value_rach {14}
lappend {*}configuration_parameters CONFIG.Enable_Safety_Circuit             {false}
