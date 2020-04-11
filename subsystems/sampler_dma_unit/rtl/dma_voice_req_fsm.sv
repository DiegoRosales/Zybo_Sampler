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

    input  wire                                start_dma,
    input  wire                                stop_dma,
    input  wire [ C_M_AXI_ADDR_WIDTH - 1 : 0 ] dma_base_addr,
    input  wire [ 29 : 0 ]                     dma_length,
	output wire [ 31 : 0 ]                     dma_status,
	output wire [ 31 : 0 ]                     dma_curr_addr,

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


// State Machine
localparam NUMBER_OF_FSM_STATES                 = 4;
localparam VOICE_DMA_ST_IDLE                    = 4'b0001;
localparam VOICE_DMA_ST_STREAM_REQ              = 4'b0010;
localparam VOICE_DMA_ST_WAIT_FOR_STREAM         = 4'b0100;
localparam VOICE_DMA_ST_WAIT_FOR_STOP           = 4'b1000;

reg   [ NUMBER_OF_FSM_STATES - 1 : 0 ] voice_dma_sm_curr_st;
logic [ NUMBER_OF_FSM_STATES - 1 : 0 ] voice_dma_sm_next_st;
// State Control
wire dma_done;
wire stop_stream;
wire stream_req_sent;
wire stream_stopped;

wire voice_dma_sm_curr_st_VOICE_DMA_ST_IDLE;
wire voice_dma_sm_curr_st_VOICE_DMA_ST_WAIT_FOR_STREAM;
wire voice_dma_sm_curr_st_VOICE_DMA_ST_WAIT_FOR_STOP;
wire voice_dma_sm_curr_st_VOICE_DMA_ST_STREAM_REQ;

//////////////////////////////////
// Information request and data signals
//////////////////////////////////
// Information signals
wire [ 31 : 0 ] voice_start_addr;
wire [ 31 : 0 ] voice_stream_length;
reg  [ 31 : 0 ] voice_stream_end_addr;
wire            voice_stream_byte_overflow;

//////////////////////////////////
// Voice Stream request and data signals
//////////////////////////////////
reg   [ C_M_AXI_ADDR_WIDTH - 1 : 0 ] voice_stream_addr;
wire  [ C_M_AXI_ADDR_WIDTH - 1 : 0 ] voice_stream_addr_next;
reg                                  voice_stream_req;

//////////////////////////////////
// FIFO Signals
//////////////////////////////////
wire [ 31 : 0 ] input_fifo_data_in;
wire            input_fifo_data_in_valid;
wire            input_fifo_data_in_write;
wire            fifo_full;
wire            fifo_empty;
wire [ 6 : 0 ]  fifo_data_count;

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
                voice_dma_sm_next_st = VOICE_DMA_ST_STREAM_REQ; // Start requesting the sample data
            end
            else begin
                voice_dma_sm_next_st = VOICE_DMA_ST_IDLE;
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
                voice_dma_sm_next_st = VOICE_DMA_ST_WAIT_FOR_STOP;
            end
            else if ( stream_received ) begin
                voice_dma_sm_next_st = VOICE_DMA_ST_STREAM_REQ;
            end
            else begin
                voice_dma_sm_next_st = VOICE_DMA_ST_WAIT_FOR_STREAM;
            end
        end

        VOICE_DMA_ST_WAIT_FOR_STOP: begin
            if ( stream_stopped ) begin
                voice_dma_sm_next_st = VOICE_DMA_ST_IDLE;
            end
        end

        default: begin
            voice_dma_sm_next_st = VOICE_DMA_ST_IDLE;
        end

    endcase
end
// DMA States
assign voice_dma_sm_curr_st_VOICE_DMA_ST_IDLE                 = voice_dma_sm_curr_st[0];//( voice_dma_sm_curr_st == VOICE_DMA_ST_IDLE            );
assign voice_dma_sm_curr_st_VOICE_DMA_ST_STREAM_REQ           = voice_dma_sm_curr_st[1];//( voice_dma_sm_curr_st == VOICE_DMA_ST_STREAM_REQ      );
assign voice_dma_sm_curr_st_VOICE_DMA_ST_WAIT_FOR_STREAM      = voice_dma_sm_curr_st[2];//( voice_dma_sm_curr_st == VOICE_DMA_ST_WAIT_FOR_STREAM );
assign voice_dma_sm_curr_st_VOICE_DMA_ST_WAIT_FOR_STOP        = voice_dma_sm_curr_st[3];//( voice_dma_sm_curr_st == VOICE_DMA_ST_WAIT_FOR_STOP   );

