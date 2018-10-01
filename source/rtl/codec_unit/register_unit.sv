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
    //---- Board Clock Domain ----//
    input wire board_clk,
    input wire reset,

    // Interface to the controller_unit //
    input  wire        clear_codec_i2c_data_wr,
    input  wire        clear_codec_i2c_data_rd,
	output wire        codec_i2c_data_wr,
    output wire        codec_i2c_data_rd,
	input  wire        controller_busy,
	input  wire        codec_init_done,
	output wire [31:0] codec_i2c_addr,
	output wire [31:0] codec_i2c_wr_data,
    input  wire [31:0] codec_i2c_rd_data,
    input  wire        update_codec_i2c_rd_data,

    //---- AXI Clock Domain ----//
    // Ports of Axi Slave Bus Interface S00_AXI
	input  wire                                  s00_axi_aclk,
	input  wire                                  s00_axi_aresetn,
	input  wire [C_S_AXI_ADDR_WIDTH-1 : 0]     s00_axi_awaddr,
	input  wire [2 : 0]                          s00_axi_awprot,
	input  wire                                  s00_axi_awvalid,
	output wire                                  s00_axi_awready,
	input  wire [C_S_AXI_DATA_WIDTH-1 : 0]     s00_axi_wdata,
	input  wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
	input  wire                                  s00_axi_wvalid,
	output wire                                  s00_axi_wready,
	output wire [1 : 0]                          s00_axi_bresp,
	output wire                                  s00_axi_bvalid,
	input  wire                                  s00_axi_bready,
	input  wire [C_S_AXI_ADDR_WIDTH-1 : 0]     s00_axi_araddr,
	input  wire [2 : 0]                          s00_axi_arprot,
	input  wire                                  s00_axi_arvalid,
	output wire                                  s00_axi_arready,
	output wire [C_S_AXI_DATA_WIDTH-1 : 0]     s00_axi_rdata,
	output wire [1 : 0]                          s00_axi_rresp,
	output wire                                  s00_axi_rvalid,
	input  wire                                  s00_axi_rready
);

`include "register_params.svh"

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
wire [31:0] codec_i2c_addr_sync;
wire [31:0] codec_i2c_wr_data_sync;
wire [31:0] codec_i2c_rd_data_sync;
wire        update_codec_i2c_rd_data_sync;


// Instantiation of Axi Bus Interface S00_AXI
	axi_slave_controller # ( 
		.C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
	) axi_slave_controller_inst (
		.S_AXI_ACLK(s00_axi_aclk),
		.S_AXI_ARESETN(s00_axi_aresetn),
		.S_AXI_AWADDR(s00_axi_awaddr),
		.S_AXI_AWPROT(s00_axi_awprot),
		.S_AXI_AWVALID(s00_axi_awvalid),
		.S_AXI_AWREADY(s00_axi_awready),
		.S_AXI_WDATA(s00_axi_wdata),
		.S_AXI_WSTRB(s00_axi_wstrb),
		.S_AXI_WVALID(s00_axi_wvalid),
		.S_AXI_WREADY(s00_axi_wready),
		.S_AXI_BRESP(s00_axi_bresp),
		.S_AXI_BVALID(s00_axi_bvalid),
		.S_AXI_BREADY(s00_axi_bready),
		.S_AXI_ARADDR(s00_axi_araddr),
		.S_AXI_ARPROT(s00_axi_arprot),
		.S_AXI_ARVALID(s00_axi_arvalid),
		.S_AXI_ARREADY(s00_axi_arready),
		.S_AXI_RDATA(s00_axi_rdata),
		.S_AXI_RRESP(s00_axi_rresp),
		.S_AXI_RVALID(s00_axi_rvalid),
		.S_AXI_RREADY(s00_axi_rready),
		
		.clear_codec_i2c_data_wr(clear_codec_i2c_data_wr_sync),
		.clear_codec_i2c_data_rd(clear_codec_i2c_data_rd_sync),
		.codec_i2c_data_wr(codec_i2c_data_wr_sync),
		.codec_i2c_data_rd(codec_i2c_data_rd_sync),
		.controller_busy(controller_busy_sync),
		.codec_init_done(codec_init_done_sync),
		.codec_i2c_addr(codec_i2c_addr_sync),
		.codec_i2c_wr_data(codec_i2c_wr_data_sync),
		.codec_i2c_rd_data(codec_i2c_rd_data_sync),
		.update_codec_i2c_rd_data(update_codec_i2c_rd_data_sync)

	);


///////////////////
// Synchronizers //
///////////////////
// AXI -> Board Clock
`REG_SYNC(s00_axi_aclk, board_clk, 1 , codec_i2c_data_wr_sync , codec_i2c_data_wr, codec_i2c_data_wr)
`REG_SYNC(s00_axi_aclk, board_clk, 1 , codec_i2c_data_rd_sync , codec_i2c_data_rd, codec_i2c_data_rd)
`REG_SYNC(s00_axi_aclk, board_clk, 32, codec_i2c_addr_sync    , codec_i2c_addr   , codec_i2c_addr)
`REG_SYNC(s00_axi_aclk, board_clk, 32, codec_i2c_wr_data_sync , codec_i2c_wr_data, codec_i2c_wr_data)


// Board Clock -> AXI
`REG_SYNC(board_clk, s00_axi_aclk, 1 , clear_codec_i2c_data_wr , clear_codec_i2c_data_wr_sync , clear_codec_i2c_data_wr)
`REG_SYNC(board_clk, s00_axi_aclk, 1 , clear_codec_i2c_data_rd , clear_codec_i2c_data_rd_sync , clear_codec_i2c_data_rd)
`REG_SYNC(board_clk, s00_axi_aclk, 1 , codec_init_done_sync    , codec_init_done_sync_sync    , codec_init_done_sync)
`REG_SYNC(board_clk, s00_axi_aclk, 1 , controller_busy         , controller_busy_sync         , controller_busy)
`REG_SYNC(board_clk, s00_axi_aclk, 32, codec_i2c_rd_data       , codec_i2c_rd_data_sync       , codec_i2c_rd_data)
`REG_SYNC(board_clk, s00_axi_aclk, 1 , update_codec_i2c_rd_data, update_codec_i2c_rd_data_sync, update_codec_i2c_rd_data)

endmodule