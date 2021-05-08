############################################
## Integration script for the Zybo Sampler
############################################

## From zybo_sampler.cfg
set project_name         $integ_project_name
set project_dir          $integ_project_dir
set project_top          $integ_project_top
set ip_repo_list         [list ${packaged_cores_dirname} ${user_interfaces_dir}]
set bus_definition_list  [list ${vivado_interface_path}/gpio_v1_0/gpio.xml           \
                               ${vivado_interface_path}/axis_v1_0/axis.xml           \
                               ${vivado_interface_path}/aximm_v1_0/aximm.xml         \
                               ${vivado_interface_path}/interrupt_v1_0/interrupt.xml \
                               ${vivado_interface_path}/clock_v1_0/clock.xml         \
                               ${vivado_interface_path}/reset_v1_0/reset.xml         \
                               ${user_interfaces_dir}/i2s/i2s.xml                    \
                               ]
## Check for a debug flag
set project_debug 0
if {[info exists STAGE_INTEG_ARGS(INTEG_SYNTH_DEBUG)]} {
  if {$STAGE_INTEG_ARGS(INTEG_SYNTH_DEBUG) == 1} {
    puts "Setting the project debug flag"
    set project_debug 1
  }
}

## Initialize the packaging
integ_utils::init -project_name          $project_name           \
                  -project_dir           $project_dir            \
                  -project_top           $project_top            \
                  -part_number           $FPGA_PART_NUMBER  \
                  -ip_repo_list          $ip_repo_list           \
                  -bus_def_xml_list      $bus_definition_list    \
                  -board_part            $BOARD_PART_NUMBER \
                  -debug                 $project_debug

################################################
## Top Hierarchy
################################################
## GPIO
# Properties:
# - Two 4-bit GPIOs (4 switches and 4 push buttons)
# - Enable interrupts
# - GPIO1 -> Switches
# - GPIO2 -> Push Buttons
set core_config [list \
                    CONFIG.C_GPIO_WIDTH          {4}          \
                    CONFIG.C_GPIO2_WIDTH         {4}          \
                    CONFIG.C_IS_DUAL             {1}          \
                    CONFIG.C_ALL_INPUTS          {1}          \
                    CONFIG.C_ALL_INPUTS_2        {1}          \
                    CONFIG.C_INTERRUPT_PRESENT   {1}          \
                    CONFIG.GPIO_BOARD_INTERFACE  {sws_4bits}  \
                    CONFIG.GPIO2_BOARD_INTERFACE {btns_4bits} \
                ]

integ_utils::create_core_instance -inst_name axi_gpio_0 \
                                  -vendor    xilinx.com \
                                  -library   ip \
                                  -name      axi_gpio \
                                  -version   2.0 \
                                  -config    $core_config


################################################
## Sampler Hierarchy
################################################
set sampler_hier sampler
## Create a new hierarchy
integ_utils::create_hierarchy_level -name $sampler_hier

## Instantiate the CODEC controller
integ_utils::create_core_instance -inst_name codec_controller \
                                  -vendor    zybo_sampler \
                                  -library   user \
                                  -name      codec_unit_top \
                                  -version   1.0 \
                                  -hierarchy $sampler_hier

## Instantiate the Sampler DMA system
set core_config [list \
                    CONFIG.MAX_VOICES                 64 \
                    CONFIG.FETCHER_ENABLE_DEBUG       0  \
                    CONFIG.DMA_REQUESTER_ENABLE_DEBUG 0  \
                    CONFIG.DMA_RECEIVER_ENABLE_DEBUG  0  \
                    CONFIG.C_AXI_STREAM_TDATA_WIDTH   32 \
                    CONFIG.C_AXI_STREAM_TUSER_WIDTH   8  \
                ]
                
integ_utils::create_core_instance -inst_name sampler_dma \
                                  -vendor    zybo_sampler \
                                  -library   user \
                                  -name      sampler_dma_top \
                                  -version   1.0 \
                                  -hierarchy $sampler_hier \
                                  -config    $core_config

## Instantiate the Sampler Mixer
set core_config [list \
                    CONFIG.ENABLE_SAMPLER_MIXER_DEBUG 0  \
                    CONFIG.C_AXI_STREAM_TDATA_WIDTH   32 \
                    CONFIG.C_AXI_STREAM_TUSER_WIDTH   8  \
                ]
                
integ_utils::create_core_instance -inst_name sampler_mixer \
                                  -vendor    zybo_sampler \
                                  -library   user \
                                  -name      sampler_mixer \
                                  -version   1.0 \
                                  -hierarchy $sampler_hier \
                                  -config    $core_config



################################################
## Zynq CPU Hierarchy
################################################
## Create a new hierarchy
set zynq_cpu_hier zynq_cpu
integ_utils::create_hierarchy_level -name $zynq_cpu_hier

