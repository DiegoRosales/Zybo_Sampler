//////////////////////////////////////////////
// This state machine will handle the individual voice
// requests from the system memory
//////////////////////////////////////////////
// This module will receive a DMA request with the base
// address of the voice information
//////////////////////////////////////////////


(* keep_hierarchy = "yes" *) module dma_voice_req_fsm # (
    parameter VOICE_INFO_DMA_BURST_SIZE      = 4, // Burst size of the information table of the voice
    parameter VOICE_STREAM_DMA_BURST_SIZE    = 64, // Burst size of the information table of the voice
    // Width of Address Bus
    parameter integer C_M_AXI_ADDR_WIDTH	= 32,
    // Width of Data Bus
    parameter integer C_M_AXI_DATA_WIDTH	= 32
    ) (
    // Clock and Reset
    input wire clk,
    input wire reset_n,

    input wire                                start_dma,
    input wire                                stop_dma,
    input wire [ C_M_AXI_ADDR_WIDTH - 1 : 0 ] dma_base_addr,

    // DMA request signals
    output wire [ C_M_AXI_ADDR_WIDTH - 1 : 0 ] dma_address,
    output wire                                dma_req,
    output wire [7 : 0 ]                       dma_req_len,

    // Received DMA information
    input wire [ C_M_AXI_DATA_WIDTH - 1 : 0 ] dma_input_data,
    input wire                                dma_input_data_valid,
    input wire                                dma_input_data_last,

    /////////////////////////////////////
    // FIFO Signals
    /////////////////////////////////////
    output wire            fifo_data_available,
    input  wire            fifo_data_read,
    output wire [ 31 : 0 ] fifo_data_out
);

// function called clogb2 that returns an integer which has the 
// value of the ceiling of the log base 2.                      
function integer clogb2 (input integer bit_depth);              
    begin                                                           
        for(clogb2=0; bit_depth>0; clogb2=clogb2+1)                   
            bit_depth = bit_depth >> 1;                                 
    end                                                           
endfunction

localparam VOICE_INFO_DATA_STRUCTURE_SIZE = 4; // Number of registers of the voice data structure
localparam integer MAX_INFO_COUNT         = clogb2( VOICE_INFO_DATA_STRUCTURE_SIZE - 1 ); // Get how many bits are needed for the max count
localparam DMA_STREAM_ADDR_INCR           = (VOICE_STREAM_DMA_BURST_SIZE << 2);


// State Machine
localparam VOICE_DMA_ST_IDLE                    = 4'h0;
localparam VOICE_DMA_ST_SAMPLE_INFO_REQ         = 4'h1;
localparam VOICE_DMA_ST_WAIT_FOR_SAMPLE_INFO    = 4'h2;
localparam VOICE_DMA_ST_STREAM_REQ              = 4'h3;
localparam VOICE_DMA_ST_WAIT_FOR_STREAM         = 4'h4;

reg   [ 3 : 0 ] voice_dma_sm_curr_st;
logic [ 3 : 0 ] voice_dma_sm_next_st;
// State Control
wire dma_done;
wire voice_info_req_sent;
wire voice_info_received;
wire stop_stream;
wire stream_req_sent;

//////////////////////////////////
// Information request and data signals
//////////////////////////////////
(* keep = "true" *) reg  [ C_M_AXI_ADDR_WIDTH - 1 : 0 ] voice_info_addr;
(* keep = "true" *) wire                                voice_info_req;
(* keep = "true" *) reg  [ MAX_INFO_COUNT - 1 : 0 ]     info_count;
(* keep = "true" *) reg  [ 31 : 0 ]                     voice_information_reg[ VOICE_INFO_DATA_STRUCTURE_SIZE - 1 : 0 ];
// Information signals
(* keep = "true" *) wire [ 31 : 0 ] voice_start_addr;
(* keep = "true" *) wire [ 31 : 0 ] voice_stream_length;
(* keep = "true" *) reg  [ 31 : 0 ] voice_stream_count;

//////////////////////////////////
// Voice Stream request and data signals
//////////////////////////////////
(* keep = "true" *) reg   [ C_M_AXI_ADDR_WIDTH - 1 : 0 ] voice_stream_addr;
(* keep = "true" *) wire  [ C_M_AXI_ADDR_WIDTH - 1 : 0 ] voice_stream_addr_next;
(* keep = "true" *) reg                                  voice_stream_req;

