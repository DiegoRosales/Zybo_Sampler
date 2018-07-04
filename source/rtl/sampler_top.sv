//// Sampler Top
module sampler_top (
  input wire clk_125,
  input wire reset,

  input wire sw1,
  input wire sw2,
  input wire sw3,
  input wire sw0,

  output wire led0,
  output wire led1,
  output wire led2,
  output wire led3,

  // CODEC I2S Audio Data Signals
  output wire i2s_bclk,
  output wire i2s_wclk,
  output wire i2s_data,

  // CODEC Misc Signals
  output wire ac_bclk,
  output wire ac_mclk,
  output wire ac_muten,
  output wire ac_pbdat,
  output wire ac_pblrc,
  output wire ac_recdat,
  output wire ac_reclrc,
  
  // CODEC I2C Control Signals
  output wire i2c_scl,
  inout  wire i2c_sda
);

codec_unit_top codec_unit(
  .clk(clk),
  .reset(reset),
  .i2s_bclk,
  .i2s_wclk,
  .i2s_data,
  .i2c_scl,
  .i2c_sda
  );



endmodule