## Zynq CPU
# Enable F2P (Fabric to Processing Unit) Interrupts
# Enable the High Performance AXI Streaming port for DMA (HP0)
# Enable CLK0 output and set it to 100MHz
set core_config [list \
                    CONFIG.PCW_USE_FABRIC_INTERRUPT {1}       \
                    CONFIG.PCW_IRQ_F2P_INTR         {1}       \
                    CONFIG.PCW_USE_S_AXI_HP0        {1}       \
                    CONFIG.PCW_S_AXI_HP0_DATA_WIDTH {64}      \
                    CONFIG.PCW_EN_CLK0_PORT {1}               \
                    CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {125} \
                ]

# Apply the Zynq presets for the Zybo
# INFO - The Board Pin information for the board automation is under board_files/zybo/B.3/*.xml
set core_board_preset [list \
                        apply_board_preset "1"        \
                        make_external "FIXED_IO, DDR" \
                        Master "Disable"              \
                        Slave "Disable"               \
                      ]

integ_utils::create_core_instance -inst_name          zynq \
                                  -vendor             xilinx.com \
                                  -library            ip \
                                  -name               processing_system7 \
                                  -version            5.5 \
                                  -hierarchy          $zynq_cpu_hier \
                                  -config             $core_config \
                                  -apply_board_preset $core_board_preset

## AXI Smart Connect for the DMA
# 1 Slave Interface
set core_config [list \
                    CONFIG.NUM_SI {1}  \
                ]

integ_utils::create_core_instance -inst_name axi_smartconnect_zynq \
                                  -vendor    xilinx.com \
                                  -library   ip \
                                  -name      smartconnect \
                                  -version   1.0 \
                                  -hierarchy $zynq_cpu_hier \
                                  -config    $core_config

## AXI Interconnect for the AXI-lite slaves
# 3 Master Interfaces
set core_config [list \
                    CONFIG.NUM_MI {3}  \
                ]

integ_utils::create_core_instance -inst_name axi_interconnect_zynq \
                                  -vendor    xilinx.com \
                                  -library   ip \
                                  -name      axi_interconnect \
                                  -version   2.1 \
                                  -hierarchy $zynq_cpu_hier \
                                  -config    $core_config

## Concat Block for the interrupt signals
# 2 Interrupts
set core_config [list \
                    CONFIG.NUM_PORTS 2  \
                ]

integ_utils::create_core_instance -inst_name intr_concat_zynq \
                                  -vendor    xilinx.com \
                                  -library   ip \
                                  -name      xlconcat \
                                  -version   2.1 \
                                  -hierarchy $zynq_cpu_hier \
                                  -config    $core_config

## CPU Reset Generation
integ_utils::create_core_instance -inst_name cpu_reset_gen \
                                  -vendor    xilinx.com \
                                  -library   ip \
                                  -name      proc_sys_reset \
                                  -version   5.0 \
                                  -hierarchy $zynq_cpu_hier \


##############################################
## Export IO to the top
##############################################
integ_utils::export -from_instance ${sampler_hier}/codec_controller -from_interface board_clk  -port_name board_clk
integ_utils::export -from_instance ${sampler_hier}/codec_controller -from_interface i2c_scl    -port_name i2c_scl
integ_utils::export -from_instance ${sampler_hier}/codec_controller -from_interface i2c_sda    -port_name i2c_sda
integ_utils::export -from_instance ${sampler_hier}/codec_controller -from_interface i2s_master -port_name codec_i2s
integ_utils::export -from_instance ${sampler_hier}/codec_controller -from_interface led_status -port_name LED
integ_utils::export -from_instance axi_gpio_0                       -from_interface GPIO       -port_name SW
integ_utils::export -from_instance axi_gpio_0                       -from_interface GPIO2      -port_name BTN

##############################################
## Connection
##############################################

### AXI Lite connections ###
# Sampler DMA
integ_utils::connect -from_instance ${zynq_cpu_hier}/axi_interconnect_zynq -from_interface M00_AXI \
                     -to_instance   ${sampler_hier}/sampler_dma            -to_interface   axi4_lite_interface
# CODEC Controller
integ_utils::connect -from_instance ${zynq_cpu_hier}/axi_interconnect_zynq -from_interface M01_AXI \
                     -to_instance   ${sampler_hier}/codec_controller       -to_interface   axi4_lite_interface
# GPIO
integ_utils::connect -from_instance ${zynq_cpu_hier}/axi_interconnect_zynq -from_interface M02_AXI \
                     -to_instance   axi_gpio_0                             -to_interface   S_AXI

### AXI DMA Connections ###
integ_utils::connect -from_instance ${zynq_cpu_hier}/axi_smartconnect_zynq -from_interface S00_AXI \
                     -to_instance   ${sampler_hier}/sampler_dma            -to_interface   axi_dma_interface

### Interrupt Connections ###
# GPIO
integ_utils::connect -from_instance ${zynq_cpu_hier}/intr_concat_zynq      -from_interface In0 \
                     -to_instance   axi_gpio_0                             -to_interface   ip2intc_irpt

# Codec Controller
integ_utils::connect -from_instance ${zynq_cpu_hier}/intr_concat_zynq      -from_interface In1 \
                     -to_instance   ${sampler_hier}/codec_controller       -to_interface   DOWNSTREAM_almost_empty


