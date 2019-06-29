// +-------------------------------------------------------------------------+
// | sample_dma_receiver.sv                                                  |
// +-------------------------------------------------------------------------+
// | This module will receive and store the sample data from the DMA engine, |
// |                                                                         |
// | This module will receive sample data from the AXI bridge and will store |
// | it in a FIFO. It will receive and mix the data from all the requested   |
// | samples of a single sample sequence.                                    |
// | Once the module receives the last sample data, it will signal the       |
// | requester to request the next batch. This module will also signal the   |
// | output FIFO to fetch the mixed samples for the playback                 |
// +-------------------------------------------------------------------------+


module sample_dma_receiver #(
    parameter ENABLE_DEBUG = 1
)(
    input wire clk,
    input wire reset_n,

    input wire stop,

    // DMA Requester interface //
    output wire           all_samples_received,
    input  wire           last_request_sent,
    input  wire [ 5 : 0 ] last_request_id,
    input  wire           all_samples_invalid,

    // AXI Bridge Interface //
    input  wire [ 31 : 0 ] axi_sample_data,
    input  wire [ 5 : 0 ]  axi_sample_id,
    input  wire            axi_sample_valid,
    input  wire            axi_sample_data_last,
    output wire            axi_sample_receiver_ready,

    // Output FIFO interface //
    output wire [ 31 : 0 ] sample_data,
    output wire            sample_data_available,
    input  wire            sample_data_read

);

// States
localparam FSM_ST_IDLE                   = 0;
localparam FSM_ST_START                  = 1;
localparam FSM_ST_WAIT_FOR_SAMPLE_DATA_0 = 2;
localparam FSM_ST_WAIT_FOR_SAMPLE_DATA_1 = 3;
localparam FSM_ST_WAIT_FOR_FIFO_EMPTY    = 4;


wire fsm_curr_st_FSM_ST_IDLE;
wire fsm_curr_st_FSM_ST_START;
wire fsm_curr_st_FSM_ST_WAIT_FOR_SAMPLE_DATA_0;
wire fsm_curr_st_FSM_ST_WAIT_FOR_FIFO_EMPTY;
wire fsm_curr_st_FSM_ST_WAIT_FOR_SAMPLE_DATA_1;

// State Machine
reg   [ 2 : 0 ] fsm_curr_st;
logic [ 2 : 0 ] fsm_next_st;

// FIFO Signals
wire           fifo_reset;
wire [ 6 : 0 ] fifo_data_count;

// Mix registers
wire [ 15 : 0 ] mix_data_left;
wire [ 15 : 0 ] mix_data_right;
wire [ 31 : 0 ] mix_fifo_data_in;
wire [ 31 : 0 ] mix_fifo_data_out;
wire            mix_data_wr;
wire            mix_data_rd;
wire            mix_fifo_data_rd;
wire            mix_fifo_data_wr;
wire            mix_fifo_full;
wire            mix_fifo_empty;

// Last sample ID
reg [ 5 : 0 ] last_request_id_reg;
reg [ 5 : 0 ] last_received_id_reg;
reg           last_request_sent_reg;
wire          sample_id_is_last;
reg           axi_sample_data_last_reg;

// The receiver is ready when the FIFO has been emptied after the data from all samples were received
assign axi_sample_receiver_ready = ~mix_fifo_full && ~fsm_curr_st_FSM_ST_IDLE && ~fsm_curr_st_FSM_ST_WAIT_FOR_FIFO_EMPTY;
assign all_samples_received      = fsm_curr_st_FSM_ST_START;