//////////////////////////////////
// FIFO Signals
//////////////////////////////////
wire [ 31 : 0 ] input_fifo_data_in;
wire            input_fifo_data_in_valid;
wire            fifo_full;
wire            fifo_empty;

//////////////////////////////////////////////////////////////////////////

always_ff @(posedge clk, negedge reset_n) begin
    if (~reset_n) begin
        voice_dma_sm_curr_st <= VOICE_DMA_ST_IDLE;
    end
    else begin
        voice_dma_sm_curr_st <= voice_dma_sm_next_st;
    end
end


always_comb begin
    case (voice_dma_sm_curr_st)
        VOICE_DMA_ST_IDLE: begin
            if ( start_dma ) begin
                voice_dma_sm_next_st = VOICE_DMA_ST_SAMPLE_INFO_REQ; // Start requesting the sample information
            end
            else begin
                voice_dma_sm_next_st = VOICE_DMA_ST_IDLE;
            end
        end
        VOICE_DMA_ST_SAMPLE_INFO_REQ: begin
            if ( voice_info_req_sent ) begin
                voice_dma_sm_next_st = VOICE_DMA_ST_WAIT_FOR_SAMPLE_INFO; // Wait until the information has been received
            end
            else begin
                voice_dma_sm_next_st = VOICE_DMA_ST_SAMPLE_INFO_REQ;
            end
        end
        VOICE_DMA_ST_WAIT_FOR_SAMPLE_INFO: begin
            if ( voice_info_received ) begin
                voice_dma_sm_next_st = VOICE_DMA_ST_STREAM_REQ; // Start streaming the sample information
            end
            else begin
                voice_dma_sm_next_st = VOICE_DMA_ST_WAIT_FOR_SAMPLE_INFO;
            end
        end
        VOICE_DMA_ST_STREAM_REQ: begin
            if ( stream_req_sent ) begin
                voice_dma_sm_next_st = VOICE_DMA_ST_WAIT_FOR_STREAM;
            end
            else begin
                voice_dma_sm_next_st = VOICE_DMA_ST_STREAM_REQ;
            end
        end
        VOICE_DMA_ST_WAIT_FOR_STREAM: begin
            if ( stop_stream ) begin
                voice_dma_sm_next_st = VOICE_DMA_ST_IDLE;
            end
            else if ( stream_received ) begin
                voice_dma_sm_next_st = VOICE_DMA_ST_STREAM_REQ;
            end
            else begin
                voice_dma_sm_next_st = VOICE_DMA_ST_WAIT_FOR_STREAM;
            end
        end        
        default: begin
            voice_dma_sm_next_st = VOICE_DMA_ST_IDLE;
        end
    endcase
end

/////////////////////////////////////////////////////////////////////////
// This controls the initial information request
/////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////
// Voice Information Data Structure
//////////////////////////////////////////
// |--------------------------|
// |       START ADDRESS      | [0]
// |==========================|
// |       STREAM LENGTH      | [1]
// |--------------------------|
// |<-------- 32-bit -------->|
//////////////////////////////////////////
assign voice_info_req      = voice_dma_sm_curr_st == VOICE_DMA_ST_SAMPLE_INFO_REQ;
assign voice_info_req_sent = ( voice_dma_sm_curr_st == VOICE_DMA_ST_SAMPLE_INFO_REQ )      ? dma_req  : 1'b0;
assign voice_info_received = ( voice_dma_sm_curr_st == VOICE_DMA_ST_WAIT_FOR_SAMPLE_INFO ) ? dma_done : 1'b0;
assign voice_start_addr    = voice_information_reg[ 0 ];
assign voice_stream_length = voice_information_reg[ 1 ];
assign stop_stream         = stop_dma | ( voice_stream_count > voice_stream_length );
assign dma_done            = dma_input_data_last; // DMA is done when the last data has been received

// DMA Info Address
always_ff @(posedge clk, negedge reset_n) begin
    if (~reset_n) begin
        voice_info_addr <= 'h0;
    end
    else begin
        voice_info_addr <= dma_base_addr;
    end
end

