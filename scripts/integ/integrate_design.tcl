#############################################
## Design integration script
#########
## This script will
## - Instantiate the Block Design elements
## - Create the interconnections
#############################################

###################################################
####### Step 1 - Instantiate the Elements #########
###################################################
#### Add the Zynq Processing Unit ####
# Enable F2P (Fabric to Processing Unit) Interrupts
# Enable the High Performance AXI Streaming port for DMA (HP0)
set zynq_configuration [list \
                            CONFIG.PCW_USE_FABRIC_INTERRUPT {1}  \
                            CONFIG.PCW_IRQ_F2P_INTR         {1}  \
                            CONFIG.PCW_USE_S_AXI_HP0        {1}  \
                            CONFIG.PCW_S_AXI_HP0_DATA_WIDTH {64} \
                        ]
create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0
set_property -dict ${zynq_configuration} [get_bd_cells processing_system7_0]


#### Add the AXI GPIO Module, set the properties ####
# Properties:
# - Two 4-bit GPIOs (4 switches and 4 push buttons)
# - Enable interrupts
# - GPIO1 -> Switches
# - GPIO2 -> Push Buttons
set gpio_configuration [list \
                            CONFIG.C_GPIO_WIDTH          {4}          \
                            CONFIG.C_GPIO2_WIDTH         {4}          \
                            CONFIG.C_IS_DUAL             {1}          \
                            CONFIG.C_ALL_INPUTS          {1}          \
                            CONFIG.C_ALL_INPUTS_2        {1}          \
                            CONFIG.C_INTERRUPT_PRESENT   {1}          \
                            CONFIG.GPIO_BOARD_INTERFACE  {sws_4bits}  \
                            CONFIG.GPIO2_BOARD_INTERFACE {btns_4bits} \
                        ]
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 axi_gpio_0
set_property -dict ${gpio_configuration} [get_bd_cells axi_gpio_0]

#### Add the AXI DMA IP
# Properties:
# - Address width = 32-bit
# - Data Width = 64-bit

create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma:7.1 axi_dma_0

set dma_configuration [list \
                            CONFIG.c_include_sg                      {0}  \
                            CONFIG.c_sg_include_stscntrl_strm        {0}  \
                            CONFIG.c_include_mm2s                    {1}  \
                            CONFIG.c_m_axi_mm2s_data_width           {64} \
                            CONFIG.c_m_axis_mm2s_tdata_width         {64} \
                            CONFIG.c_mm2s_burst_size                 {8}  \
                            CONFIG.c_include_s2mm                    {0}  \
                            CONFIG.c_addr_width                      {32} \
                            CONFIG.c_m_axi_s2mm_data_width.VALUE_SRC USER \
                            CONFIG.c_include_s2mm                    {1}  \
                            CONFIG.c_m_axi_s2mm_data_width           {64} \
                        ] 

set_property -dict ${dma_configuration} [get_bd_cells axi_dma_0]

#### Add the Concat module to concatenate multiple interrupts from different sources
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_0


#### Add the custom IP and make the connections ####
set packaged_ip_inst_name ${packaged_ip_name}_inst
create_bd_cell -type ip -vlnv xilinx.com:user:${packaged_ip_name}:${packaged_ip_ver} ${packaged_ip_inst_name}

##############################################
####### Step 2 - Create the IO ports #########
##############################################

## Clock
create_bd_port -dir I -type clk board_clk
set_property CONFIG.FREQ_HZ 50000000 [get_bd_ports board_clk]
connect_bd_net [get_bd_ports board_clk] [get_bd_pins ${packaged_ip_inst_name}/board_clk]

## I2S
## Master Clock
create_bd_port -dir O ac_mclk   
## I2S Serial Clock
create_bd_port -dir I ac_bclk   
## I2S Playback Channel Clock (Left/Right)
create_bd_port -dir I ac_pblrc  
## I2S Playback Data
create_bd_port -dir O ac_pbdat  
## I2S Recorded Channel Clock (Left/Right)
create_bd_port -dir I ac_reclrc 
## I2S Recorded Data
create_bd_port -dir I ac_recdat 
## Digital Enable (Active Low)
create_bd_port -dir O ac_muten  

## I2C
create_bd_port -dir IO i2c_sda
create_bd_port -dir IO i2c_scl


## GPIO
# Create a Xilinx gpio_rtl interface
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 SW
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 BTN
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 LED

##############################################
####### Step 3 - Run the Connections #########
##############################################

#### Run Board Connection Automation for the Zynq Processing Unit, the AXI GPIO and the AXI Interface of the Samples ####
#### INFO - The Board Pin information for the board automation is under board_files/zybo/B.3/*.xml
## Zynq
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {make_external "FIXED_IO, DDR" apply_board_preset "1" Master "Disable" Slave "Disable" } [get_bd_cells processing_system7_0]

