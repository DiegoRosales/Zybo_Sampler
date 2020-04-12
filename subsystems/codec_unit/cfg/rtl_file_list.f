####################
## codec_unit RTL filelist
####################

set synthesis_file_list {
    ${core_root}/rtl/codec_unit_top.sv
    ${core_root}/rtl/controller_unit/codec_init_unit.sv
    ${core_root}/rtl/controller_unit/controller_unit_top.sv
    ${core_root}/rtl/controller_unit/i2c_seq_sm.sv
    ${core_root}/rtl/controller_unit/wb_master_controller.sv
    ${core_root}/rtl/register_unit/axi_slave_controller.sv
    ${core_root}/rtl/register_unit/codec_registers.sv
    ${core_root}/rtl/register_unit/register_unit.sv
    ${core_root}/rtl/audio_unit/audio_unit_top.sv
    ${core_root}/rtl/audio_unit/audio_data_serializer.sv
    ${core_root}/rtl/controller_unit/i2c_core/verilog-i2c/rtl/i2c_master.v
    ${core_root}/rtl/controller_unit/i2c_core/verilog-i2c/rtl/i2c_master_wbs_8.v
    ${core_root}/rtl/controller_unit/i2c_core/verilog-i2c/rtl/axis_fifo.v
}