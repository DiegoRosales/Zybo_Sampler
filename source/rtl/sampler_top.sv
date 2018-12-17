//// Sampler Top
module sampler_top #(
  parameter C_S00_AXI_DATA_WIDTH = 32,
  parameter C_S00_AXI_ADDR_WIDTH = 8
) (
  //********************************************//
  //              Board Signals                 //
  //********************************************//
  //// Clocks and Resets
  input wire board_clk,
  input wire reset,

  //// GPIOs
  // Switches
  input wire sw[3:0],
  // Push Buttons
  input wire btn[3:0],
  // LEDs
  output wire led[3:0],

  /////////////////////////////////////////////////
  ///////////// CODEC SIGNALS (Audio) ///////////// 
  // Clocks
  output wire ac_mclk   , // Master Clock
  input  wire ac_bclk   , // I2S Serial Clock
  // Playback
  input  wire ac_pblrc  , // I2S Playback Channel Clock (Left/Right)
  output wire ac_pbdat  , // I2S Playback Data
  // Record
  input  wire ac_recdat , // I2S Recorded Data
  input  wire ac_reclrc , // I2S Recorded Channel Clock (Left/Right)
  // Misc
  output wire ac_muten  , // Digital Enable (Active Low)

  /////////////////////////////////////////////////
  //////////// CODEC SIGNALS (Control) //////////// 
  inout wire i2c_scl,
  inout wire i2c_sda,

  //********************************************//
  //            AXI Clock Domain                //
  //********************************************//
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
	input  wire                                  s00_axi_rready,

  ////////////////////////////////////////////////
  ///////////// AXI4 Stream Signals //////////////
  // Clock and Reset
  input  wire          s_axis_aclk,
  input  wire          s_axis_aresetn,
  // Clock and Reset
  input  wire          m_axis_aclk,
  input  wire          m_axis_aresetn,  

  // Slave Interface Signals (DMA -> CODEC) //
  output wire          s_axis_tready,  // Ready
  input  wire          s_axis_tvalid,  // Data Valid (WR)
  input  wire [63 : 0] s_axis_tdata,   // Data

  // Master Interface Signals (CODEC -> DMA) //
  input  wire          m_axis_tready,  // Ready (RD)
  output wire          m_axis_tvalid,  // Data Valid
  output wire [63 : 0] m_axis_tdata,   // Data
  output wire          m_axis_tlast

  ////////////////////////////////////////////
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
wire        missed_ack;
wire        pll_locked;

wire [3:0]  led_status;


assign led[0] = (sw[0] == 1) ? init_done      : led_status[0];
assign led[1] = (sw[0] == 1) ? init_error     : led_status[1];
assign led[2] = (sw[0] == 1) ? missed_ack     : led_status[2];
assign led[3] = (sw[0] == 1) ? controller_busy: led_status[3];

//assign m_axis_tlast = ~m_axis_tvalid;

codec_unit_top #(
  .C_S00_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
  .C_S00_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
) codec_unit(
  //********************************************//
  //              Board Signals                 //
  //********************************************//
  // Board Clock and Reset
  .board_clk, // 50MHz
  .reset(btn[3]),

  // Misc
  .led_status,
  .test_mode(sw[3]),

  /////////////////////////////////////////////////
  ///////////// CODEC SIGNALS (Audio) ///////////// 
  // Clocks
  .ac_mclk  , // Master Clock
  .ac_bclk  , // I2S Serial Clock
  // Playback
  .ac_pblrc , // I2S Playback Channel Clock (Left/Right)
  .ac_pbdat , // I2S Playback Data
  // Record
  .ac_recdat, // I2S Recorded Data
  .ac_reclrc, // I2S Recorded Channel Clock (Left/Right)
  // Misc
  .ac_muten , // Digital Enable (Active Low)

  /////////////////////////////////////////////////
  //////////// CODEC SIGNALS (Control) //////////// 
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
  .missed_ack,
  
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
  .s00_axi_rready,

  ////////////////////////////////////////////////
  ///////////// AXI4 Stream Signals //////////////
  // Clock and Reset
  .axis_aclk    (s_axis_aclk   ), // input wire s_axis_aclk
  .axis_aresetn (s_axis_aresetn), // input wire s_axis_aresetn

  // Slave Interface Signals (DMA -> CODEC) //
  .s_axis_tready , // Ready
  .s_axis_tvalid , // Data Valid (WR)
  .s_axis_tdata  , // Data

  // Master Interface Signals (CODEC -> DMA) //
  .m_axis_tready , // Ready (RD)
  .m_axis_tvalid , // Data Valid
  .m_axis_tdata  , // Data
  .m_axis_tlast

  );



endmodule