// Current state assignments
assign fsm_curr_st_FSM_ST_IDLE                   = ( fsm_curr_st == FSM_ST_IDLE                   );
assign fsm_curr_st_FSM_ST_START                  = ( fsm_curr_st == FSM_ST_START                  );
assign fsm_curr_st_FSM_ST_WAIT_FOR_SAMPLE_DATA_0 = ( fsm_curr_st == FSM_ST_WAIT_FOR_SAMPLE_DATA_0 );
assign fsm_curr_st_FSM_ST_WAIT_FOR_SAMPLE_DATA_1 = ( fsm_curr_st == FSM_ST_WAIT_FOR_SAMPLE_DATA_1 );
assign fsm_curr_st_FSM_ST_WAIT_FOR_FIFO_EMPTY    = ( fsm_curr_st == FSM_ST_WAIT_FOR_FIFO_EMPTY    );

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
            if ( stop | all_samples_invalid ) begin
                fsm_next_st = FSM_ST_IDLE;
            end
            else begin
                fsm_next_st = FSM_ST_WAIT_FOR_SAMPLE_DATA_0;
            end
        end

        FSM_ST_START: begin
            if ( stop | all_samples_invalid ) begin
                fsm_next_st = FSM_ST_IDLE;
            end           
            else begin
                fsm_next_st = FSM_ST_WAIT_FOR_SAMPLE_DATA_0;
            end
        end

        FSM_ST_WAIT_FOR_SAMPLE_DATA_0: begin
            if ( stop | all_samples_invalid ) begin
                fsm_next_st = FSM_ST_IDLE;
            end            
            else if ( axi_sample_data_last ) begin
                if ( last_request_sent_reg && sample_id_is_last ) begin
                    fsm_next_st = FSM_ST_WAIT_FOR_FIFO_EMPTY;
                end
                else begin
                    fsm_next_st = FSM_ST_WAIT_FOR_SAMPLE_DATA_1;
                end
            end
            else begin
                fsm_next_st = FSM_ST_WAIT_FOR_SAMPLE_DATA_0;
            end
        end

        FSM_ST_WAIT_FOR_SAMPLE_DATA_1: begin
            if ( stop | all_samples_invalid ) begin
                fsm_next_st = FSM_ST_IDLE;
            end
            else if ( axi_sample_data_last_reg  && last_request_sent_reg && sample_id_is_last ) begin
                fsm_next_st = FSM_ST_WAIT_FOR_FIFO_EMPTY;
            end
            else begin
                fsm_next_st = FSM_ST_WAIT_FOR_SAMPLE_DATA_1;
            end
        end

        FSM_ST_WAIT_FOR_FIFO_EMPTY: begin
            if ( stop | all_samples_invalid ) begin
                fsm_next_st = FSM_ST_IDLE;
            end
            else if ( mix_fifo_empty ) begin
                fsm_next_st = FSM_ST_START;
            end
            else begin
                fsm_next_st = FSM_ST_WAIT_FOR_FIFO_EMPTY;
            end
        end


    endcase
end

// AXI Data last register
// Sample the data last to avoid a race condition if the requester takes longer to determine that the last sample
// has been requested
always_ff @(posedge clk, posedge reset_n) begin
    if ( ~reset_n ) begin
        axi_sample_data_last_reg <= 1'b0;
    end
    else begin
        axi_sample_data_last_reg <= axi_sample_data_last_reg;

        if ( axi_sample_data_last && axi_sample_valid ) begin
            axi_sample_data_last_reg <= 1'b1;
        end
        else if ( axi_sample_valid ) begin
            axi_sample_data_last_reg <= 1'b0;
        end
    end
    
end

// Check if the current sample ID matches the last sample ID and the transaction is valid
assign sample_id_is_last = ( last_request_id_reg == last_received_id_reg ) ? axi_sample_data_last_reg : 1'b0;

// Last sample ID FF
always_ff @(posedge clk, negedge reset_n) begin
    if ( ~reset_n ) begin
        last_request_id_reg   <= 'h0;
        last_request_sent_reg <= 1'b0;
        last_received_id_reg  <= 'h0;
    end
    else begin
        last_request_id_reg   <= last_request_id_reg;
        last_request_sent_reg <= last_request_sent_reg;
        last_received_id_reg  <= last_received_id_reg;

        // Get the sample ID of the last request
        if ( last_request_sent ) begin
            last_request_id_reg   <= last_request_id;
            last_request_sent_reg <= 1'b1;
        end
        else if ( fsm_curr_st_FSM_ST_IDLE || fsm_curr_st_FSM_ST_WAIT_FOR_FIFO_EMPTY ) begin
            last_request_sent_reg <= 1'b0;
        end

        if ( axi_sample_valid ) begin
            last_received_id_reg <= axi_sample_id;
        end
    end
end

/////////////////
// Mixer FF
/////////////////
assign mix_fifo_data_in = { mix_data_right, mix_data_left };

