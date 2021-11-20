///////////////////////////////////////////////////////////
// Codec Unit Top                                        //
// Author: Diego Rosales                                 //
///////////////////////////////////////////////////////////
// Description                                           //
//////////////                                           //
// This module controls the CODEC in the Digilent Zybo   //
// The CODEC Part Number is: SSM2603                     //
// This module translates instructions into rd/wr        //
// sequences for the CODEC for easy interfacing          //
// This module is also responsible for transmitting the  //
// audio stream to the CODEC                             //
///////////////////////////////////////////////////////////
// Rev 0.1 - Init                                        //
///////////////////////////////////////////////////////////

`default_nettype none

module codec_unit_top #(
  parameter C_S00_AXI_DATA_WIDTH = 32,
  parameter C_S00_AXI_ADDR_WIDTH = 8
) (
  //********************************************//
  //            Board Clock Domain              //
  //********************************************//
  ///////////////////////////////////////////////
  /////////////// CLOCK AND RESET /////////////// 
  input wire board_clk, // 125MHz
  input wire reset_n,

  // Misc
  output wire [3:0] led_status,

  /////////////////////////////////////////////////
  ///////////// CODEC SIGNALS (Audio) ///////////// 
  // Clocks
  output wire ac_mclk, // Master Clock
  input  wire ac_bclk, // I2S Serial Clock
  // Playback
  input  wire ac_pblrc, // I2S Playback Channel Clock (Left/Right)
  output wire ac_pbdat, // I2S Playback Data
  // Record
  input  wire ac_recdat, // I2S Recorded Data
  input  wire ac_reclrc, // I2S Recorded Channel Clock (Left/Right)
  // Misc
  output wire ac_muten, // Digital Enable (Active Low)

  /////////////////////////////////////////////////
  //////////// CODEC SIGNALS (Control) //////////// 
  inout wire i2c_scl,
  inout wire i2c_sda,


  //********************************************//
  //            AXI Clock Domain                //
  //********************************************//
  input wire axi_clk,

  //////////////////////////////////////////////
  ///////////// AXI4-Lite Signals //////////////
  // Ports of Axi Slave Bus Interface S00_AXI
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
  ///////////// AXI Stream Signals ///////////////
  // Clock and Reset
  input  wire          axis_aresetn,

  // Slave Interface Signals (DMA -> CODEC) //
  output wire          s_axis_tready,  // Ready
  input  wire          s_axis_tvalid,  // Data Valid (WR)
  input  wire [32 : 0] s_axis_tdata,   // Data

  // Master Interface Signals (CODEC -> DMA) //
  input  wire          m_axis_tready,  // Ready (RD)
  output wire          m_axis_tvalid,  // Data Valid
  output wire [63 : 0] m_axis_tdata,   // Data
  output wire          m_axis_tlast,

  ///////////////////////////
  //// Interrupt Signals ////  
  output wire DOWNSTREAM_almost_empty

);

wire [47:0] fifo_data;
wire fifo_rd;
wire mmcm_locked;
wire clk_24mhz;
wire clk_125mhz;
wire clk_44_1_24b;
wire clk_48_16b;
wire clk_48_24b;
wire fifo_empty;
wire i2s_busy;
wire board_clk_bufg;

// I2C
wire        i2c_scl_i;
wire        i2c_scl_o;
wire        i2c_scl_t;
wire        i2c_sda_i;
wire        i2c_sda_o;
wire        i2c_sda_t;

// Synchronizer
wire       codec_rd_en_SYNC;
wire       codec_wr_en_SYNC;
wire [7:0] codec_reg_addr_SYNC;
wire [7:0] codec_data_in_SYNC;
wire       controller_busy_SYNC; 
wire       codec_data_out_valid_SYNC;
wire [7:0] codec_data_out_SYNC; 
wire [2:0] i2c_ctrl_addr_SYNC;
wire       i2c_ctrl_rd_SYNC;
wire [7:0] i2c_ctrl_data_SYNC;

// Interface between the register unit and the design
wire        clear_codec_i2c_data_wr;
wire        clear_codec_i2c_data_rd;
wire        codec_i2c_data_wr;
wire        codec_i2c_data_rd;
wire        controller_busy;
wire        codec_init_done;
wire        data_in_valid;
wire        missed_ack;
wire [31:0] codec_i2c_addr;
wire [31:0] codec_i2c_wr_data;
wire [31:0] codec_i2c_rd_data;
wire        update_codec_i2c_rd_data;
wire        controller_reset_n;
wire        sw_reset;

///////////////////////////

wire [63:0] audio_data_out;
wire [3:0]  heartbeat;
wire        test_mode;
wire        justification;

///////////////////////////

wire [31:0] DOWNSTREAM_axis_wr_data_count;
wire [31:0] UPSTREAM_axis_rd_data_count;
wire [31:0] DOWNSTREAM_axis_rd_data_count;
wire [31:0] UPSTREAM_axis_wr_data_count;
wire [63:0] s_axis_tdata_int;
wire init_done;
wire init_error;

assign codec_init_done    = init_done | init_error;
assign controller_reset_n = ~sw_reset && reset_n;

assign s_axis_tdata_int = {16'h0000, s_axis_tdata[31:16], 16'h0000, s_axis_tdata[15:0]};

assign led_status = heartbeat;

assign test_mode     = 1'b0;
assign justification = 1'b0;

// IOBUFs for the I2C interface
IOBUF sda_iobuf (
  .I  ( i2c_sda_o ), 
  .IO ( i2c_sda   ), 
  .O  ( i2c_sda_i ), 
  .T  ( i2c_sda_t )
  );   

IOBUF scl_iobuf (
  .I  ( i2c_scl_o ), 
  .IO ( i2c_scl   ), 
  .O  ( i2c_scl_i ), 
  .T  ( i2c_scl_t )
  );   

BUFGCE board_clk_bufg_inst (
  .I  ( board_clk      ),
  .O  ( board_clk_bufg )
);

controller_unit_top controller_unit(
  .clk                     ( axi_clk            ),
  .reset_n                 ( controller_reset_n ),

  // CODEC RW signals
  .codec_rd_en             ( codec_i2c_data_rd         ), // Input
  .codec_wr_en             ( codec_i2c_data_wr         ), // Input
  .codec_reg_addr          ( codec_i2c_addr[7:0]       ), // Input
  .codec_data_in           ( codec_i2c_wr_data[8:0]    ), // Input
  .codec_data_out          ( codec_i2c_rd_data         ), // Output
  .codec_data_out_valid    ( update_codec_i2c_rd_data  ), // Output
  .controller_busy         ( controller_busy           ), // Output
  .missed_ack              ( missed_ack                ), //

  .init_done               ( init_done  ),
  .init_error              ( init_error ),

  // I2C Signals
  .i2c_scl_i               ( i2c_scl_i ),
  .i2c_scl_o               ( i2c_scl_o ),
  .i2c_scl_t               ( i2c_scl_t ),
  .i2c_sda_i               ( i2c_sda_i ),
  .i2c_sda_o               ( i2c_sda_o ),
  .i2c_sda_t               ( i2c_sda_t )
);


audio_unit_top audio_unit_top (
  .clock   ( board_clk_bufg ),
  .reset_n ( reset_n        ),

  /////////////////////////////////////////////////
  ///////////// CODEC SIGNALS (Audio) ///////////// 
  // Clocks
  .ac_mclk   ( ac_mclk   ), // Master Clock
  .ac_bclk   ( ac_bclk   ), // I2S Serial Clock
  // Playback
  .ac_pblrc  ( ac_pblrc  ), // I2S Playback Channel Clock (Left/Right)
  .ac_pbdat  ( ac_pbdat  ), // I2S Playback Data
  // Record
  .ac_recdat ( ac_recdat ), // I2S Recorded Data
  .ac_reclrc ( ac_reclrc ), // I2S Recorded Channel Clock (Left/Right)
  // Misc
  .ac_muten  ( ac_muten  ), // Digital Enable (Active Low)

  ///////////////////////////////////////////////////
  ///////////// Control Signals (Audio) ///////////// 
  .test_mode     ( test_mode     ),
  .justification ( justification ),

  ////////////////////////////////////////////////
  ///////////// AXI4 Stream Signals //////////////
  // Clock and Reset
  .axis_aclk     ( axi_clk       ), // input wire s_axis_aclk
  .axis_aresetn  ( axis_aresetn  ), // input wire s_axis_aresetn

  // Slave Interface Signals (DMA -> CODEC) //
  .s_axis_tready ( s_axis_tready    ), // Ready
  .s_axis_tvalid ( s_axis_tvalid    ), // Data Valid (WR)
  .s_axis_tdata  ( s_axis_tdata_int ), // Data

  // Master Interface Signals (CODEC -> DMA) //
  .m_axis_tready ( m_axis_tready ), // Ready (RD)
  .m_axis_tvalid ( m_axis_tvalid ), // Data Valid
  .m_axis_tdata  ( m_axis_tdata  ), // Data
  .m_axis_tlast  ( m_axis_tlast  ),

  .heartbeat     ( heartbeat     ),
  
  /////////////////////////
  //// Counter Signals ////
  /////////////////////////
  // AXI CLK //
  .DOWNSTREAM_axis_wr_data_count ( DOWNSTREAM_axis_wr_data_count ),
  .UPSTREAM_axis_rd_data_count   ( UPSTREAM_axis_rd_data_count   ),
  // Audio CLK //
  .DOWNSTREAM_axis_rd_data_count ( DOWNSTREAM_axis_rd_data_count ),
  .UPSTREAM_axis_wr_data_count   ( UPSTREAM_axis_wr_data_count   ),

  ///////////////////////////
  //// Interrupt Signals ////
  ///////////////////////////
  .DOWNSTREAM_almost_empty       ( DOWNSTREAM_almost_empty       )
);


register_unit #(
  .C_S_AXI_DATA_WIDTH( C_S00_AXI_DATA_WIDTH ),
  .C_S_AXI_ADDR_WIDTH( C_S00_AXI_ADDR_WIDTH )
) register_unit(
  // Clocks and resets
  .ac_bclk         ( ac_bclk         ),
  .s00_axi_aclk    ( axi_clk         ),
  .s00_axi_aresetn ( s00_axi_aresetn ),

  //////////////////////
  // Register signals //
  //////////////////////
  //---- I2S Clock Domain ----//
  .audio_data_out                ( audio_data_out                ),
  .DOWNSTREAM_axis_wr_data_count ( DOWNSTREAM_axis_wr_data_count ),
  .UPSTREAM_axis_wr_data_count   ( UPSTREAM_axis_wr_data_count   ),

  //---- AXI Clock Domain ----//

  // Interface to the controller_unit
  .clear_codec_i2c_data_wr       ( controller_busy               ),
  .clear_codec_i2c_data_rd       ( controller_busy               ),
  .controller_busy               ( controller_busy               ),
  .codec_i2c_rd_data             ( codec_i2c_rd_data             ),
  .data_in_valid                 ( update_codec_i2c_rd_data      ),
  .missed_ack                    ( missed_ack                    ), 
  .codec_init_done               ( codec_init_done               ),
  .update_codec_i2c_rd_data      ( update_codec_i2c_rd_data      ),
  .codec_i2c_data_wr             ( codec_i2c_data_wr             ),
  .codec_i2c_data_rd             ( codec_i2c_data_rd             ),
  .codec_i2c_addr                ( codec_i2c_addr                ),
  .codec_i2c_wr_data             ( codec_i2c_wr_data             ),
  .controller_reset              ( sw_reset                      ),
  .UPSTREAM_axis_rd_data_count   ( UPSTREAM_axis_rd_data_count   ),
  .DOWNSTREAM_axis_rd_data_count ( DOWNSTREAM_axis_rd_data_count ),

  /////////////////////////
  //// AXI Interface   ////
  /////////////////////////
  .s00_axi_awaddr  ( s00_axi_awaddr  ),
  .s00_axi_awprot  ( s00_axi_awprot  ),
  .s00_axi_awvalid ( s00_axi_awvalid ),
  .s00_axi_awready ( s00_axi_awready ),
  .s00_axi_wdata   ( s00_axi_wdata   ),
  .s00_axi_wstrb   ( s00_axi_wstrb   ),
  .s00_axi_wvalid  ( s00_axi_wvalid  ),
  .s00_axi_wready  ( s00_axi_wready  ),
  .s00_axi_bresp   ( s00_axi_bresp   ),
  .s00_axi_bvalid  ( s00_axi_bvalid  ),
  .s00_axi_bready  ( s00_axi_bready  ),
  .s00_axi_araddr  ( s00_axi_araddr  ),
  .s00_axi_arprot  ( s00_axi_arprot  ),
  .s00_axi_arvalid ( s00_axi_arvalid ),
  .s00_axi_arready ( s00_axi_arready ),
  .s00_axi_rdata   ( s00_axi_rdata   ),
  .s00_axi_rresp   ( s00_axi_rresp   ),
  .s00_axi_rvalid  ( s00_axi_rvalid  ),
  .s00_axi_rready  ( s00_axi_rready  )

);

endmodule

`default_nettype wire