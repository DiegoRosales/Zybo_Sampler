set synthesis_file_list {
    ${project_root}/source/rtl/codec_unit/codec_unit_top.sv
    ${project_root}/source/rtl/codec_unit/controller_unit/codec_init_unit.sv
    ${project_root}/source/rtl/codec_unit/controller_unit/controller_unit_top.sv
    ${project_root}/source/rtl/codec_unit/controller_unit/i2c_seq_sm.sv
    ${project_root}/source/rtl/codec_unit/controller_unit/wb_master_controller.sv
    ${project_root}/source/rtl/codec_unit/register_unit/axi_slave_controller.sv
    ${project_root}/source/rtl/codec_unit/register_unit/codec_registers.sv
    ${project_root}/source/rtl/codec_unit/register_unit/register_unit.sv
    ${project_root}/source/rtl/codec_unit/audio_unit/audio_unit_top.sv
    ${project_root}/source/rtl/codec_unit/audio_unit/audio_data_serializer.sv
    ${project_root}/source/rtl/codec_unit/pulse_synchronizer.sv
    ${project_root}/source/rtl/codec_unit/synchronizer.sv
    ${project_root}/source/rtl/sampler_top.sv
    ${project_root}/source/rtl/codec_unit/controller_unit/i2c_core/verilog-i2c/rtl/i2c_master.v
    ${project_root}/source/rtl/codec_unit/controller_unit/i2c_core/verilog-i2c/rtl/i2c_master_wbs_8.v
    ${project_root}/source/rtl/codec_unit/controller_unit/i2c_core/verilog-i2c/rtl/axis_fifo.v
    ${project_root}/source/rtl/sampler_dma_unit/sampler_dma_top.sv
    ${project_root}/source/rtl/sampler_dma_unit/sampler_dma_S_AXI_INTR.v
    ${project_root}/source/rtl/sampler_dma_unit/sampler_dma_AXI_LITE_SLAVE.v
    ${project_root}/source/rtl/sampler_dma_unit/sampler_dma_AXI_DMA_MASTER.v
    ${project_root}/source/rtl/sampler_dma_unit/sampler_dma_AXI_STREAM_MASTER.v
}
## This should be populated when the collateral IPs are generated
set generated_ip_file_list {
}
     #${project_root}/source/generated_ips/codec_audio_clock_generator/codec_audio_clock_generator.xci

set simulation_file_list {
    ${project_root}/source/verif/sampler_top_tb.sv
}