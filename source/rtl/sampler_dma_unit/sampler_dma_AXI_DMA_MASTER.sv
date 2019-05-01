
`timescale 1 ns / 1 ps

	module sampler_dma_v1_0_AXI_DMA_MASTER #
	(
		// Users to add parameters here
		//////////////////////////////////
		// Sampler Parameters
		//////////////////////////////////
		parameter MAX_VOICES                     = 4,
		parameter VOICE_INFO_DMA_BURST_SIZE      = 4, // Burst size of the information table of the voice
		parameter VOICE_STREAM_DMA_BURST_SIZE    = 64, // Burst size of the information table of the voice

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
		// Users to add ports here
		// DMA Start/Stop
		input  wire [ 31 : 0 ]                     dma_control[ MAX_VOICES - 1 : 0 ],
		input  wire [ C_M_AXI_ADDR_WIDTH - 1 : 0 ] dma_base_addr[ MAX_VOICES - 1 : 0 ],
		output wire [ 31 : 0 ]                     dma_status[ MAX_VOICES - 1 : 0 ],
		output wire [ 31 : 0 ]                     dma_curr_addr[ MAX_VOICES - 1 : 0 ],

		// Output FIFO Read
		output wire [ C_M_AXI_DATA_WIDTH : 0 ]     fifo_data_out,
		output wire                                fifo_data_available,
		input  wire                                fifo_data_read,

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

wire dma_addr_wr_done;

///////////////////////////////////////////////////////////////
// Arbiter Signals
//////////////////////////////////////////////////////////////
// Parameters

localparam integer MAX_ARB_COUNT = clogb2( MAX_VOICES );  // Should be able to count to from 0 to MAX_VOICES

localparam REQ_ARB_IDLE     = 4'h0;
localparam REQ_ARB_SCAN     = 4'h1;
localparam REQ_ARB_DMA_REQ  = 4'h2;
localparam REQ_ARB_DMA_REQ2 = 4'h3;

localparam [ MAX_VOICES - 1 : 0 ] MAX_VOICES_CONST_1 = 'h1;


wire [ MAX_VOICES - 1 : 0 ] indv_dma_input_data_valid;
wire [ MAX_VOICES - 1 : 0 ] indv_dma_input_data_last;

reg                              dma_req_reg;     // Request
reg [ 31 : 0 ]                   dma_addr_reg;    // Address
reg [ 7 : 0 ]                    dma_req_len_reg; // Burst Size
reg [ C_M_AXI_ID_WIDTH - 1 : 0 ] dma_req_id_reg;      // Request ID

reg [ MAX_VOICES - 1 : 0 ] dma_req_serviced;

reg [ MAX_VOICES - 1 : 0 ]         indv_dma_req_reg; // Request
reg [ C_M_AXI_ADDR_WIDTH - 1 : 0 ] indv_dma_addr_reg[ MAX_VOICES - 1 : 0 ]; // Address
reg [ 7 : 0 ]                      indv_dma_req_len_reg[ MAX_VOICES - 1 : 0 ]; // Burst Size

(* keep = "true" *) wire [ MAX_VOICES - 1 : 0 ]         indv_dma_req; // Request
(* keep = "true" *) wire [ C_M_AXI_ADDR_WIDTH - 1 : 0 ] indv_dma_addr[ MAX_VOICES - 1 : 0 ]; // Address
(* keep = "true" *) wire [ 7 : 0 ]                      indv_dma_req_len[ MAX_VOICES - 1 : 0 ]; // Burst Size

(* keep = "true" *) wire [ C_M_AXI_DATA_WIDTH - 1 : 0 ] indiv_fifo_data[MAX_VOICES - 1 : 0];
(* keep = "true" *) wire [ MAX_VOICES - 1 : 0 ]         indiv_fifo_data_available;
(* keep = "true" *) reg  [ MAX_VOICES - 1 : 0 ]         indiv_fifo_data_read;
(* keep = "true" *) wire [ MAX_VOICES - 1 : 0 ]         indiv_fifo_data_read_mask;
(* keep = "true" *) wire                                any_indiv_fifo_data_available;

(* keep = "true" *) wire [ C_M_AXI_DATA_WIDTH : 0 ]     mix_fifo_data_out;
(* keep = "true" *) wire                                mix_fifo_data_available;
(* keep = "true" *) wire                                mix_fifo_read;

// Arbiter SM
reg   [ MAX_ARB_COUNT - 1 : 0 ] req_arbiter_count;
reg   [ 3 : 0 ] req_arbiter_curr_st;
logic [ 3 : 0 ] req_arbiter_next_st;

// State Control
(* keep = "true" *) wire all_dma_req;
(* keep = "true" *) wire found_req;
(* keep = "true" *) reg req_done;
(* keep = "true" *) wire end_of_scan;


///////////////////////////////////////////////////////////////
// Mixer Signals
///////////////////////////////////////////////////////////////
(* keep = "true" *) reg [C_M_AXI_DATA_WIDTH - 1 : 0 ] mix_fifo_data_in;
(* keep = "true" *) reg                               data_available_in_current_loop;
(* keep = "true" *) reg [ MAX_ARB_COUNT - 1 : 0 ]     sampler_mixer_count;
(* keep = "true" *) wire                              sampler_mixer_count_last;
(* keep = "true" *) wire                              mix_fifo_wr;


//////////////////////////////////////////////////////////
// Logic
//////////////////////////////////////////////////////////

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
assign M_AXI_RREADY  = 1'b1;


always_ff @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
	if ( ~M_AXI_ARESETN ) begin
		axi_rd_sm_curr_st <= REQ_ARB_IDLE;
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
// Sampler DMA Arbiter
///////////////////////

always_ff @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
	if ( ~M_AXI_ARESETN ) begin
		req_arbiter_curr_st <= REQ_ARB_IDLE;
	end
	else begin
		req_arbiter_curr_st <= req_arbiter_next_st;
	end
end



assign all_dma_req = |{indv_dma_req_reg};

always_comb begin
	case (req_arbiter_curr_st)
		REQ_ARB_IDLE: begin
			if ( all_dma_req ) begin
				req_arbiter_next_st = REQ_ARB_SCAN;
			end
			else begin
				req_arbiter_next_st = REQ_ARB_IDLE;
			end
		end

		REQ_ARB_SCAN: begin
			if ( found_req && end_of_scan ) begin
				req_arbiter_next_st = REQ_ARB_DMA_REQ2; // Go to this special request. The state after that will be idle because it's the last register
			end
			else if ( found_req ) begin
				req_arbiter_next_st = REQ_ARB_DMA_REQ;
			end
			else if ( end_of_scan ) begin
				req_arbiter_next_st = REQ_ARB_IDLE;
			end
			else begin
				req_arbiter_next_st = REQ_ARB_SCAN;
			end
		end

		REQ_ARB_DMA_REQ: begin
			if ( dma_addr_wr_done ) begin
				req_arbiter_next_st = REQ_ARB_SCAN;
			end
			else begin
				req_arbiter_next_st = REQ_ARB_DMA_REQ;
			end
		end

		REQ_ARB_DMA_REQ2: begin // Go to idle instead of continuing with the scan
			if ( dma_addr_wr_done ) begin
				req_arbiter_next_st = REQ_ARB_IDLE;
			end		
			else begin
				req_arbiter_next_st = REQ_ARB_DMA_REQ2;
			end	
		end

		default: begin
			req_arbiter_next_st = REQ_ARB_IDLE;
		end
	endcase
end


assign found_req   = ( (req_arbiter_curr_st == REQ_ARB_SCAN) & ( indv_dma_req_reg[ req_arbiter_count ] == 1'b1 ) ) ? 1'b1 : 1'b0;
assign end_of_scan = req_arbiter_count == (MAX_VOICES - 1);

always_ff @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
	if ( ~M_AXI_ARESETN ) begin
		req_arbiter_count <= 'h0;
		dma_req_reg       <= 'h0;
		dma_addr_reg      <= 'h0;
		dma_req_len_reg   <= 'h0;
		dma_req_id_reg    <= 'h0;
		dma_req_serviced  <= 'h0;
	end
	else begin
		req_arbiter_count <= req_arbiter_count;

		dma_req_reg       <= 1'b0;
		dma_addr_reg      <= dma_addr_reg;
		dma_req_len_reg   <= dma_req_len_reg;
		dma_req_id_reg    <= dma_req_id_reg;

		dma_req_serviced  <= 'h0;

		if ( req_arbiter_curr_st == REQ_ARB_SCAN ) begin
			if ( req_arbiter_count <= (MAX_VOICES - 1) && ( indv_dma_req_reg[ req_arbiter_count ] == 1'b0 ) ) begin
				req_arbiter_count <= req_arbiter_count + 1'b1; // Increase the counter
			end
		end
		else if ( req_arbiter_curr_st == REQ_ARB_DMA_REQ ) begin
			if ( indv_dma_req_reg[ req_arbiter_count ] == 1'b1 ) begin // Check if the DMA request came from which FSM
				// Capture the addressess
				dma_req_reg     <= 1'b1;
				dma_addr_reg    <= indv_dma_addr_reg[ req_arbiter_count ];
				dma_req_len_reg <= indv_dma_req_len_reg[ req_arbiter_count ];
				dma_req_id_reg  <= req_arbiter_count;
				// Let know the individual that the request is being handled
				dma_req_serviced[ req_arbiter_count ] <= 1'b1;
			end
		end
		else if ( req_arbiter_curr_st == REQ_ARB_IDLE ) begin
			req_arbiter_count <= 'h0;
		end

	end
end

/////////////////
// Sample Mixer and FIFO
/////////////////

assign fifo_data_available           = ~fifo_empty;
assign any_indiv_fifo_data_available = |indiv_fifo_data_available;

assign mix_fifo_read = fifo_data_read & ( ~mix_fifo_empty );
assign fifo_data_out = mix_fifo_data_out;
assign fifo_empty    = mix_fifo_empty;

assign sampler_mixer_count_last = ( sampler_mixer_count >= MAX_VOICES );

assign indiv_fifo_data_read_mask = ( sampler_mixer_count_last == 1'b1 ) ? 'h0 : ( MAX_VOICES_CONST_1 << sampler_mixer_count);

assign mix_fifo_wr = ( sampler_mixer_count_last & data_available_in_current_loop & ( ~mix_fifo_full ) );

always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin

	if ( ~M_AXI_ARESETN ) begin
		sampler_mixer_count            <= 'h0;
		mix_fifo_data_in               <= 'h0;
//		mix_fifo_wr                    <= 1'b0;
		indiv_fifo_data_read           <= 'h0;
		data_available_in_current_loop <= 1'b0;
	end
	else begin

		sampler_mixer_count            <= sampler_mixer_count;
		mix_fifo_data_in               <= mix_fifo_data_in;
//		mix_fifo_wr                    <= 1'b0;
		indiv_fifo_data_read           <= 'h0;
		data_available_in_current_loop <= data_available_in_current_loop;

		// While the counter is less than MAX_VOICES
		if ( sampler_mixer_count_last == 1'b0 ) begin
			// Increase the counter
			sampler_mixer_count <= sampler_mixer_count + 1'b1;

			if ( ( any_indiv_fifo_data_available == 1'b1 ) && ( (indiv_fifo_data_available & indiv_fifo_data_read_mask) != 'h0 ) ) begin
					// Mix each channel separately to avoid data corruption
					mix_fifo_data_in[ 15 : 0 ]  <= mix_fifo_data_in[ 15 : 0 ]  + indiv_fifo_data[ sampler_mixer_count ][ 15 : 0 ];
					mix_fifo_data_in[ 31 : 16 ] <= mix_fifo_data_in[ 31 : 16 ] + indiv_fifo_data[ sampler_mixer_count ][ 31 : 16 ];

					// Assert the read signal for the FIFO
					indiv_fifo_data_read <= indiv_fifo_data_read_mask;

					// Flag that indicates that there is thata to be written to the FIFO
					data_available_in_current_loop <= 1'b1;
			end
		end

		// If the counter reached the limit and the mix FIFO is not full, write to the mix FIFO
		if ( ( ~mix_fifo_full ) && ( sampler_mixer_count_last == 1'b1 ) ) begin
			sampler_mixer_count            <= 'h0;
			mix_fifo_data_in               <= 'h0;
//			mix_fifo_wr                    <= data_available_in_current_loop;
			data_available_in_current_loop <= 1'b0;
		end
	end

end

sampler_dma_fifo mix_fifo_inst (
    // Clock and Reset
    .clk ( M_AXI_ACLK     ), // input wire clk
    .rst ( ~M_AXI_ARESETN ), // input wire rst

    // Input
    .din  ( mix_fifo_data_in ), // input wire [31 : 0] din
    .wr_en( mix_fifo_wr      ), // input wire wr_en
    .full ( mix_fifo_full    ), // output wire full

    // Output
    .dout       ( mix_fifo_data_out  ), // output wire [31 : 0] dout
    .rd_en      ( mix_fifo_read      ), // input wire rd_en
    .empty      ( mix_fifo_empty     ), // output wire empty

    // Misc
    .data_count (  )  // output wire [6 : 0] data_count
);


//////////////////////////////////////////////////////

genvar i;
generate 

	for ( i = 0; i < MAX_VOICES; i = i + 1 ) begin: indv_voice_fsm

		/////////////////////////
		// FSM Instantiation
		/////////////////////////

		assign indv_dma_input_data_valid[i] = ( M_AXI_RID == i ) ? M_AXI_RVALID : 1'b0;
		assign indv_dma_input_data_last[i]  = ( M_AXI_RID == i ) ? M_AXI_RLAST  : 1'b0;
		//assign indiv_fifo_data_read[i]      = ( (sampler_mixer_count == i) && (indiv_fifo_data_available[i] == 1'b1) && (mix_fifo_full == 1'b0) ) ? 1'b1 : 1'b0;

		dma_voice_req_fsm #(
    	.VOICE_INFO_DMA_BURST_SIZE       ( VOICE_INFO_DMA_BURST_SIZE      ),
		.VOICE_STREAM_DMA_BURST_SIZE     ( VOICE_STREAM_DMA_BURST_SIZE    ),
    	.C_M_AXI_ADDR_WIDTH              ( C_M_AXI_ADDR_WIDTH             ),
    	.C_M_AXI_DATA_WIDTH              ( C_M_AXI_DATA_WIDTH             )
		) dma_voice_req_fsm_inst (
			// Clock and Reset
			.clk     ( M_AXI_ACLK    ),
			.reset_n ( M_AXI_ARESETN ),

			.start_dma     ( dma_control[i][0] ),
			.stop_dma      ( dma_control[i][1] ),
			.dma_base_addr ( dma_base_addr[i]  ),
			.dma_status    ( dma_status[i]     ),
			.dma_curr_addr ( dma_curr_addr[i]  ),

			// DMA request signals
			.dma_address ( indv_dma_addr[i]    ),
			.dma_req     ( indv_dma_req[i]     ),
			.dma_req_len ( indv_dma_req_len[i] ),

			// Received DMA information
			.dma_input_data       ( M_AXI_RDATA                  ),
			.dma_input_data_valid ( indv_dma_input_data_valid[i] ),
			.dma_input_data_last  ( indv_dma_input_data_last[i]  ),
			
			// FIFO
			.fifo_data_available ( indiv_fifo_data_available[i] ),
			.fifo_data_read      ( indiv_fifo_data_read[i]      ),
			.fifo_data_out       ( indiv_fifo_data[i]           )
		);

		// Glue logic
		always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) 
		begin

			if ( ~M_AXI_ARESETN ) begin
				indv_dma_addr_reg[i]    <= 'h0;
				indv_dma_req_reg[i]     <= 'h0;
				indv_dma_req_len_reg[i] <= 'h0;
			end
			else begin
				indv_dma_req_reg[i]     <= indv_dma_req_reg[i];
				indv_dma_addr_reg[i]    <= indv_dma_addr_reg[i];
				indv_dma_req_len_reg[i] <= indv_dma_req_len_reg[i];

				if ( indv_dma_req[i] ) begin
					indv_dma_req_reg[i]     <= 1'b1;
					indv_dma_addr_reg[i]    <= indv_dma_addr[i];
					indv_dma_req_len_reg[i] <= indv_dma_req_len[i];
				end
				else if ( dma_req_serviced[i] ) begin
					indv_dma_req_reg[i] <= 1'b0;
				end //if ( indv_dma_req[i] ) begin

			end //if ( ~M_AXI_ARESETN ) begin

		end //always_ff @(posedge M_AXI_ACLK, negedge M_AXI_ARESETN) begin

	end // for ( i=0; i < MAX_VOICES; i++ ) begin
endgenerate

endmodule
