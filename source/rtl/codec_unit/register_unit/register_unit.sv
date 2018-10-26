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
	input  wire        data_in_valid,
	input  wire        missed_ack,		
	output wire [31:0] codec_i2c_addr,
	output wire [31:0] codec_i2c_wr_data,
    input  wire [31:0] codec_i2c_rd_data,
    input  wire        update_codec_i2c_rd_data,
	output wire        controller_reset,

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
wire        data_in_valid_sync;
wire        missed_ack_sync;
wire [31:0] codec_i2c_addr_sync;
wire [31:0] codec_i2c_wr_data_sync;
wire [31:0] codec_i2c_rd_data_sync;
wire        update_codec_i2c_rd_data_sync;
wire        controller_reset_sync;


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
		
		.clear_codec_i2c_data_wr  (clear_codec_i2c_data_wr_sync ),
		.clear_codec_i2c_data_rd  (clear_codec_i2c_data_rd_sync ),
		.codec_i2c_data_wr        (codec_i2c_data_wr_sync       ),
		.codec_i2c_data_rd        (codec_i2c_data_rd_sync       ),
		.controller_busy          (controller_busy_sync         ),
		.codec_init_done          (codec_init_done_sync         ),
		.data_in_valid            (data_in_valid_sync           ),
		.missed_ack               (missed_ack_sync              ),
		.codec_i2c_addr           (codec_i2c_addr_sync          ),
		.codec_i2c_wr_data        (codec_i2c_wr_data_sync       ),
		.codec_i2c_rd_data        (codec_i2c_rd_data_sync       ),
		.update_codec_i2c_rd_data (update_codec_i2c_rd_data_sync),
		.controller_reset         (controller_reset_sync        )

	);


///////////////////
// Synchronizers //
///////////////////
// AXI -> Board Clock
synchronizer #(.DATA_WIDTH(1))  AXI_2_BOARD_codec_i2c_data_wr_sync      (.clk_in(s00_axi_aclk),  .clk_out(board_clk), .data_in(codec_i2c_data_wr_sync),  .data_out(codec_i2c_data_wr));
synchronizer #(.DATA_WIDTH(1))  AXI_2_BOARD_codec_i2c_data_rd_sync      (.clk_in(s00_axi_aclk),  .clk_out(board_clk), .data_in(codec_i2c_data_rd_sync),  .data_out(codec_i2c_data_rd));
synchronizer #(.DATA_WIDTH(32)) AXI_2_BOARD_codec_i2c_addr_sync         (.clk_in(s00_axi_aclk),  .clk_out(board_clk), .data_in(codec_i2c_addr_sync   ),  .data_out(codec_i2c_addr   ));
synchronizer #(.DATA_WIDTH(32)) AXI_2_BOARD_codec_i2c_wr_data_sync      (.clk_in(s00_axi_aclk),  .clk_out(board_clk), .data_in(codec_i2c_wr_data_sync),  .data_out(codec_i2c_wr_data));
pulse_synchronizer              AXI_2_BOARD_controller_reset_pulse_sync (.clk_in(s00_axi_aclk),  .clk_out(board_clk), .data_in(controller_reset_sync),   .data_out(controller_reset ));


// Board Clock -> AXI
synchronizer       #(.DATA_WIDTH(1 )) BOARD_2_AXI_clear_codec_i2c_data_wr_sync        (.clk_in(board_clk),  .clk_out(s00_axi_aclk), .data_in(clear_codec_i2c_data_wr ),  .data_out(clear_codec_i2c_data_wr_sync ));
synchronizer       #(.DATA_WIDTH(1 )) BOARD_2_AXI_clear_codec_i2c_data_rd_sync        (.clk_in(board_clk),  .clk_out(s00_axi_aclk), .data_in(clear_codec_i2c_data_rd ),  .data_out(clear_codec_i2c_data_rd_sync ));
synchronizer       #(.DATA_WIDTH(1 )) BOARD_2_AXI_controller_busy_sync                (.clk_in(board_clk),  .clk_out(s00_axi_aclk), .data_in(controller_busy         ),  .data_out(controller_busy_sync         ));
synchronizer       #(.DATA_WIDTH(32)) BOARD_2_AXI_codec_i2c_rd_data_sync              (.clk_in(board_clk),  .clk_out(s00_axi_aclk), .data_in(codec_i2c_rd_data       ),  .data_out(codec_i2c_rd_data_sync       ));
synchronizer       #(.DATA_WIDTH(1 )) BOARD_2_AXI_data_in_valid_sync                  (.clk_in(board_clk),  .clk_out(s00_axi_aclk), .data_in(data_in_valid           ),  .data_out(data_in_valid_sync           ));
synchronizer       #(.DATA_WIDTH(1 )) BOARD_2_AXI_missed_ack_sync                     (.clk_in(board_clk),  .clk_out(s00_axi_aclk), .data_in(missed_ack              ),  .data_out(missed_ack_sync              ));
pulse_synchronizer                    BOARD_2_AXI_codec_init_done_pulse_sync          (.clk_in(board_clk),  .clk_out(s00_axi_aclk), .data_in(codec_init_done         ),  .data_out(codec_init_done_sync         ));
pulse_synchronizer                    BOARD_2_AXI_update_codec_i2c_rd_data_pulse_sync (.clk_in(board_clk),  .clk_out(s00_axi_aclk), .data_in(update_codec_i2c_rd_data),  .data_out(update_codec_i2c_rd_data_sync));

endmodule