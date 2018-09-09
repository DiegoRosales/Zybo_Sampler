//// Sampler Top
module sampler_top_tb (
);

//////////////////
// Clocks
//////////////////

reg clk_125 = 1'b0;
reg clk_50  = 1'b0;
reg reset   = 1'b0;

initial force sampler_top.codec_unit.controller_unit.i2c_sda_i = 1'b0;
initial forever #(4ns) clk_125 = ~clk_125;
initial forever #(10ns) clk_50 = ~clk_50;

initial begin
   #(1ns) reset   = 1'b1;
   #(200ns) reset = 1'b0;
end

wire i2c_sda;
wire i2c_scl;

wire i2c_sda_pin;
wire i2c_sda_i;
wire i2c_sda_t;
assign i2c_sda_pin = 1'b0;
assign i2c_sda_t   = 1'b1;//(i2c_sda_i === 1'b0) ? 1'b1 : 1'b0;

IOBUF sda_iobuf (
  .I  (i2c_sda_pin), 
  .IO (i2c_sda  ), 
  .O  (i2c_sda_i), 
  .T  (i2c_sda_t)
  ); 

pullup(i2c_sda);
pullup(i2c_scl);

sampler_top sampler_top (
  .board_clk(clk_50),
  .reset(reset),

  .sw0(reset),
  .sw1(),
  .sw2(),
  .sw3(reset),

  .led0(),
  .led1(),
  .led2(),
  .led3(),

  .btn0(),
  .btn1(),
  .btn2(),
  .btn3(reset),

  // CODEC I2S Audio Data Signals
 // .i2s_bclk(),
 // .i2s_wclk(),
 // .i2s_data(),

  // CODEC Misc Signals
  .ac_bclk(),
  .ac_mclk(),
  .ac_muten(),
  .ac_pbdat(),
  .ac_pblrc(),
  .ac_recdat(),
  .ac_reclrc(),

  // CODEC I2C Control Signals
  .i2c_scl,
  .i2c_sda
);



endmodule
