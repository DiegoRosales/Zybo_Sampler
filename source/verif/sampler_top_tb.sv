//// Sampler Top
module sampler_top_tb (
);

//////////////////
// Clocks
//////////////////

reg clk_125  = 1'b0;
reg clk_50   = 1'b0;
reg reset    = 1'b0;
wire reset_n = ~reset;
initial force sampler_top.codec_unit.controller_unit.i2c_sda_i = 1'b0;
initial forever #(4ns) clk_125 = ~clk_125;
initial forever #(10ns) clk_50 = ~clk_50;

initial begin
   #(1ns) reset   = 1'b1;
   #(200ns) reset = 1'b0;
   #(500000ns) force   sampler_top.codec_unit.register_unit.axi_slave_controller_inst.codec_registers.controller_reset = 1'b1;
   #(500100ns) release sampler_top.codec_unit.register_unit.axi_slave_controller_inst.codec_registers.controller_reset;
   //#(128200ns) force   sampler_top.codec_unit.register_unit.axi_slave_controller_inst.codec_registers.controller_reset = 1'b0;
   //#(128300ns) release sampler_top.codec_unit.register_unit.axi_slave_controller_inst.codec_registers.controller_reset;
end

wire i2c_sda;
wire i2c_scl;

wire i2c_sda_pin;
wire i2c_sda_i;
wire i2c_sda_t;
assign i2c_sda_pin = 1'b0;
assign i2c_sda_t   = 1'b1;//(i2c_sda_i === 1'b0) ? 1'b1 : 1'b0;

wire codec_mclk;
wire lr_clk;
reg [5:0] counter = 'h0;
always @(posedge codec_mclk) counter <= counter + 1;
assign lr_clk = &counter;


IOBUF sda_iobuf (
  .I  (i2c_sda_pin), 
  .IO (i2c_sda  ), 
  .O  (i2c_sda_i), 
  .T  (i2c_sda_t)
  ); 

pullup(i2c_sda);
pullup(i2c_scl);

sampler_top sampler_top (
  .board_clk(clk_125),
  .reset(reset),
  .s00_axi_aclk(clk_125),
  .s00_axi_aresetn(reset_n),

  .sw({reset, reset, reset, reset}),

  .led(),

  .btn({reset, reset, reset, reset}),

  // CODEC I2S Audio Data Signals
 // .i2s_bclk(),
 // .i2s_wclk(),
 // .i2s_data(),

  // CODEC Misc Signals
  .ac_bclk(codec_mclk), // Loopback
  .ac_mclk(codec_mclk),
  .ac_muten(),
  .ac_pbdat(),
  .ac_pblrc(lr_clk),
  .ac_recdat(),
  .ac_reclrc(),

  // CODEC I2C Control Signals
  .i2c_scl,
  .i2c_sda
);



endmodule
