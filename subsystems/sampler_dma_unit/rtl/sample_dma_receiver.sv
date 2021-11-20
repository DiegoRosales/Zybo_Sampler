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

`default_nettype none

module sample_dma_receiver #(
    parameter         ENABLE_DEBUG             = 1,
    parameter integer C_AXI_STREAM_TDATA_WIDTH = 32,
    parameter integer C_AXI_STREAM_TUSER_WIDTH = 32
)(
    input wire clk,
    input wire reset_n,

    input wire stop,

    // DMA Requester interface //
    output wire           all_samples_received,
    input  wire           last_request_sent,
    input  wire [ 5 : 0 ] last_request_id,
    input  wire           all_samples_invalid,

    // Input AXI Stream interface from the AXI Bridge
    input  wire [C_AXI_STREAM_TDATA_WIDTH-1 : 0] axi_stream_slave_tdata,
    input  wire                                  axi_stream_slave_tvalid,
    input  wire                                  axi_stream_slave_tlast,
    input  wire [C_AXI_STREAM_TUSER_WIDTH-1 : 0] axi_stream_slave_tuser,
    output wire                                  axi_stream_slave_tready,

    // Output AXI Stream interface
    output wire [C_AXI_STREAM_TDATA_WIDTH-1 : 0] axi_stream_master_tdata,
    output wire                                  axi_stream_master_tvalid,
    output wire                                  axi_stream_master_tlast,
    output wire [C_AXI_STREAM_TUSER_WIDTH-1 : 0] axi_stream_master_tuser,
    input  wire                                  axi_stream_master_tready

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

// Sample Metadata
wire [ C_AXI_STREAM_TUSER_WIDTH-1 : 0 ] axi_stream_slave_tready_int;
wire [ C_AXI_STREAM_TUSER_WIDTH-1 : 0 ] axi_stream_slave_tuser_int;
wire [ C_AXI_STREAM_TUSER_WIDTH-1 : 0]  axi_stream_master_tuser_int;
wire [ 5 : 0 ]                          axi_sample_id;
wire                                    axis_slave_last_sample_data;
wire                                    axis_master_last_sample_data;

// FIFO Signals
wire           fifo_reset_n;

// Last sample ID
reg [ 5 : 0 ] last_request_id_reg;
reg [ 5 : 0 ] last_received_id_reg;
reg           last_request_sent_reg;
wire          sample_id_is_last;
reg           axis_slave_last_sample_data_reg;

/////////////////////////////////////
// Assignments
/////////////////////////////////////
// Sample ID
assign axi_sample_id = axi_stream_slave_tuser[5:0];

// Last sample data
assign axis_slave_last_sample_data  = axi_stream_slave_tvalid && axi_stream_slave_tlast;
assign axis_master_last_sample_data = axi_stream_master_tvalid && axi_stream_master_tlast;

// The receiver is ready when the SM is ready to receive new data
assign axi_stream_slave_tready = axi_stream_slave_tready_int && ~fsm_curr_st_FSM_ST_IDLE && ~fsm_curr_st_FSM_ST_WAIT_FOR_FIFO_EMPTY;
assign all_samples_received    = fsm_curr_st_FSM_ST_START;

// Check if the current sample ID matches the last sample ID and the transaction is valid
assign sample_id_is_last = ( last_request_id_reg == last_received_id_reg ) ? (axi_stream_slave_tvalid && axi_stream_slave_tready_int) : 1'b0;

// Modified TUSER
assign axi_stream_slave_tuser_int[5:0]                          = axi_stream_slave_tuser[5:0];
assign axi_stream_slave_tuser_int[6]                            = sample_id_is_last;
assign axi_stream_slave_tuser_int[C_AXI_STREAM_TUSER_WIDTH-1:7] = axi_stream_slave_tuser[C_AXI_STREAM_TUSER_WIDTH-1:7];
// Modified TUSER Output
assign axi_stream_master_tuser = fsm_curr_st_FSM_ST_IDLE ? '1 : axi_stream_master_tuser_int;

// FIFO Reset
assign fifo_reset_n = reset_n & ~stop;

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
            else if ( axis_slave_last_sample_data ) begin
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
            else if ( (axis_slave_last_sample_data | axis_slave_last_sample_data_reg)  && last_request_sent_reg && sample_id_is_last ) begin
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
            else if ( axis_master_last_sample_data ) begin
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
always_ff @(posedge clk, negedge reset_n) begin
    if ( ~reset_n ) begin
        axis_slave_last_sample_data_reg <= 1'b0;
    end
    else begin
        axis_slave_last_sample_data_reg <= axis_slave_last_sample_data_reg;

        if ( axis_slave_last_sample_data ) begin
            axis_slave_last_sample_data_reg <= 1'b1;
        end
        else if ( axi_stream_slave_tvalid ) begin
            axis_slave_last_sample_data_reg <= 1'b0;
        end
    end
    
end


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
        if ( fsm_curr_st_FSM_ST_IDLE ) begin
            last_request_id_reg   <= 'h0;
            last_request_sent_reg <= 1'b0;
            last_received_id_reg  <= 'h0;
        end
        else if ( last_request_sent ) begin
            last_request_id_reg   <= last_request_id;
            last_request_sent_reg <= 1'b1;
        end
        else if ( fsm_curr_st_FSM_ST_WAIT_FOR_FIFO_EMPTY ) begin
            last_request_sent_reg <= 1'b0;
        end

        if ( axi_stream_slave_tvalid ) begin
            last_received_id_reg <= axi_sample_id;
        end
    end
end

//////////////////
// Output FIFO
//////////////////

axis_fifo_32x64_u8_pm receiver_fifo (
    // Clock and Reset
    .s_axis_aresetn ( fifo_reset_n ),  // input wire s_axis_aresetn
    .s_axis_aclk    ( clk          ),  // input wire s_axis_aclk

    // Input (Slave)
    .s_axis_tdata  ( axi_stream_slave_tdata      ),   // input wire [31 : 0] s_axis_tdata
    .s_axis_tvalid ( axi_stream_slave_tvalid     ),   // input wire s_axis_tvalid
    .s_axis_tlast  ( axi_stream_slave_tlast      ),   // input wire s_axis_tlast
    .s_axis_tuser  ( axi_stream_slave_tuser_int  ),   // input wire s_axis_user
    .s_axis_tready ( axi_stream_slave_tready_int ),   // output wire s_axis_tready

    // Output (Master)
    .m_axis_tdata  ( axi_stream_master_tdata      ),    // output wire [31 : 0] m_axis_tdata
    .m_axis_tvalid ( axi_stream_master_tvalid     ),    // output wire m_axis_tvalid
    .m_axis_tlast  ( axi_stream_master_tlast      ),    // output wire m_axis_tlast
    .m_axis_tuser  ( axi_stream_master_tuser_int  ),    // output wire m_axis_tuser
    .m_axis_tready ( axi_stream_master_tready     )     // input wire m_axis_tready
);

generate;
    if( ENABLE_DEBUG == 1 ) begin

        (* keep = "true" *) wire [ 15 : 0 ] axi_in_data_left       = axi_stream_slave_tdata[15:0];
        (* keep = "true" *) wire [ 15 : 0 ] axi_in_data_right      = axi_stream_slave_tdata[31:16];
        (* keep = "true" *) wire [ 15 : 0 ] axi_out_data_left      = axi_stream_master_tdata[15:0];
        (* keep = "true" *) wire [ 15 : 0 ] axi_out_data_right     = axi_stream_master_tdata[31:16];

        sample_dma_receiver_ILA sample_dma_receiver_ILA (
            .clk     ( clk                       ), // input wire clk
            // AXI in
            .probe0  ( axi_in_data_left              ),
            .probe1  ( axi_in_data_right             ),
            .probe2  ( axi_stream_slave_tvalid       ),
            .probe3  ( axi_stream_slave_tlast        ),
            .probe4  ( axi_stream_slave_tuser_int    ),
            .probe5  ( axi_stream_slave_tready_int   ),
            // AXI out
            .probe6   ( axi_out_data_left            ),
            .probe7   ( axi_out_data_right           ),
            .probe8   ( axi_stream_master_tvalid     ),
            .probe9   ( axi_stream_master_tlast      ),
            .probe10  ( axi_stream_master_tuser      ),
            .probe11  ( axi_stream_master_tready     ),
            // SM
            .probe12  ( fsm_curr_st                  ),
            .probe13  ( last_request_sent_reg        ),
            .probe14  ( last_request_id_reg          ),
            .probe15  ( last_received_id_reg         )
        );
    end
endgenerate


endmodule

`default_nettype wire