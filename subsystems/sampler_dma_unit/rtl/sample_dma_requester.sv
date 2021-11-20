
// +-------------------------------------------------------------------+
// | sample_dma_requester.sv                                               |
// +-------------------------------------------------------------------+
// | This module will perform DMA read requests to the AXI bridge      |
// |                                                                   |
// | This module will receive sample information previously fetched    |
// | from the BRAM and will forward the DMA request tot he AXI bridge. |
// | This operation will continue with no interruptios for all the     |
// | active samples until the last sample is requested. At that point  |
// | the SM will wait to receive all the requested samples before      |
// | starting again                                                    |
// +-------------------------------------------------------------------+


module sample_dma_requester #(
    parameter ENABLE_DEBUG = 1
) (
    input wire clk,
    input wire reset_n,

    // Control interface //
    input wire start, // Start the fetch mechanism
    input wire stop,  // Stop the fetch mechanism

    // AXI Bridge interface //
    output wire [ 31 : 0 ] dma_sample_req_addr,
    output wire [ 5 : 0 ]  dma_sample_req_id,
    output wire [ 7 : 0 ]  dma_sample_req_len,
    output wire            dma_sample_req_valid,
    input  wire            dma_sample_req_done,

    // Data receiver interface //
    input  wire            all_samples_received,
    output wire            last_request_sent,
    output wire [ 5 : 0 ]  last_request_id,

    // Information fetcher interface //
    input  wire [ 31 : 0 ] sample_addr,
    input  wire [ 5 : 0 ]  sample_id,
    input  wire            sample_valid,
    input  wire            sample_overflow,
    input  wire            sample_last,
    output wire            load_next_sample,
    output wire            all_samples_invalid
);

// States
localparam FSM_ST_IDLE                = 0;
localparam FSM_ST_REQ_NEXT_SAMPLE     = 1;
localparam FSM_ST_WAIT_FOR_VALID_INFO = 2;
localparam FSM_ST_SEND_DMA_REQ        = 3;
localparam FSM_ST_WAIT_FOR_REQ_DONE   = 4;
localparam FSM_ST_WAIT_FOR_ALL_DATA   = 5;
localparam FSM_ST_ANALYZE_INFO        = 6;

// State Machine
reg   [ 2 : 0 ] fsm_curr_st;
logic [ 2 : 0 ] fsm_next_st;

// Current states

wire fsm_curr_st_FSM_ST_IDLE;
wire fsm_curr_st_FSM_ST_REQ_NEXT_SAMPLE;
wire fsm_curr_st_FSM_ST_SEND_DMA_REQ;
wire fsm_curr_st_FSM_ST_WAIT_FOR_REQ_DONE;
wire fsm_curr_st_FSM_ST_WAIT_FOR_ALL_DATA;
wire fsm_curr_st_FSM_ST_WAIT_FOR_VALID_INFO;
wire fsm_curr_st_FSM_ST_ANALYZE_INFO;

// Request ID
reg [ 5 : 0 ] last_request_id_reg;
reg           no_requests_sent;
// Output assignments //

// To the fetcher
assign load_next_sample     = fsm_curr_st_FSM_ST_REQ_NEXT_SAMPLE;
assign all_samples_invalid  = fsm_curr_st_FSM_ST_WAIT_FOR_ALL_DATA && no_requests_sent;
assign dma_sample_req_addr  = sample_addr;
assign dma_sample_req_id    = sample_id;
assign dma_sample_req_len   = 64; // TODO: Customize it based on the remaining samples if the remaining samples is less than 64
assign dma_sample_req_valid = fsm_curr_st_FSM_ST_SEND_DMA_REQ;

// To the sample receiver 
assign last_request_sent = ( fsm_curr_st_FSM_ST_WAIT_FOR_REQ_DONE && dma_sample_req_done && sample_last ) | ( fsm_curr_st_FSM_ST_ANALYZE_INFO && sample_overflow && sample_last );
assign last_request_id   = last_request_id_reg;

// Current state assignments //

assign fsm_curr_st_FSM_ST_IDLE                = ( fsm_curr_st == FSM_ST_IDLE                );
assign fsm_curr_st_FSM_ST_REQ_NEXT_SAMPLE     = ( fsm_curr_st == FSM_ST_REQ_NEXT_SAMPLE     );
assign fsm_curr_st_FSM_ST_SEND_DMA_REQ        = ( fsm_curr_st == FSM_ST_SEND_DMA_REQ        );
assign fsm_curr_st_FSM_ST_WAIT_FOR_REQ_DONE   = ( fsm_curr_st == FSM_ST_WAIT_FOR_REQ_DONE   );
assign fsm_curr_st_FSM_ST_WAIT_FOR_ALL_DATA   = ( fsm_curr_st == FSM_ST_WAIT_FOR_ALL_DATA   );
assign fsm_curr_st_FSM_ST_WAIT_FOR_VALID_INFO = ( fsm_curr_st == FSM_ST_WAIT_FOR_VALID_INFO );
assign fsm_curr_st_FSM_ST_ANALYZE_INFO        = ( fsm_curr_st == FSM_ST_ANALYZE_INFO        );

// Current state FF
always_ff @(posedge clk, negedge reset_n) begin
    if (~reset_n) begin
        fsm_curr_st <= FSM_ST_IDLE;
    end
    else begin
        fsm_curr_st <= fsm_next_st;
    end