### Internal AXI Sampler Connections ###
# DMA Controller --> Sampler Mixer
integ_utils::connect -from_instance ${sampler_hier}/sampler_dma           -from_interface axis_interface_master \
                     -to_instance   ${sampler_hier}/sampler_mixer         -to_interface   axis_interface_slave
# Sampler Mixer --> CODEC Controller
integ_utils::connect -from_instance ${sampler_hier}/sampler_mixer         -from_interface axis_interface_master \
                     -to_instance   ${sampler_hier}/codec_controller      -to_interface   axis_interface_slave


### Internal AXI Zynq Connections ###
# AXI DMA
integ_utils::connect -from_instance ${zynq_cpu_hier}/axi_smartconnect_zynq -from_interface M00_AXI \
                     -to_instance   ${zynq_cpu_hier}/zynq                  -to_interface   S_AXI_HP0

# AXI Lite
integ_utils::connect -from_instance ${zynq_cpu_hier}/axi_interconnect_zynq -from_interface S00_AXI \
                     -to_instance   ${zynq_cpu_hier}/zynq                  -to_interface   M_AXI_GP0

# Interrupts
integ_utils::connect -from_instance ${zynq_cpu_hier}/intr_concat_zynq      -from_interface dout \
                     -to_instance   ${zynq_cpu_hier}/zynq                  -to_interface   IRQ_F2P


### Clocking ###
set clock_destinations [list                               \
  ${sampler_hier}/sampler_dma             axi_clk          \
  ${sampler_hier}/codec_controller        axi_clk          \
  ${sampler_hier}/sampler_mixer           clk              \
  ${zynq_cpu_hier}/axi_smartconnect_zynq  aclk             \
  ${zynq_cpu_hier}/axi_interconnect_zynq  ACLK             \
  ${zynq_cpu_hier}/axi_interconnect_zynq  M00_ACLK         \
  ${zynq_cpu_hier}/axi_interconnect_zynq  M01_ACLK         \
  ${zynq_cpu_hier}/axi_interconnect_zynq  M02_ACLK         \
  ${zynq_cpu_hier}/axi_interconnect_zynq  S00_ACLK         \
  ${zynq_cpu_hier}/zynq                   M_AXI_GP0_ACLK   \
  ${zynq_cpu_hier}/zynq                   S_AXI_HP0_ACLK   \
  ${zynq_cpu_hier}/cpu_reset_gen          slowest_sync_clk \
  axi_gpio_0                              s_axi_aclk       \
]

foreach {dest_instance dest_port} $clock_destinations {
  integ_utils::connect -from_instance ${zynq_cpu_hier}/zynq    -from_interface FCLK_CLK0 \
                       -to_instance   ${dest_instance}         -to_interface   ${dest_port}
}

### Reset ###
## Peripheral Reset
set peripheral_reset_destinations [list                             \
  ${zynq_cpu_hier}/axi_interconnect_zynq  M00_ARESETN               \
  ${zynq_cpu_hier}/axi_interconnect_zynq  M01_ARESETN               \
  ${zynq_cpu_hier}/axi_interconnect_zynq  M02_ARESETN               \
  ${zynq_cpu_hier}/axi_interconnect_zynq  S00_ARESETN               \
  ${sampler_hier}/codec_controller        s00_axi_aresetn           \
  ${sampler_hier}/codec_controller        axis_aresetn              \
  ${sampler_hier}/sampler_mixer           reset_n                   \
  ${sampler_hier}/sampler_dma             axi_dma_master_aresetn    \
  ${sampler_hier}/sampler_dma             axi_lite_slave_aresetn    \
  ${sampler_hier}/sampler_dma             axi_stream_master_aresetn \
  axi_gpio_0                              s_axi_aresetn             \
]

foreach {dest_instance dest_port} $peripheral_reset_destinations {
  integ_utils::connect -from_instance ${zynq_cpu_hier}/cpu_reset_gen  -from_interface peripheral_aresetn \
                       -to_instance   ${dest_instance}                -to_interface   ${dest_port}
}

## Interconnect Reset
set interconn_reset_destinations [list \
  ${zynq_cpu_hier}/axi_interconnect_zynq  ARESETN \
  ${zynq_cpu_hier}/axi_smartconnect_zynq  aresetn \
]

foreach {dest_instance dest_port} $interconn_reset_destinations {
  integ_utils::connect -from_instance ${zynq_cpu_hier}/cpu_reset_gen  -from_interface interconnect_aresetn \
                       -to_instance   ${dest_instance}                -to_interface   ${dest_port}
}

## Zynq Reset to the reset generator
integ_utils::connect -from_instance ${zynq_cpu_hier}/zynq          -from_interface FCLK_RESET0_N \
                     -to_instance   ${zynq_cpu_hier}/cpu_reset_gen -to_interface ext_reset_in

## Finalize
# Add memory maps
# Verify design
# Generate RTL and other files
integ_utils::finalize -output integ_output