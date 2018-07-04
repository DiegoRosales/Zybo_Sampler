//// Sampler Top
module sampler_top_tb (
);

//////////////////
// Clocks
//////////////////

reg clk_125 = 1'b0;
reg reset   = 1'b1;

initial begin
forever #(4ns) clk_125 = ~clk_125;
end // initial

initial #(20ns) reset = 1'b0;

sampler_top sampler_top (
  .clk_125(clk_125),
  .reset(reset),

  .sw0(reset),
  .sw1(),
  .sw2(),
  .sw3(),

  .led0(),
  .led1(),
  .led2(),
  .led3(),

  // CODEC I2S Audio Data Signals
  .i2s_bclk(),
  .i2s_wclk(),
  .i2s_data(),

  // CODEC Misc Signals
  .ac_bclk(),
  .ac_mclk(),
  .ac_muten(),
  .ac_pbdat(),
  .ac_pblrc(),
  .ac_recdat(),
  .ac_reclrc(),

  // CODEC I2C Control Signals
  .i2c_scl(),
  .i2c_sda()
);



endmodule