end

always_comb begin
    case (fsm_curr_st)
        FSM_ST_IDLE: begin
            if ( start && ~stop && sample_valid ) begin
                fsm_next_st = FSM_ST_ANALYZE_INFO; // By default the first sample must be valid
            end
            else begin
                fsm_next_st = FSM_ST_IDLE;
            end
        end

        FSM_ST_WAIT_FOR_VALID_INFO: begin
            if( stop ) begin
                fsm_next_st = FSM_ST_IDLE;
            end
            else if( sample_valid ) begin
                fsm_next_st = FSM_ST_ANALYZE_INFO;
            end
            else begin
                fsm_next_st = FSM_ST_WAIT_FOR_VALID_INFO;
            end
        end

        FSM_ST_ANALYZE_INFO: begin
            if ( sample_overflow ) begin
                if ( sample_last ) begin
                    fsm_next_st = FSM_ST_WAIT_FOR_ALL_DATA;
                end
                else begin
                    fsm_next_st = FSM_ST_REQ_NEXT_SAMPLE;
                end
            end
            else begin
                fsm_next_st = FSM_ST_SEND_DMA_REQ;
            end
        end

        FSM_ST_REQ_NEXT_SAMPLE: begin
            fsm_next_st = FSM_ST_WAIT_FOR_VALID_INFO;
        end

        FSM_ST_SEND_DMA_REQ: begin
            fsm_next_st = FSM_ST_WAIT_FOR_REQ_DONE;
        end

        FSM_ST_WAIT_FOR_REQ_DONE: begin
            if( stop ) begin
                fsm_next_st = FSM_ST_IDLE;
            end
            else if ( dma_sample_req_done ) begin
                if ( sample_last ) begin
                    fsm_next_st = FSM_ST_WAIT_FOR_ALL_DATA;
                end
                else begin
                    fsm_next_st = FSM_ST_REQ_NEXT_SAMPLE;
                end
            end
            else begin
                fsm_next_st = FSM_ST_WAIT_FOR_REQ_DONE;
            end
        end

        FSM_ST_WAIT_FOR_ALL_DATA: begin
            if ( stop | no_requests_sent ) begin
                fsm_next_st = FSM_ST_IDLE;
            end
            else if ( all_samples_received ) begin
                fsm_next_st = FSM_ST_REQ_NEXT_SAMPLE;
            end
            else begin
                fsm_next_st = FSM_ST_WAIT_FOR_ALL_DATA;
            end
        end

        default: begin
            fsm_next_st = FSM_ST_IDLE;
        end
    endcase
end


always_ff @(posedge clk, negedge reset_n) begin
    if ( ~reset_n ) begin
        last_request_id_reg <= 'h0;
    end
    else begin
        last_request_id_reg <= last_request_id_reg;

        if ( fsm_curr_st_FSM_ST_ANALYZE_INFO && sample_valid && ~sample_overflow ) begin
            last_request_id_reg <= sample_id;
        end
        else begin
            last_request_id_reg <= last_request_id_reg;
        end

    end
end

// Register that checks if there were no requests sent which means that
// all the samples have overflowed.
always_ff @(posedge clk, negedge reset_n) begin
    if ( ~reset_n ) begin
        no_requests_sent <= 1'b1;
    end
    else begin
        no_requests_sent <= no_requests_sent;

        if ( dma_sample_req_valid ) begin
            no_requests_sent <= 1'b0;
        end
        else if ( fsm_curr_st_FSM_ST_IDLE || ( fsm_curr_st_FSM_ST_WAIT_FOR_ALL_DATA && all_samples_received ) ) begin
            no_requests_sent <= 1'b1;
        end
    end
end

generate;
    if( ENABLE_DEBUG == 1 ) begin
        sample_dma_requester_ILA your_instance_name (
            .clk(clk), // input wire clk

            .probe0   ( dma_sample_req_addr  ), // input wire [31:0]  probe0  
            .probe1   ( dma_sample_req_id    ), // input wire [5:0]  probe1 
            .probe2   ( dma_sample_req_len   ), // input wire [7:0]  probe2 
            .probe3   ( dma_sample_req_valid ), // input wire [0:0]  probe3 
            .probe4   ( dma_sample_req_done  ), // input wire [0:0]  probe4 
            .probe5   ( all_samples_received ), // input wire [0:0]  probe5 
            .probe6   ( last_request_sent    ), // input wire [0:0]  probe6 
            .probe7   ( last_request_id      ), // input wire [5:0]  probe7 
            .probe8   ( sample_addr          ), // input wire [31:0]  probe8 
            .probe9   ( sample_id            ), // input wire [5:0]  probe9 
            .probe10  ( sample_valid         ), // input wire [0:0]  probe10 
            .probe11  ( sample_last          ), // input wire [0:0]  probe11 
            .probe12  ( load_next_sample     ), // input wire [0:0]  probe12 
            .probe13  ( fsm_curr_st          ), // input wire [2:0]  probe13
            .probe14  ( sample_overflow      ), // input wire [0:0]  probe14
            .probe15  ( no_requests_sent     ), // input wire [0:0]  probe15
            .probe16  ( all_samples_invalid  )  // input wire [0:0]  probe16
        );
    end
endgenerate

endmodule