/////////////////////////////////////////////////////////////////////////
// This controls the initial information request
/////////////////////////////////////////////////////////////////////////

assign stream_stopped             = voice_dma_sm_curr_st_VOICE_DMA_ST_WAIT_FOR_STOP & input_fifo_data_in_write;
assign voice_start_addr           = dma_base_addr;
assign voice_stream_length        = dma_length;
assign voice_stream_byte_overflow = ( voice_stream_addr_next >= voice_stream_end_addr );
assign stop_stream                = stop_dma | voice_stream_byte_overflow;
assign dma_done                   = dma_input_data_last; // DMA is done when the last data has been received

/////////////////////////////////////////////////////////////////////////
// This controls the stream request
/////////////////////////////////////////////////////////////////////////

assign stream_req_sent        = voice_dma_sm_curr_st_VOICE_DMA_ST_STREAM_REQ & dma_req;
assign stream_received        = voice_dma_sm_curr_st_VOICE_DMA_ST_WAIT_FOR_STREAM & dma_done;
assign voice_stream_addr_next = voice_stream_addr + 32'h4;

always_ff @(posedge clk, negedge reset_n) begin
    if (~reset_n) begin
        voice_stream_addr     <= 'h0;
        voice_stream_req      <= 1'b0;
        voice_stream_end_addr <= 'h0;
    end
    else begin
        voice_stream_addr     <= voice_stream_addr;
        voice_stream_req      <= 1'b0;
        voice_stream_end_addr <= voice_stream_end_addr;

        if ( voice_dma_sm_curr_st_VOICE_DMA_ST_IDLE & start_dma ) begin
            voice_stream_addr       <= voice_start_addr;                       // Initialize the address when the information is received
            voice_stream_end_addr   <= voice_start_addr + voice_stream_length; // Initialize the end address to avoid overflow
        end

        if ( voice_dma_sm_curr_st_VOICE_DMA_ST_WAIT_FOR_STREAM & dma_input_data_valid ) begin
            voice_stream_addr <= voice_stream_addr_next;
        end

        // Check if the FIFO is completely empty to request a new DMA
        if ( voice_dma_sm_curr_st_VOICE_DMA_ST_STREAM_REQ & fifo_empty ) begin
            voice_stream_req    <= 1'b1;
        end


    end
end


assign dma_address = voice_stream_addr;
assign dma_req     = voice_stream_req;

assign dma_req_len = VOICE_STREAM_DMA_BURST_SIZE;

////////////////////////////////////////////////
// FIFO
////////////////////////////////////////////////

assign input_fifo_data_in_ready = ~fifo_full;
assign fifo_data_available      = ~fifo_empty;
assign input_fifo_data_in       = ( voice_dma_sm_curr_st_VOICE_DMA_ST_WAIT_FOR_STOP ) ? 'h0 : dma_input_data;
assign input_fifo_data_in_valid = ( voice_dma_sm_curr_st_VOICE_DMA_ST_WAIT_FOR_STREAM & dma_input_data_valid ) | voice_dma_sm_curr_st_VOICE_DMA_ST_WAIT_FOR_STOP;
assign input_fifo_data_in_write = input_fifo_data_in_valid & input_fifo_data_in_ready;


sampler_dma_fifo sampler_dma_fifo_inst (
    // Clock and Reset
    .clk ( clk      ), // input wire clk
    .rst ( ~reset_n ), // input wire rst

    // Input
    .din  ( input_fifo_data_in       ), // input wire [31 : 0] din
    .wr_en( input_fifo_data_in_write ), // input wire wr_en
    .full ( fifo_full                ), // output wire full

    // Output
    .rd_en      ( fifo_data_read            ), // input wire rd_en
    .dout       ( fifo_data_out             ), // output wire [31 : 0] dout
    .empty      ( fifo_empty                ), // output wire empty

    // Misc
    .data_count ( fifo_data_count )  // output wire [6 : 0] data_count
);

//////////////////////////////////////////
// Status Register Assignments
//////////////////////////////////////////
// Status
assign dma_status = 'h0;
// Current Address
assign dma_curr_addr = 'h0;
endmodule