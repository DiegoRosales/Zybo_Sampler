/////////////////////////////////////////////////////
// This contains the registers that control the    //
// sampler. These registers interface with the AXI //
// host.                                           //
/////////////////////////////////////////////////////
// Rev. 0.1 - Init                                 //
/////////////////////////////////////////////////////

module register_unit #(
    parameter C_S_AXI_DATA_WIDTH = 32,
    parameter C_S_AXI_ADDR_WIDTH = 8
) (
  // Clocks and resets
	input wire ac_bclk,
	input wire s00_axi_aclk,
	input wire s00_axi_aresetn,
  
  //////////////////////
  // Register signals //
  //////////////////////
  //---- I2S Clock Domain ----//
  input wire [31:0] DOWNSTREAM_axis_rd_data_count,
  input wire [31:0] UPSTREAM_axis_wr_data_count,

  //---- AXI Clock Domain ----//
  input wire [31:0] DOWNSTREAM_axis_wr_data_count,
  input wire [31:0] UPSTREAM_axis_rd_data_count,

  // Interface to the controller_unit //
  input  wire        clear_codec_i2c_data_wr,
  input  wire        clear_codec_i2c_data_rd,
	output wire        codec_i2c_data_wr,
  output wire        codec_i2c_data_rd,
	input  wire        controller_busy,
	input  wire        codec_init_done,
	input  wire        data_in_valid,
	input  wire        missed_ack,		
	output wire [31:0] codec_i2c_addr,
	output wire [31:0] codec_i2c_wr_data,
  input  wire [31:0] codec_i2c_rd_data,
  input  wire        update_codec_i2c_rd_data,
	output wire        controller_reset,
	input  wire [63:0] audio_data_out,

	/////////////////////////
  //// AXI Interface   ////
  /////////////////////////
	input  wire [C_S_AXI_ADDR_WIDTH-1 : 0]     s00_axi_awaddr,
	input  wire [2 : 0]                        s00_axi_awprot,
	input  wire                                s00_axi_awvalid,
	output wire                                s00_axi_awready,
	input  wire [C_S_AXI_DATA_WIDTH-1 : 0]     s00_axi_wdata,
	input  wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
	input  wire                                s00_axi_wvalid,
	output wire                                s00_axi_wready,
	output wire [1 : 0]                        s00_axi_bresp,
	output wire                                s00_axi_bvalid,
	input  wire                                s00_axi_bready,
	input  wire [C_S_AXI_ADDR_WIDTH-1 : 0]     s00_axi_araddr,
	input  wire [2 : 0]                        s00_axi_arprot,
	input  wire                                s00_axi_arvalid,
	output wire                                s00_axi_arready,
	output wire [C_S_AXI_DATA_WIDTH-1 : 0]     s00_axi_rdata,
	output wire [1 : 0]                        s00_axi_rresp,
	output wire                                s00_axi_rvalid,
	input  wire                                s00_axi_rready
);

