############################################
## Integration script for the Zybo Sampler
############################################

## From zybo_sampler.cfg
set project_name         ${integ_project_name}_dut
set project_dir          ${integ_project_dir}_dut
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
if {[info exists STAGE_INTEG_ARGS(INTEG_SIM_DEBUG)]} {
  if {$STAGE_INTEG_ARGS(INTEG_SIM_DEBUG) == 1} {
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
## Sampler Hierarchy
################################################

## Instantiate the CODEC controller
integ_utils::create_core_instance -inst_name codec_controller \
                                  -vendor    zybo_sampler \
                                  -library   user \
                                  -name      codec_unit_top \
                                  -version   1.0 \

## Instantiate the Sampler DMA system
set core_config [list \
                    CONFIG.MAX_VOICES                 64 \
                    CONFIG.FETCHER_ENABLE_DEBUG       0  \
                    CONFIG.DMA_REQUESTER_ENABLE_DEBUG 0  \
                    CONFIG.DMA_RECEIVER_ENABLE_DEBUG  0  \
                ]
                
integ_utils::create_core_instance -inst_name sampler_dma \
                                  -vendor    zybo_sampler \
                                  -library   user \
                                  -name      sampler_dma_top \
                                  -version   1.0 \
                                  -config    $core_config


##############################################
## Export IO to the top
##############################################
integ_utils::export -from_instance codec_controller -from_interface board_clk                 -port_name board_clk
integ_utils::export -from_instance codec_controller -from_interface i2c_scl                   -port_name i2c_scl
integ_utils::export -from_instance codec_controller -from_interface i2c_sda                   -port_name i2c_sda
integ_utils::export -from_instance codec_controller -from_interface i2s_master                -port_name codec_i2s
integ_utils::export -from_instance codec_controller -from_interface led_status                -port_name LED
integ_utils::export -from_instance sampler_dma      -from_interface axi4_lite_interface       -port_name sampler_dma_axi4_lite_if
integ_utils::export -from_instance codec_controller -from_interface axi4_lite_interface       -port_name codec_controller_axi4_lite_if
integ_utils::export -from_instance sampler_dma      -from_interface axi_dma_interface         -port_name sampler_dma_axi4_if
integ_utils::export -from_instance codec_controller -from_interface DOWNSTREAM_almost_empty   -port_name DOWNSTREAM_almost_empty
integ_utils::export -from_instance sampler_dma      -from_interface axi_clk                   -port_name axi_clk
integ_utils::export -from_instance codec_controller -from_interface axi_clk                   -port_name axi_clk
integ_utils::export -from_instance codec_controller -from_interface s00_axi_aresetn           -port_name s00_axi_aresetn
integ_utils::export -from_instance codec_controller -from_interface axis_aresetn              -port_name axis_aresetn
integ_utils::export -from_instance codec_controller -from_interface reset                     -port_name board_reset
integ_utils::export -from_instance sampler_dma      -from_interface axi_dma_master_aresetn    -port_name axi_dma_master_aresetn
integ_utils::export -from_instance sampler_dma      -from_interface axi_lite_slave_aresetn    -port_name axi_lite_slave_aresetn
integ_utils::export -from_instance sampler_dma      -from_interface axi_stream_master_aresetn -port_name axi_stream_master_aresetn

##############################################
## Connection
##############################################
### Internal AXI Sampler Connections ###
# AXI Stream
integ_utils::connect -from_instance codec_controller -from_interface axis_interface_slave \
                     -to_instance   sampler_dma      -to_interface   axis_interface_master



## Finalize
# Add memory maps
# Verify design
# Generate RTL and other files
integ_utils::finalize