///////////////////////////////////////////////////////////
// Codec Unit Top                                        //
// Author: Diego Rosales                                 //
///////////////////////////////////////////////////////////
// Description                                           //
//////////////                                           //
// This module controls the CODEC in the Digilent Zybo   //
// The CODEC Part Number is:                             //
// This module translates instructions into rd/wr        //
// sequences for the CODEC for easy interfacing          //
// This module is also responsible for transmitting the  //
// audio stream to the CODEC                             //
///////////////////////////////////////////////////////////
// Rev 0.1 - Init                                        //
///////////////////////////////////////////////////////////

module codec_unit_top #(
  parameter C_S00_AXI_DATA_WIDTH = 32,
  parameter C_S00_AXI_ADDR_WIDTH = 8
) (
  //********************************************//
  //              Board Signals                 //
  //********************************************//
  ///////////////////////////////////////////////
  /////////////// CLOCK AND RESET /////////////// 
  input wire board_clk, // 50MHz
  input wire reset,

  ///////////////////////////////////////////////
  ///////////// I2S SIGNALS (Audio) ///////////// 
  output wire i2s_bclk,
  output wire i2s_wclk,
  output wire i2s_data,

  ///////////////////////////////////////////////
  //////////// I2C SIGNALS (Control) //////////// 
  inout wire i2c_scl,
  inout wire i2c_sda,


  //********************************************//
  //            AXI Clock Domain                //
  //********************************************//

  // AXI Clock
  input wire axi_clk,

  ///////////////////////////////////////////////
  //////////// CODEC CONTROL SIGNALS ////////////
  input wire       output_en,    // CODEC Output Enable

  input wire [2:0] frequency,    // Sample Frequency Select
  input wire       apply_config, // Apply Configuration

  ///////////////////////////////////////////////
  /////////// CODEC REGISTER SIGNALS ////////////
  input  wire       codec_rd_en,
  input  wire       codec_wr_en,
  input  wire [7:0] codec_reg_addr,
  input  wire [7:0] codec_data_in,
  output wire [7:0] codec_data_out,
  output wire       codec_data_out_valid,

  ///////////////////////////////////////////////
  /////////// I2C CONTROLLER SIGNALS ////////////
  input  wire       i2c_ctrl_rd,
  input  wire [2:0] i2c_ctrl_addr,
  output wire [7:0] i2c_ctrl_data,
  output wire       controller_busy,
  output wire       init_done,
  output wire       init_error,
  output wire       missed_ack,
  
  ///////////////////////////////////////////////
  ///////////// CODEC DATA SIGNALS //////////////    
  input wire [47:0] data_in, // Audio Data
  input wire        data_wr, // Data Write to the data FIFO

  ///////////////////////////////////////////////
  ////////// CODEC UNIT STATUS SIGNALS ////////// 
  output wire pll_locked,

  //********************************************//

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

// I2C
wire        i2c_scl_i;
wire        i2c_scl_o;
wire        i2c_scl_t;
wire        i2c_sda_i;
wire        i2c_sda_o;
wire        i2c_sda_t;

// Synchronizer
wire       codec_rd_en_SYNC         ;
wire       codec_wr_en_SYNC         ;
wire [7:0] codec_reg_addr_SYNC      ;
wire [7:0] codec_data_in_SYNC       ;
wire       controller_busy_SYNC     ; 
wire       codec_data_out_valid_SYNC;
wire [7:0] codec_data_out_SYNC      ; 
wire [2:0] i2c_ctrl_addr_SYNC       ;
wire       i2c_ctrl_rd_SYNC         ;
wire [7:0] i2c_ctrl_data_SYNC       ;

assign pll_locked = 1'b0;

// Interface between the register unit and the design
wire        clear_codec_i2c_data_wr;
wire        clear_codec_i2c_data_rd;
wire        codec_i2c_data_wr;
wire        codec_i2c_data_rd;
wire        controller_busy;
wire        codec_init_done;
wire [31:0] codec_i2c_addr;
wire [31:0] codec_i2c_wr_data;
wire [31:0] codec_i2c_rd_data;
wire        update_codec_i2c_rd_data;

assign codec_init_done = init_done;

IOBUF sda_iobuf (
  .I  (i2c_sda_o), 
  .IO (i2c_sda  ), 
  .O  (i2c_sda_i), 
  .T  (i2c_sda_t)
  );   

IOBUF scl_iobuf (
  .I  (i2c_scl_o), 
  .IO (i2c_scl  ), 
  .O  (i2c_scl_i), 
  .T  (i2c_scl_t)
  );   

controller_unit_top controller_unit(
  .clk  (board_clk),
  .reset(reset    ),

  // CODEC RW signals
  .codec_rd_en          (codec_i2c_data_rd       ), // Input
  .codec_wr_en          (codec_i2c_data_wr       ), // Input
  .codec_reg_addr       (codec_i2c_addr[7:0]     ), // Input
  .codec_data_in        (codec_i2c_wr_data       ), // Input
  .codec_data_out       (codec_i2c_rd_data       ), // Output
  .codec_data_out_valid (update_codec_i2c_rd_data), // Output
  .controller_busy, // Output

  .init_done,
  .init_error,

  // I2C Signals
  .i2c_scl_i,
  .i2c_scl_o,
  .i2c_scl_t,
  .i2c_sda_i,
  .i2c_sda_o,
  .i2c_sda_t
  );


i2s_controller i2s_controller(
  .clk      (clk_24mhz),
  .reset    (reset    ),
  .data     (fifo_data),
  .data_rd  (fifo_rd  ),
  .i2s_bclk (i2s_bclk ),
  .i2s_wclk (i2s_wclk ),
  .i2s_data (i2s_data )
  );


register_unit #(
  .C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
  .C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
) register_unit(
  //---- Board Clock Domain ----//
  .board_clk,
  .reset,


  // Interface to the controller_unit
  .clear_codec_i2c_data_wr(controller_busy),
  .clear_codec_i2c_data_rd(controller_busy),
  .codec_i2c_data_wr,
  .codec_i2c_data_rd,
  .controller_busy,
  .codec_init_done,
  .codec_i2c_addr,
  .codec_i2c_wr_data,
  .codec_i2c_rd_data,
  .update_codec_i2c_rd_data,
  
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