// Mix the new data with the previous data
assign mix_data_left  = ( fsm_curr_st_FSM_ST_WAIT_FOR_SAMPLE_DATA_1 == 1'b1 ) ? ( axi_sample_data[ 15 : 0 ]  + mix_fifo_data_out[ 15 : 0 ]  ) : axi_sample_data[ 15 : 0 ];
assign mix_data_right = ( fsm_curr_st_FSM_ST_WAIT_FOR_SAMPLE_DATA_1 == 1'b1 ) ? ( axi_sample_data[ 31 : 16 ] + mix_fifo_data_out[ 31 : 16 ] ) : axi_sample_data[ 31 : 16 ];
assign mix_data_wr    = ( fsm_curr_st_FSM_ST_WAIT_FOR_SAMPLE_DATA_0 | fsm_curr_st_FSM_ST_WAIT_FOR_SAMPLE_DATA_1 ) && axi_sample_valid;
assign mix_data_rd    = ( fsm_curr_st_FSM_ST_WAIT_FOR_SAMPLE_DATA_1 ) && axi_sample_valid;

assign mix_fifo_data_rd = mix_data_rd | ( sample_data_read & sample_data_available );
assign mix_fifo_data_wr = mix_data_wr;
assign fifo_reset       = ~reset_n | stop;


//////////////////
// Outputs
//////////////////
assign sample_data           = mix_fifo_data_out;
assign sample_data_available = fsm_curr_st_FSM_ST_WAIT_FOR_FIFO_EMPTY && ~mix_fifo_empty;
sampler_dma_fifo mix_fifo (
    // Clock and Reset
    .clk ( clk        ), // input wire clk
    .rst ( fifo_reset ), // input wire rst

    // Input
    .din  ( mix_fifo_data_in ), // input wire [31 : 0] din
    .wr_en( mix_fifo_data_wr ), // input wire wr_en
    .full ( mix_fifo_full    ), // output wire full

    // Output
    .dout  ( mix_fifo_data_out ), // output wire [31 : 0] dout
    .rd_en ( mix_fifo_data_rd  ), // input wire rd_en
    .empty ( mix_fifo_empty    ), // output wire empty

    // Misc
    .data_count ( fifo_data_count )  // output wire [6 : 0] data_count
);

generate;
    if( ENABLE_DEBUG == 1 ) begin

        (* keep = "true" *) wire [ 15 : 0 ] axi_data_left          = axi_sample_data[15:0];
        (* keep = "true" *) wire [ 15 : 0 ] axi_data_right         = axi_sample_data[31:16];
        (* keep = "true" *) wire [ 15 : 0 ] mix_fifo_in_data_left  = mix_data_left;
        (* keep = "true" *) wire [ 15 : 0 ] mix_fifo_in_data_right = mix_data_right;
        (* keep = "true" *) wire [ 15 : 0 ] fifo_out_data_left     = sample_data[15:0];
        (* keep = "true" *) wire [ 15 : 0 ] fifo_out_data_right    = sample_data[31:16];

        sample_dma_receiver_ILA sample_dma_receiver_ILA (
            .clk(clk), // input wire clk

            .probe0  ( stop                      ),
            .probe1  ( all_samples_received      ),
            .probe2  ( last_request_sent         ),
            .probe3  ( last_request_id           ),
            .probe4  ( axi_data_left             ),
            .probe5  ( axi_data_right            ),
            .probe6  ( axi_sample_id             ),
            .probe7  ( axi_sample_valid          ),
            .probe8  ( axi_sample_data_last      ),
            .probe9  ( axi_sample_receiver_ready ),
            .probe10 ( mix_fifo_in_data_left     ),
            .probe11 ( mix_fifo_in_data_right    ),
            .probe12 ( sample_data_available     ),
            .probe13 ( sample_data_read          ),
            .probe14 ( last_request_sent_reg     ),
            .probe15 ( fsm_curr_st               ),
            .probe16 ( last_received_id_reg      ),
            .probe17 ( axi_sample_data_last_reg  ),
            .probe18 ( mix_fifo_data_rd          ),
            .probe19 ( fifo_data_count           ),
            .probe20 ( fifo_out_data_left        ),
            .probe21 ( fifo_out_data_right       ),
            .probe22 ( mix_fifo_empty            ),
            .probe23 ( all_samples_invalid       ),
            .probe24 ( mix_fifo_data_wr          )

        );
    end
endgenerate


endmodule