// DMA Info Data Gather
always_ff @(posedge clk, negedge reset_n) begin
    if (~reset_n) begin
        info_count            <= 'h0;
        voice_information_reg <= '{VOICE_INFO_DATA_STRUCTURE_SIZE{'h0}};
    end
    else begin
        info_count            <= info_count;
        voice_information_reg <= voice_information_reg;

        // Reset the counter
        if ( voice_dma_sm_curr_st == VOICE_DMA_ST_SAMPLE_INFO_REQ ) begin
            info_count      <= 'h0;
        end

        // Sample the data
        if ( voice_dma_sm_curr_st == VOICE_DMA_ST_WAIT_FOR_SAMPLE_INFO ) begin
            if ( dma_input_data_valid & ( info_count < MAX_INFO_COUNT ) ) begin
                voice_information_reg[ info_count ] <= dma_input_data;    // Sample the data
                info_count                          <= info_count + 1'b1; // Increase the counter
            end
        end

    end
end

/////////////////////////////////////////////////////////////////////////
// This controls the stream request
/////////////////////////////////////////////////////////////////////////

assign stream_req_sent        = ( voice_dma_sm_curr_st == VOICE_DMA_ST_STREAM_REQ ) ? dma_req : 1'b0;
assign stream_received        = ( voice_dma_sm_curr_st == VOICE_DMA_ST_WAIT_FOR_STREAM ) ? dma_done : 1'b0;
assign voice_stream_addr_next = ( ( voice_dma_sm_curr_st == VOICE_DMA_ST_WAIT_FOR_STREAM ) & ( dma_input_data_valid == 1'b1 ) ) ? ( voice_stream_addr + 'h4 ) : voice_stream_addr;

always_ff @(posedge clk, negedge reset_n) begin
    if (~reset_n) begin
        voice_stream_addr  <= 'h0;
        voice_stream_req   <= 1'b0;
        voice_stream_count <= 'h0;
    end
    else begin
        voice_stream_addr <= voice_stream_addr_next;
        voice_stream_req   <= 1'b0;
        voice_stream_count <= voice_stream_count;

        if ( voice_info_received ) begin
            voice_stream_addr  <= voice_start_addr; // Initialize the address when the information is received
            voice_stream_count <= 'h0;              // Initialize the count
        end

        if ( stream_received ) begin // Increment the stream count
            voice_stream_count <= voice_stream_count + 1;
        end

        // Check if the FIFO is completely empty to request a new DMA
        if ( ( voice_dma_sm_curr_st == VOICE_DMA_ST_STREAM_REQ ) && ( fifo_empty == 1'b1 ) ) begin
            voice_stream_req    <= 1'b1;
        end
    end
end


assign dma_address = ( ( voice_dma_sm_curr_st == VOICE_DMA_ST_SAMPLE_INFO_REQ ) | ( voice_dma_sm_curr_st == VOICE_DMA_ST_WAIT_FOR_SAMPLE_INFO ) ) ? voice_info_addr : voice_stream_addr;
assign dma_req     = voice_info_req | voice_stream_req;

assign dma_req_len = ( voice_info_req ) ? VOICE_INFO_DMA_BURST_SIZE : VOICE_STREAM_DMA_BURST_SIZE;

////////////////////////////////////////////////
// FIFO
////////////////////////////////////////////////

assign input_fifo_data_in_ready = ~fifo_full;
assign input_fifo_data_in       = dma_input_data;
assign input_fifo_data_in_valid = ( voice_dma_sm_curr_st == VOICE_DMA_ST_WAIT_FOR_STREAM && input_fifo_data_in_ready == 1'b1) ? dma_input_data_valid : 1'b0;
assign input_fifo_data_in_last  = ( voice_dma_sm_curr_st == VOICE_DMA_ST_WAIT_FOR_STREAM && input_fifo_data_in_ready == 1'b1) ? dma_input_data_last  : 1'b0;
assign fifo_data_available      = ~fifo_empty;


sampler_dma_fifo sampler_dma_fifo_inst (
    // Clock and Reset
    .clk ( clk      ), // input wire clk
    .rst ( ~reset_n ), // input wire rst

    // Input
    .din  ( input_fifo_data_in       ), // input wire [31 : 0] din
    .wr_en( input_fifo_data_in_valid ), // input wire wr_en
    .full ( fifo_full                ), // output wire full

    // Output
    .rd_en      ( fifo_data_read            ), // input wire rd_en
    .dout       ( fifo_data_out             ), // output wire [31 : 0] dout
    .empty      ( fifo_empty                ), // output wire empty

    // Misc
    .data_count (  )  // output wire [6 : 0] data_count
);

endmodule