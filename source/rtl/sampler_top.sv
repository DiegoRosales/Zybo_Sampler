//// Sampler Top
module sampler_top (
  input wire clk_125,
  input wire reset,

  input wire sw0,
  input wire sw1,
  input wire sw2,
  input wire sw3,

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
  inout wire i2c_scl,
  inout wire i2c_sda
);

wire       output_en    = 0;
wire [4:0] frequency    = 0;
wire       apply_config = 0;

wire       codec_rd_en     = 0;
wire       codec_wr_en     = 0;
wire       codec_reg_addr  = 0;
wire [7:0] codec_data_wr   = 0;
wire [7:0] codec_data_rd;
wire       controller_busy;

wire       i2c_ctrl_rd   = 0;
wire [2:0] i2c_ctrl_addr = 0;
wire [7:0] i2c_ctrl_data;

wire [47:0] data_in      = 0;
wire        data_wr      = 0;

wire pll_locked;

codec_unit_top codec_unit(
  //********************************************//
  //              Board Signals                 //
  //********************************************//
  // Board Clock and Reset
  .clk(clk_125), // 125MHz
  .reset(sw0),

  ///////////////////////////////////////////////
  ///////////////// I2S SIGNALS ///////////////// 
  .i2s_bclk,
  .i2s_wclk,
  .i2s_data,

  ///////////////////////////////////////////////
  ///////////////// I2C SIGNALS ///////////////// 
  .i2c_scl,
  .i2c_sda,

  //********************************************//

  //********************************************//
  //            AXI Clock Domain                //
  //********************************************//

  // AXI Clock
  .axi_clk(clk_125),

  ///////////////////////////////////////////////
  //////////// CODEC CONTROL SIGNALS ////////////
  .output_en,    // CODEC Output Enable

  .frequency,    // Sample Frequency Select
  .apply_config, // Apply Configuration

  ///////////////////////////////////////////////
  /////////// CODEC REGISTER SIGNALS ////////////
  .codec_rd_en,
  .codec_wr_en,
  .codec_reg_addr,
  .codec_data_wr,
  .codec_data_rd,

  ///////////////////////////////////////////////
  /////////// I2C CONTROLLER SIGNALS ////////////
  .i2c_ctrl_rd,
  .i2c_ctrl_addr,
  .i2c_ctrl_data,
  .controller_busy,
  
  ///////////////////////////////////////////////
  ///////////// CODEC DATA SIGNALS //////////////    
  .data_in, // Audio Data
  .data_wr, // Data Write to the data FIFO

  ///////////////////////////////////////////////
  ////////// CODEC UNIT STATUS SIGNALS ////////// 
  .pll_locked

  //********************************************//
  );



endmodule