`include "register_params.svh"

localparam integer OPT_MEM_ADDR_BITS = 5;

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

wire        clear_codec_i2c_data_wr_sync;
wire        clear_codec_i2c_data_rd_sync;
wire        codec_i2c_data_wr_sync;
wire        codec_i2c_data_rd_sync;
wire        controller_busy_sync;
wire        codec_init_done_sync;
wire        data_in_valid_sync;
wire        missed_ack_sync;
wire [31:0] codec_i2c_addr_sync;
wire [31:0] codec_i2c_wr_data_sync;
wire [31:0] codec_i2c_rd_data_sync;
wire        update_codec_i2c_rd_data_sync;
wire        controller_reset_sync;
wire [63:0] audio_data_out_sync;
wire [31:0] DOWNSTREAM_axis_wr_data_count_sync;
wire [31:0] UPSTREAM_axis_rd_data_count_sync;
wire [31:0] DOWNSTREAM_axis_rd_data_count_sync;
wire [31:0] UPSTREAM_axis_wr_data_count_sync;

// Output from the registers
(* keep = "true" *) wire [ C_S_AXI_DATA_WIDTH - 1 : 0 ] reg_data_out;
(* keep = "true" *) wire [ OPT_MEM_ADDR_BITS  - 1 : 0 ] reg_wr_addr;
(* keep = "true" *) wire [ OPT_MEM_ADDR_BITS  - 1 : 0 ] reg_rd_addr;
(* keep = "true" *) wire                                reg_wr_en;

// Instantiation of Axi Bus Interface S00_AXI
	axi_slave_controller # ( 
		.OPT_MEM_ADDR_BITS  ( OPT_MEM_ADDR_BITS  ),
		.C_S_AXI_DATA_WIDTH ( C_S_AXI_DATA_WIDTH ),
		.C_S_AXI_ADDR_WIDTH ( C_S_AXI_ADDR_WIDTH )
	) axi_slave_controller_inst (
		.S_AXI_ACLK   ( s00_axi_aclk    ),
		.S_AXI_ARESETN( s00_axi_aresetn ),
		.S_AXI_AWADDR ( s00_axi_awaddr  ),
		.S_AXI_AWPROT ( s00_axi_awprot  ),
		.S_AXI_AWVALID( s00_axi_awvalid ),
		.S_AXI_AWREADY( s00_axi_awready ),
		.S_AXI_WDATA  ( s00_axi_wdata   ),
		.S_AXI_WSTRB  ( s00_axi_wstrb   ),
		.S_AXI_WVALID ( s00_axi_wvalid  ),
		.S_AXI_WREADY ( s00_axi_wready  ),
		.S_AXI_BRESP  ( s00_axi_bresp   ),
		.S_AXI_BVALID ( s00_axi_bvalid  ),
		.S_AXI_BREADY ( s00_axi_bready  ),
		.S_AXI_ARADDR ( s00_axi_araddr  ),
		.S_AXI_ARPROT ( s00_axi_arprot  ),
		.S_AXI_ARVALID( s00_axi_arvalid ),
		.S_AXI_ARREADY( s00_axi_arready ),
		.S_AXI_RDATA  ( s00_axi_rdata   ),
		.S_AXI_RRESP  ( s00_axi_rresp   ),
		.S_AXI_RVALID ( s00_axi_rvalid  ),
		.S_AXI_RREADY ( s00_axi_rready  ),
		
		// Interface to the register controller
		.reg_data_out ( reg_data_out ),
		.reg_wr_addr  ( reg_wr_addr  ),
		.reg_rd_addr  ( reg_rd_addr  ),
		.reg_wr_en    ( reg_wr_en    )

	);


	codec_registers #(
		.OPT_MEM_ADDR_BITS( OPT_MEM_ADDR_BITS )
	)
	codec_registers (
		// Clock and Reset
		.axi_clk  ( s00_axi_aclk    ),
		.axi_reset( s00_axi_aresetn ),

		// Data Rd/Wr
		.data_in     ( s00_axi_wdata ),
		.data_out    ( reg_data_out  ),
		.reg_addr_wr ( reg_wr_addr   ),
		.reg_addr_rd ( reg_rd_addr   ),
		.data_wren   ( reg_wr_en     ),
		.byte_enable ( 4'h0          ),

		// Register outputs
		.clear_codec_i2c_data_wr  ( clear_codec_i2c_data_wr  ),
		.clear_codec_i2c_data_rd  ( clear_codec_i2c_data_rd  ),
		.codec_i2c_data_wr        ( codec_i2c_data_wr        ),
		.codec_i2c_data_rd        ( codec_i2c_data_rd        ),
		.controller_busy          ( controller_busy          ),
		.codec_init_done          ( codec_init_done          ),
		.data_in_valid            ( data_in_valid            ),
		.missed_ack               ( missed_ack               ),
		.codec_i2c_addr           ( codec_i2c_addr           ),
		.codec_i2c_wr_data        ( codec_i2c_wr_data        ),
		.codec_i2c_rd_data        ( codec_i2c_rd_data        ),
		.update_codec_i2c_rd_data ( update_codec_i2c_rd_data ),
		.controller_reset         ( controller_reset         ),
		.audio_data_out           ( audio_data_out_sync      ),

		// Register inputs
		// AXI CLK //
    .DOWNSTREAM_axis_wr_data_count ( DOWNSTREAM_axis_wr_data_count ),
    .UPSTREAM_axis_rd_data_count   ( UPSTREAM_axis_rd_data_count   ),
    // Audio CLK //
    .DOWNSTREAM_axis_rd_data_count ( DOWNSTREAM_axis_rd_data_count_sync ),
    .UPSTREAM_axis_wr_data_count   ( UPSTREAM_axis_wr_data_count_sync   )
	);

///////////////////
// Synchronizers //
///////////////////

// CODEC Clock -> AXI
synchronizer       #(.DATA_WIDTH(64)) CODEC_2_AXI_audio_data_out_sync                 (.clk_in(ac_bclk),  .clk_out(s00_axi_aclk), .data_in(audio_data_out                ),  .data_out(audio_data_out_sync                ));
synchronizer       #(.DATA_WIDTH(32)) CODEC_2_AXI_DOWNSTREAM_axis_rd_data_count       (.clk_in(ac_bclk),  .clk_out(s00_axi_aclk), .data_in(DOWNSTREAM_axis_rd_data_count ),  .data_out(DOWNSTREAM_axis_rd_data_count_sync ));
synchronizer       #(.DATA_WIDTH(32)) CODEC_2_AXI_UPSTREAM_axis_wr_data_count         (.clk_in(ac_bclk),  .clk_out(s00_axi_aclk), .data_in(UPSTREAM_axis_wr_data_count   ),  .data_out(UPSTREAM_axis_wr_data_count_sync   ));


endmodule