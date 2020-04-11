####################
## codec_unit RTL filelist
####################

set synthesis_file_list {
    codec_unit_top.sv
    controller_unit/codec_init_unit.sv
    controller_unit/controller_unit_top.sv
    controller_unit/i2c_seq_sm.sv
    controller_unit/wb_master_controller.sv
    register_unit/axi_slave_controller.sv
    register_unit/codec_registers.sv
    register_unit/register_unit.sv
    audio_unit/audio_unit_top.sv
    audio_unit/audio_data_serializer.sv
    pulse_synchronizer.sv
    synchronizer.sv
    controller_unit/i2c_core/verilog-i2c/rtl/i2c_master.v
    controller_unit/i2c_core/verilog-i2c/rtl/i2c_master_wbs_8.v
    controller_unit/i2c_core/verilog-i2c/rtl/axis_fifo.v
}