## Sampler
# AXI Interface
apply_bd_automation -rule xilinx.com:bd_rule:axi4               -config {Master "/processing_system7_0/M_AXI_GP0" intc_ip "New AXI Interconnect" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto" }  [get_bd_intf_pins ${packaged_ip_inst_name}/s00_axi]
# GPIO
connect_bd_intf_net [get_bd_intf_pins ${packaged_ip_inst_name}/LED]  [get_bd_intf_ports LED ]
connect_bd_intf_net [get_bd_intf_pins ${packaged_ip_inst_name}/SW ]  [get_bd_intf_ports SW  ] 
connect_bd_intf_net [get_bd_intf_pins ${packaged_ip_inst_name}/BTN]  [get_bd_intf_ports BTN ]
# CODEC I2C (Control)
connect_bd_net      [get_bd_pins ${packaged_ip_inst_name}/i2c_scl ]  [get_bd_ports i2c_scl] 
connect_bd_net      [get_bd_pins ${packaged_ip_inst_name}/i2c_sda ]  [get_bd_ports i2c_sda] 
# CODEC I2S (Audio)
connect_bd_net      [get_bd_pins ${packaged_ip_inst_name}/ac_bclk  ]  [get_bd_ports ac_bclk  ] 
connect_bd_net      [get_bd_pins ${packaged_ip_inst_name}/ac_mclk  ]  [get_bd_ports ac_mclk  ] 
connect_bd_net      [get_bd_pins ${packaged_ip_inst_name}/ac_pblrc ]  [get_bd_ports ac_pblrc ] 
connect_bd_net      [get_bd_pins ${packaged_ip_inst_name}/ac_pbdat ]  [get_bd_ports ac_pbdat ] 
connect_bd_net      [get_bd_pins ${packaged_ip_inst_name}/ac_reclrc]  [get_bd_ports ac_reclrc] 
connect_bd_net      [get_bd_pins ${packaged_ip_inst_name}/ac_recdat]  [get_bd_ports ac_recdat] 
connect_bd_net      [get_bd_pins ${packaged_ip_inst_name}/ac_muten ]  [get_bd_ports ac_muten ] 

## AXI GPIO
apply_bd_automation -rule xilinx.com:bd_rule:axi4               -config {Master "/processing_system7_0/M_AXI_GP0" intc_ip "/ps7_0_axi_periph" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto" }     [get_bd_intf_pins axi_gpio_0/S_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_gpio_0/GPIO        ]  [get_bd_intf_ports SW  ] 
connect_bd_intf_net [get_bd_intf_pins axi_gpio_0/GPIO2       ]  [get_bd_intf_ports BTN ]
#connect_bd_net      [get_bd_pins      axi_gpio_0/ip2intc_irpt]  [get_bd_pins  processing_system7_0/IRQ_F2P]

## AXI DMA
# AXI Stream to the Audio Controller
connect_bd_intf_net [get_bd_intf_pins axi_dma_0/M_AXIS_MM2S] [get_bd_intf_pins ${packaged_ip_inst_name}/s_axis]
connect_bd_intf_net [get_bd_intf_pins axi_dma_0/S_AXIS_S2MM] [get_bd_intf_pins ${packaged_ip_inst_name}/m_axis]
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config {Clk "/processing_system7_0/FCLK_CLK0 (100 MHz)" }  [get_bd_pins ${packaged_ip_inst_name}/s_axis_aclk]
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config {Clk "/processing_system7_0/FCLK_CLK0 (100 MHz)" }  [get_bd_pins ${packaged_ip_inst_name}/m_axis_aclk]

# AXI DMA to the Zynq Processor
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/axi_dma_0/M_AXI_MM2S" intc_ip "Auto" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto" }  [get_bd_intf_pins processing_system7_0/S_AXI_HP0]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/processing_system7_0/FCLK_CLK0 (100 MHz)} Clk_slave {/processing_system7_0/FCLK_CLK0 (100 MHz)} Clk_xbar {/processing_system7_0/FCLK_CLK0 (100 MHz)} Master {/axi_dma_0/M_AXI_S2MM} Slave {/processing_system7_0/S_AXI_HP0} intc_ip {/axi_smc} master_apm {0}}  [get_bd_intf_pins axi_dma_0/M_AXI_S2MM]
# AXI-Lite DMA to the Zynq Processor
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/processing_system7_0/M_AXI_GP0" intc_ip "/ps7_0_axi_periph" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto" }  [get_bd_intf_pins axi_dma_0/S_AXI_LITE]

## Interrupts to the CPU
# GPIO to input 0 of the concatenator block
connect_bd_net [get_bd_pins xlconcat_0/In0] [get_bd_pins axi_gpio_0/ip2intc_irpt]
# DMA to input 1 of the concatenator block
connect_bd_net [get_bd_pins xlconcat_0/In1] [get_bd_pins axi_dma_0/mm2s_introut]
# Concatenator block to the CPU
connect_bd_net [get_bd_pins xlconcat_0/dout] [get_bd_pins processing_system7_0/IRQ_F2P]