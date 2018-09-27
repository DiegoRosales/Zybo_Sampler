//// Sampler Top
module sampler_top #(
  parameter C_S00_AXI_DATA_WIDTH = 32,
  parameter C_S00_AXI_ADDR_WIDTH = 8
) (
  input wire board_clk,
  input wire reset,

  // Switches
  input wire sw0,
  input wire sw1,
  input wire sw2,
  input wire sw3,

  // Push Buttons
  input wire btn0,
  input wire btn1,
  input wire btn2,
  input wire btn3,

  // LEDs
  output wire led0,
  output wire led1,
  output wire led2,
  output wire led3,

  // CODEC I2S Audio Data Signals
  //output wire i2s_bclk,
  //output wire i2s_wclk,
  //output wire i2s_data,

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
  inout wire i2c_sda,

  //---- AXI Clock Domain ----//
  // Ports of Axi Slave Bus Interface S00_AXI
	input  wire                                  s00_axi_aclk,
	input  wire                                  s00_axi_aresetn,
	input  wire [C_S00_AXI_ADDR_WIDTH-1 : 0]     s00_axi_awaddr,
	input  wire [2 : 0]                          s00_axi_awprot,
	input  wire                                  s00_axi_awvalid,
	output wire                                  s00_axi_awready,
	input  wire [C_S00_AXI_DATA_WIDTH-1 : 0]     s00_axi_wdata,
	input  wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
	input  wire                                  s00_axi_wvalid,
	output wire                                  s00_axi_wready,
	output wire [1 : 0]                          s00_axi_bresp,
	output wire                                  s00_axi_bvalid,
	input  wire                                  s00_axi_bready,
	input  wire [C_S00_AXI_ADDR_WIDTH-1 : 0]     s00_axi_araddr,
	input  wire [2 : 0]                          s00_axi_arprot,
	input  wire                                  s00_axi_arvalid,
	output wire                                  s00_axi_arready,
	output wire [C_S00_AXI_DATA_WIDTH-1 : 0]     s00_axi_rdata,
	output wire [1 : 0]                          s00_axi_rresp,
	output wire                                  s00_axi_rvalid,
	input  wire                                  s00_axi_rready
);

wire       output_en    = 0;
wire [4:0] frequency    = 0;
wire       apply_config = 0;

wire       codec_rd_en     = 0;
wire       codec_wr_en     = 0;
wire       codec_reg_addr  = 0;
wire [7:0] codec_data_in   = 0;
wire [7:0] codec_data_out;
wire       controller_busy;

wire       i2c_ctrl_rd   = 0;
wire [2:0] i2c_ctrl_addr = 0;
wire [7:0] i2c_ctrl_data;

wire [47:0] data_in      = 0;
wire        data_wr      = 0;

wire        init_done;
wire        init_error;
wire pll_locked;


assign led0 = init_done;
assign led1 = init_error;
assign led3 = pll_locked;

codec_unit_top #(
  .C_S00_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
  .C_S00_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
) codec_unit(
  //********************************************//
  //              Board Signals                 //
  //********************************************//
  // Board Clock and Reset
  .board_clk, // 50MHz
  .reset(btn3),

  ///////////////////////////////////////////////
  ///////////////// I2S SIGNALS ///////////////// 
 // .i2s_bclk,
 // .i2s_wclk,
 // .i2s_data,

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
  .codec_data_in,
  .codec_data_out,

  ///////////////////////////////////////////////
  /////////// I2C CONTROLLER SIGNALS ////////////
  .i2c_ctrl_rd,
  .i2c_ctrl_addr,
  .i2c_ctrl_data,
  .controller_busy,
  .init_done,
  .init_error,
  
  ///////////////////////////////////////////////
  ///////////// CODEC DATA SIGNALS //////////////    
  .data_in, // Audio Data
  .data_wr, // Data Write to the data FIFO

  ///////////////////////////////////////////////
  ////////// CODEC UNIT STATUS SIGNALS ////////// 
  .pll_locked,

  //********************************************//
  //---- AXI Clock Domain ----//
  .s00_axi_aclk,
  .s00_axi_aresetn,
  .s00_axi_awaddr,
  .s00_axi_awprot,
  .s00_axi_awvalid,
  .s00_axi_awready,
  .s00_axi_wdata,
  .s00_axi_wstrb,
  .s00_axi_wvalid,
  .s00_axi_wready,
  .s00_axi_bresp,
  .s00_axi_bvalid,
  .s00_axi_bready,
  .s00_axi_araddr,
  .s00_axi_arprot,
  .s00_axi_arvalid,
  .s00_axi_arready,
  .s00_axi_rdata,
  .s00_axi_rresp,
  .s00_axi_rvalid,
  .s00_axi_rready

  );



endmodule
