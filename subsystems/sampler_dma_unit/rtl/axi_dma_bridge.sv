// +--------------------------------------------------------------------------+
// | axi_dma_bridge.sv                                                        |
// +--------------------------------------------------------------------------+
// | This module will interface with the AXI fabric to perform DMA operations |
// |                                                                          |
// | This module will receive the address, ID and length from the requester   |
// | and generate an AXI transaction, returning an acknowledge when the       |
// | request has been sent and acknowledged by the AXI fabric                 |
// |                                                                          |
// | This module will forward the AXI data to the receiver for consumption    |
// +--------------------------------------------------------------------------+

`timescale 1 ns / 1 ps

	module axi_dma_bridge #
	(
		// Users to add parameters here
    parameter integer C_AXI_STREAM_TDATA_WIDTH = 32,
    parameter integer C_AXI_STREAM_TUSER_WIDTH = 32,
		// User parameters ends
		// Do not modify the parameters beyond this line

		// Base address of targeted slave
		parameter  C_M_TARGET_SLAVE_BASE_ADDR	= 32'h40000000,
		// Burst Length. Supports 1, 2, 4, 8, 16, 32, 64, 128, 256 burst lengths
		parameter integer C_M_AXI_BURST_LEN	= 16,
		// Thread ID Width
		parameter integer C_M_AXI_ID_WIDTH	= 6,
		// Width of Address Bus
		parameter integer C_M_AXI_ADDR_WIDTH	= 32,
		// Width of Data Bus
		parameter integer C_M_AXI_DATA_WIDTH	= 32,
		// Width of User Write Address Bus
		parameter integer C_M_AXI_AWUSER_WIDTH	= 0,
		// Width of User Read Address Bus
		parameter integer C_M_AXI_ARUSER_WIDTH	= 0,
		// Width of User Write Data Bus
		parameter integer C_M_AXI_WUSER_WIDTH	= 0,
		// Width of User Read Data Bus
		parameter integer C_M_AXI_RUSER_WIDTH	= 0,
		// Width of User Response Bus
		parameter integer C_M_AXI_BUSER_WIDTH	= 0
	)
	(
		////////////////////////////////////////////////////
		// Interface to the user logic
		////////////////////////////////////////////////////

		// Interface between the AXI bridge and the receiver //
    // Output AXI Stream interface
    output wire [C_AXI_STREAM_TDATA_WIDTH-1 : 0]  axi_stream_master_tdata,
    input  wire                                   axi_stream_master_tready,
    output wire                                   axi_stream_master_tvalid,
    output wire                                   axi_stream_master_tlast,
    output wire [C_AXI_STREAM_TUSER_WIDTH-1 : 0]  axi_stream_master_tuser,


		// Interface between the AXI bridge and the requester //
		input  wire [ 31 : 0 ] dma_sample_req_addr,
		input  wire [ 5 : 0 ]  dma_sample_req_id,
		input  wire [ 7 : 0 ]  dma_sample_req_len,
		input  wire            dma_sample_req_valid,
		output wire            dma_sample_req_done,

		// User ports ends
		// Do not modify the ports beyond this line

		// Initiate AXI transactions
		input wire  INIT_AXI_TXN,
		// Asserts when transaction is complete
		output wire  TXN_DONE,
		// Asserts when ERROR is detected
		output reg  ERROR,
		// Global Clock Signal.
		input wire  M_AXI_ACLK,
		// Global Reset Singal. This Signal is Active Low
		input wire  M_AXI_ARESETN,

		//////////////////////////////////////////////////////
		// Write Signals
		//////////////////////////////////////////////////////

		// Master Interface Write Address ID
		output wire [C_M_AXI_ID_WIDTH-1 : 0] M_AXI_AWID,
		// Master Interface Write Address
		output wire [C_M_AXI_ADDR_WIDTH-1 : 0] M_AXI_AWADDR,
		// Burst length. The burst length gives the exact number of transfers in a burst
		output wire [7 : 0] M_AXI_AWLEN,
		// Burst size. This signal indicates the size of each transfer in the burst
		output wire [2 : 0] M_AXI_AWSIZE,
		// Burst type. The burst type and the size information, 
		// determine how the address for each transfer within the burst is calculated.
		output wire [1 : 0] M_AXI_AWBURST,
		// Lock type. Provides additional information about the
		// atomic characteristics of the transfer.
		output wire  M_AXI_AWLOCK,
		// Memory type. This signal indicates how transactions
		// are required to progress through a system.
		output wire [3 : 0] M_AXI_AWCACHE,
		// Protection type. This signal indicates the privilege
		// and security level of the transaction, and whether
		// the transaction is a data access or an instruction access.
		output wire [2 : 0] M_AXI_AWPROT,
		// Quality of Service, QoS identifier sent for each write transaction.
		output wire [3 : 0] M_AXI_AWQOS,
		// Optional User-defined signal in the write address channel.
		output wire [C_M_AXI_AWUSER_WIDTH-1 : 0] M_AXI_AWUSER,
		// Write address valid. This signal indicates that
		// the channel is signaling valid write address and control information.
		output wire  M_AXI_AWVALID,
		// Write address ready. This signal indicates that
		// the slave is ready to accept an address and associated control signals
		input wire  M_AXI_AWREADY,
		// Master Interface Write Data.
		output wire [C_M_AXI_DATA_WIDTH-1 : 0] M_AXI_WDATA,
		// Write strobes. This signal indicates which byte
		// lanes hold valid data. There is one write strobe
		// bit for each eight bits of the write data bus.
		output wire [C_M_AXI_DATA_WIDTH/8-1 : 0] M_AXI_WSTRB,
		// Write last. This signal indicates the last transfer in a write burst.
		output wire  M_AXI_WLAST,
		// Optional User-defined signal in the write data channel.
		output wire [C_M_AXI_WUSER_WIDTH-1 : 0] M_AXI_WUSER,
		// Write valid. This signal indicates that valid write
		// data and strobes are available
		output wire  M_AXI_WVALID,
		// Write ready. This signal indicates that the slave
		// can accept the write data.
		input wire  M_AXI_WREADY,

		//////////////////////////////////////////////
		// Master Interface Write Response.
		///////////////////////////////////////////////
		input wire [C_M_AXI_ID_WIDTH-1 : 0] M_AXI_BID,
		// Write response. This signal indicates the status of the write transaction.
		input wire [1 : 0] M_AXI_BRESP,
		// Optional User-defined signal in the write response channel
		input wire [C_M_AXI_BUSER_WIDTH-1 : 0] M_AXI_BUSER,
		// Write response valid. This signal indicates that the
		// channel is signaling a valid write response.
		input wire  M_AXI_BVALID,
		// Response ready. This signal indicates that the master
		// can accept a write response.
		output wire  M_AXI_BREADY,

		//////////////////////////////////////////////
		// Read Signals
		///////////////////////////////////////////////

		// Master Interface Read Address.
		output wire [C_M_AXI_ID_WIDTH-1 : 0] M_AXI_ARID,
		// Read address. This signal indicates the initial
		// address of a read burst transaction.
		output wire [C_M_AXI_ADDR_WIDTH-1 : 0] M_AXI_ARADDR,
		// Burst length. The burst length gives the exact number of transfers in a burst
		output wire [7 : 0] M_AXI_ARLEN,
		// Burst size. This signal indicates the size of each transfer in the burst
		output wire [2 : 0] M_AXI_ARSIZE,
		// Burst type. The burst type and the size information, 
		// determine how the address for each transfer within the burst is calculated.
		output wire [1 : 0] M_AXI_ARBURST,
		// Lock type. Provides additional information about the
		// atomic characteristics of the transfer.
		output wire  M_AXI_ARLOCK,
		// Memory type. This signal indicates how transactions
		// are required to progress through a system.
		output wire [3 : 0] M_AXI_ARCACHE,
		// Protection type. This signal indicates the privilege
		// and security level of the transaction, and whether
		// the transaction is a data access or an instruction access.
		output wire [2 : 0] M_AXI_ARPROT,
		// Quality of Service, QoS identifier sent for each read transaction
		output wire [3 : 0] M_AXI_ARQOS,
		// Optional User-defined signal in the read address channel.
		output wire [C_M_AXI_ARUSER_WIDTH-1 : 0] M_AXI_ARUSER,
		// Write address valid. This signal indicates that
		// the channel is signaling valid read address and control information
		output wire  M_AXI_ARVALID,
		// Read address ready. This signal indicates that
		// the slave is ready to accept an address and associated control signals
		input wire  M_AXI_ARREADY,

		//////////////////////////////////////////////
		// Read Response Signals
		///////////////////////////////////////////////

		// Read ID tag. This signal is the identification tag
		// for the read data group of signals generated by the slave.
		input wire [C_M_AXI_ID_WIDTH-1 : 0] M_AXI_RID,
		// Master Read Data
		input wire [C_M_AXI_DATA_WIDTH-1 : 0] M_AXI_RDATA,
		// Read response. This signal indicates the status of the read transfer
		input wire [1 : 0] M_AXI_RRESP,
		// Read last. This signal indicates the last transfer in a read burst
		input wire  M_AXI_RLAST,
		// Optional User-defined signal in the read address channel.
		input wire [C_M_AXI_RUSER_WIDTH-1 : 0] M_AXI_RUSER,
		// Read valid. This signal indicates that the channel
		// is signaling the required read data.
		input wire  M_AXI_RVALID,
		// Read ready. This signal indicates that the master can
		// accept the read data and response information.
		output wire  M_AXI_RREADY
	);


// function called clogb2 that returns an integer which has the
//value of the ceiling of the log base 2

// function called clogb2 that returns an integer which has the 
// value of the ceiling of the log base 2.                      
function integer clogb2 (input integer bit_depth);              
begin                                                           
	for(clogb2=0; bit_depth>0; clogb2=clogb2+1)                   
		bit_depth = bit_depth >> 1;                                 
	end                                                           
endfunction              


///////////////////////////////////////////////////////////////
// AXI Read Signals
///////////////////////////////////////////////////////////////

localparam AXI_RD_STATE_IDLE    = 4'h0;
localparam AXI_RD_ADDR_WR       = 4'h1;
localparam AXI_RD_ADDR_ACK      = 4'h2;

reg [ C_M_AXI_ID_WIDTH  -1 : 0 ]     ARID_reg;
reg [ C_M_AXI_ADDR_WIDTH - 1 : 0 ]   ARADDR_reg;
reg [ 7 : 0 ]                        ARLEN_reg;
reg [ 2 : 0 ]                        ARSIZE_reg;
reg [ 1 : 0 ]                        ARBURST_reg;
reg                                  ARLOCK_reg;
reg [ 3 : 0 ]                        ARCACHE_reg;
reg [ 2 : 0 ]                        ARPROT_reg;
reg [ 3 : 0 ]                        ARQOS_reg;
reg [ C_M_AXI_ARUSER_WIDTH - 1 : 0 ] ARUSER_reg;
reg                                  ARVALID_reg;

// AXI Read FSM
reg   [ 3 : 0 ] axi_rd_sm_curr_st;
logic [ 3 : 0 ] axi_rd_sm_next_st;


wire axi_rd_sm_curr_st_AXI_RD_STATE_IDLE;
wire axi_rd_sm_curr_st_AXI_RD_ADDR_WR;
wire axi_rd_sm_curr_st_AXI_RD_ADDR_ACK;

wire dma_addr_wr_done;

///////////////////////////////////////////////////////////////
// Arbiter Signals
//////////////////////////////////////////////////////////////

reg                              dma_req_reg;     // Request
reg [ 31 : 0 ]                   dma_addr_reg;    // Address
reg [ 7 : 0 ]                    dma_req_len_reg; // Burst Size
reg [ C_M_AXI_ID_WIDTH - 1 : 0 ] dma_req_id_reg;  // Request ID


//////////////////////////////////////////////////////////
// Outputs
//////////////////////////////////////////////////////////
assign axi_stream_master_tdata           = M_AXI_RDATA;
assign axi_stream_master_tuser[5:0]      = M_AXI_RID[ 5 : 0 ];
assign axi_stream_master_tvalid          = M_AXI_RVALID;
assign axi_stream_master_tlast           = M_AXI_RLAST;
assign M_AXI_RREADY                      = axi_stream_master_tready;

//////////////////////////////////////////////////////////
// Logic
//////////////////////////////////////////////////////////

assign axi_rd_sm_curr_st_AXI_RD_STATE_IDLE = ( axi_rd_sm_curr_st == AXI_RD_STATE_IDLE );
assign axi_rd_sm_curr_st_AXI_RD_ADDR_WR    = ( axi_rd_sm_curr_st == AXI_RD_ADDR_WR );
assign axi_rd_sm_curr_st_AXI_RD_ADDR_ACK   = ( axi_rd_sm_curr_st == AXI_RD_ADDR_ACK );

//////////////////////
// AXI Read FSM
//////////////////////

assign M_AXI_ARID    = ARID_reg;
assign M_AXI_ARADDR  = ARADDR_reg;
assign M_AXI_ARLEN   = ARLEN_reg;
assign M_AXI_ARSIZE  = ARSIZE_reg;
assign M_AXI_ARBURST = ARBURST_reg;
assign M_AXI_ARLOCK  = ARLOCK_reg;
assign M_AXI_ARCACHE = ARCACHE_reg;
assign M_AXI_ARPROT  = ARPROT_reg;
assign M_AXI_ARQOS   = ARQOS_reg;
assign M_AXI_ARUSER  = ARUSER_reg;
assign M_AXI_ARVALID = ARVALID_reg;
//assign M_AXI_RREADY  = 1'b1;


always_ff @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
	if ( ~M_AXI_ARESETN ) begin
		axi_rd_sm_curr_st <= AXI_RD_STATE_IDLE;
	end
	else begin
		axi_rd_sm_curr_st <= axi_rd_sm_next_st;
	end	
end


always_comb begin

	case (axi_rd_sm_curr_st)
		AXI_RD_STATE_IDLE: begin

			if ( dma_req_reg ) begin
				axi_rd_sm_next_st = AXI_RD_ADDR_WR;
			end
			else begin
				axi_rd_sm_next_st = AXI_RD_STATE_IDLE;
			end

		end

		AXI_RD_ADDR_WR: begin
			if ( dma_addr_wr_done ) begin
				axi_rd_sm_next_st = AXI_RD_STATE_IDLE;
			end
			else begin
				axi_rd_sm_next_st = AXI_RD_ADDR_WR;
			end
		end

		default: begin
			axi_rd_sm_next_st = AXI_RD_STATE_IDLE;
		end
	endcase

end

assign dma_addr_wr_done = ( ( axi_rd_sm_curr_st == AXI_RD_ADDR_WR ) & ( M_AXI_ARREADY ) & ( M_AXI_ARVALID ) ) ? 1'b1 : 1'b0;

always_ff @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
	if ( ~M_AXI_ARESETN ) begin
		ARID_reg    <= 'h0;
		ARADDR_reg  <= 'h0;
		ARLEN_reg   <= 'h0;
		ARSIZE_reg  <= 'h0;
		ARBURST_reg <= 'h0;
		ARLOCK_reg  <= 'h0;
		ARCACHE_reg <= 'h0;
		ARPROT_reg  <= 'h0;
		ARQOS_reg   <= 'h0;
		ARUSER_reg  <= 'h0;
		ARVALID_reg <= 'h0;

	end
	else begin
		ARVALID_reg      <= ARVALID_reg;

		ARADDR_reg  <= ARADDR_reg; 
		ARLEN_reg   <= ARLEN_reg;  
		ARID_reg    <= ARID_reg;   
		ARSIZE_reg  <= ARSIZE_reg; 
		ARBURST_reg <= ARBURST_reg;
		ARLOCK_reg  <= ARLOCK_reg; 
		ARCACHE_reg <= ARCACHE_reg;
		ARPROT_reg  <= ARPROT_reg; 
		ARQOS_reg   <= ARQOS_reg;  
		ARUSER_reg  <= ARUSER_reg; 

		if ( axi_rd_sm_curr_st == AXI_RD_ADDR_WR ) begin

			ARADDR_reg  <= dma_addr_reg;
			ARLEN_reg   <= dma_req_len_reg;
			ARID_reg    <= dma_req_id_reg;
			ARSIZE_reg  <= 3'b010; // 4 bytes per transfer == 32 bit transfers
			ARBURST_reg <= 2'b01;  // Burst type == INCR
			ARLOCK_reg  <= 1'b0;
			ARCACHE_reg <= 4'b0010; // Normal Non-cacheable Non-bufferable
			ARPROT_reg  <= 3'b000;
			ARQOS_reg   <= 4'h0;
			ARUSER_reg  <= 'h0;

			// Valid Signal
			if ( ~ARVALID_reg ) begin
				ARVALID_reg <= 1'b1;
			end
			else if ( M_AXI_ARREADY == 1'b1 ) begin
				ARVALID_reg      <= 1'b0;
			end
		end
		else begin
			ARVALID_reg <= 1'b0;
		end
	end


end




///////////////////////
// DMA Request Handler
///////////////////////

assign dma_sample_req_done = dma_addr_wr_done;

always_ff @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
	if ( ~M_AXI_ARESETN ) begin
		dma_req_reg       <= 'h0;
		dma_addr_reg      <= 'h0;
		dma_req_len_reg   <= 'h0;
		dma_req_id_reg    <= 'h0;
	end
	else begin

		dma_req_reg       <= 1'b0;
		dma_addr_reg      <= dma_addr_reg;
		dma_req_len_reg   <= dma_req_len_reg;
		dma_req_id_reg    <= dma_req_id_reg;

		if ( dma_sample_req_valid && axi_rd_sm_curr_st_AXI_RD_STATE_IDLE ) begin
			// Capture the necessary fields
			dma_addr_reg            <= dma_sample_req_addr;
			dma_req_id_reg[ 5 : 0 ] <= dma_sample_req_id;
			dma_req_len_reg         <= dma_sample_req_len;
			// Start the DMA request
			dma_req_reg <= 1'b1;

		end

	end
end


endmodule
