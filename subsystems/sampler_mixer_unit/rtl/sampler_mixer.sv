//////////////////////////////////////////////////////
// sample_mixer.sv
///////////////////
// This module receives a stream of samples through an AXI-Stream interface
// Each stream is 64 samples long and the streams are groupped in blocks
// The mixer will only mix the samples of one specific block
// Once the mixer receives all the samples of one block, it will make the data available for the next stage
//////////////////////////////////////////////////////

`default_nettype none

module sampler_mixer #(
    parameter         ENABLE_SAMPLER_MIXER_DEBUG = 0,
    parameter integer C_AXI_STREAM_TDATA_WIDTH   = 32,
    parameter integer C_AXI_STREAM_TUSER_WIDTH   = 32
) (
    // Clock and reset
    input  wire clk,
    input  wire reset_n,

    // Output AXI Stream interface
    output wire [C_AXI_STREAM_TDATA_WIDTH-1 : 0]     axi_stream_master_tdata,
    output wire                                      axi_stream_master_tvalid,
    output wire                                      axi_stream_master_tlast,
    output wire [C_AXI_STREAM_TUSER_WIDTH-1 : 0]     axi_stream_master_tuser,
    input  wire                                      axi_stream_master_tready,

    // Input AXI Stream interface
    input  wire [C_AXI_STREAM_TDATA_WIDTH-1 : 0]     axi_stream_slave_tdata,
    input  wire                                      axi_stream_slave_tvalid,
    input  wire                                      axi_stream_slave_tlast,
    input  wire [C_AXI_STREAM_TUSER_WIDTH-1 : 0]     axi_stream_slave_tuser,
    output wire                                      axi_stream_slave_tready
);

// States
localparam [1:0] FSM_ST_RECEIVE_SAMPLES_0   = 0;
localparam [1:0] FSM_ST_RECEIVE_SAMPLES_1   = 1;
localparam [1:0] FSM_ST_WAIT_FOR_FIFO_EMPTY = 2;

wire fsm_curr_st_FSM_ST_RECEIVE_SAMPLES_0;
wire fsm_curr_st_FSM_ST_RECEIVE_SAMPLES_1;
wire fsm_curr_st_FSM_ST_WAIT_FOR_FIFO_EMPTY;


// State Machine
logic [ 1 : 0 ] fsm_curr_st;
logic [ 1 : 0 ] fsm_next_st;

// Metadata from AXIS
wire last_stream;
wire stream_stop;
wire end_of_slave_stream;
wire end_of_master_stream;

// Internal AXIS
wire [C_AXI_STREAM_TDATA_WIDTH-1 : 0]     axi_stream_master_tdata_int;
wire                                      axi_stream_master_tvalid_int;
wire                                      axi_stream_master_tlast_int;
wire [C_AXI_STREAM_TUSER_WIDTH-1 : 0]     axi_stream_master_tuser_int;
wire [C_AXI_STREAM_TUSER_WIDTH-1 : 0]     axi_stream_slave_tuser_int;
wire                                      axi_stream_slave_tready_int;

// Mix FIFO signals
wire            fifo_reset_n;
wire [ 15 : 0 ] mix_data_left;
wire [ 15 : 0 ] mix_data_right;
wire [ 31 : 0 ] mix_fifo_data_in;
wire            mix_fifo_data_rd;
wire            mix_fifo_data_wr;

/////////////////////////////////////////
// Assignments
/////////////////////////////////////////
//// State Machine Assignments ////
// Current State
assign fsm_curr_st_FSM_ST_RECEIVE_SAMPLES_0   = ( fsm_curr_st == FSM_ST_RECEIVE_SAMPLES_0   );
assign fsm_curr_st_FSM_ST_RECEIVE_SAMPLES_1   = ( fsm_curr_st == FSM_ST_RECEIVE_SAMPLES_1   );
assign fsm_curr_st_FSM_ST_WAIT_FOR_FIFO_EMPTY = ( fsm_curr_st == FSM_ST_WAIT_FOR_FIFO_EMPTY );

//// Output AXIS Assignments ////
// AXIs
assign axi_stream_master_tvalid    = fsm_curr_st_FSM_ST_WAIT_FOR_FIFO_EMPTY ? axi_stream_master_tvalid_int : '0; // Assert the output only when all samples have been mixed
assign axi_stream_master_tdata     = fsm_curr_st_FSM_ST_WAIT_FOR_FIFO_EMPTY ? axi_stream_master_tdata_int  : '0;  // Assert the output only when all samples have been mixed
assign axi_stream_master_tlast     = fsm_curr_st_FSM_ST_WAIT_FOR_FIFO_EMPTY ? axi_stream_master_tlast_int  : '0;  // Assert the output only when all samples have been mixed
assign axi_stream_master_tuser     = fsm_curr_st_FSM_ST_WAIT_FOR_FIFO_EMPTY ? axi_stream_master_tuser_int  : '0;  // Assert the output only when all samples have been mixed
assign axi_stream_slave_tready     = (fsm_curr_st_FSM_ST_RECEIVE_SAMPLES_0 | fsm_curr_st_FSM_ST_RECEIVE_SAMPLES_1) && axi_stream_slave_tready_int; // Assert only when accepting new samples

//// Internal Misc Assignments ////
// Last sample data
assign end_of_slave_stream  = axi_stream_slave_tvalid    && axi_stream_slave_tlast;
assign end_of_master_stream = axi_stream_master_tvalid   && axi_stream_master_tlast && mix_fifo_data_rd;

// Sample Metadata
assign last_stream = axi_stream_slave_tuser[6];

// Stream stop
assign stream_stop  = axi_stream_slave_tuser == '1; // All bits to 1
assign fifo_reset_n = stream_stop ? 1'b0 : reset_n;

//// Mixer FIFO Assignments ////
// User Data
assign axi_stream_master_tuser_int = stream_stop ? '1 : '0; // No use at the moment

// Sample Data Mixer
assign mix_fifo_data_in = { mix_data_right, mix_data_left };

// Mix the new data with the previous data
assign mix_data_left  = ( fsm_curr_st_FSM_ST_RECEIVE_SAMPLES_1 == 1'b1 ) ? (axi_stream_slave_tdata[ 15 : 0 ]  + axi_stream_master_tdata_int[ 15 : 0 ]) : 
                                                                            axi_stream_slave_tdata[ 15 : 0 ];
assign mix_data_right = ( fsm_curr_st_FSM_ST_RECEIVE_SAMPLES_1 == 1'b1 ) ? (axi_stream_slave_tdata[ 31 : 16 ] + axi_stream_master_tdata_int[ 31 : 16 ]) : 
                                                                            axi_stream_slave_tdata[ 31 : 16 ];

// Read/Write signals
assign mix_fifo_data_wr = axi_stream_slave_tvalid && axi_stream_slave_tready;
assign mix_fifo_data_rd = fsm_curr_st_FSM_ST_WAIT_FOR_FIFO_EMPTY ? axi_stream_master_tready :
                                                                   (fsm_curr_st_FSM_ST_RECEIVE_SAMPLES_1 && axi_stream_master_tvalid_int && mix_fifo_data_wr);

/////////////////////////////////////////
// State Machine
/////////////////////////////////////////

// Current state FF
always_ff @(posedge clk, negedge reset_n) begin
    if (~reset_n) begin
        fsm_curr_st <= FSM_ST_RECEIVE_SAMPLES_0;
    end
    else begin
        fsm_curr_st <= fsm_next_st;
    end
end

// Next State
always_comb begin
    fsm_next_st <= fsm_curr_st;
    case(fsm_curr_st)
        // Receive the first sample
        FSM_ST_RECEIVE_SAMPLES_0: begin
            if ( end_of_slave_stream ) begin
                if( last_stream ) begin
                    fsm_next_st <= FSM_ST_WAIT_FOR_FIFO_EMPTY;
                end
                else begin
                    fsm_next_st <= FSM_ST_RECEIVE_SAMPLES_1;
                end
            end
        end

        // Receive the next samples
        FSM_ST_RECEIVE_SAMPLES_1: begin
            if ( stream_stop ) begin
                fsm_next_st <= FSM_ST_RECEIVE_SAMPLES_0;
            end
            else if( last_stream && end_of_slave_stream ) begin
                fsm_next_st <= FSM_ST_WAIT_FOR_FIFO_EMPTY;
            end
        end

        // All samples received. Waiting for FIFO to be empty
        FSM_ST_WAIT_FOR_FIFO_EMPTY: begin
            if ( stream_stop ) begin
                fsm_next_st <= FSM_ST_RECEIVE_SAMPLES_0;
            end
            else if ( end_of_master_stream ) begin
                fsm_next_st <= FSM_ST_RECEIVE_SAMPLES_0;
            end
        end
        default: fsm_next_st <= FSM_ST_RECEIVE_SAMPLES_0;
    endcase
end


axis_fifo_32x64_u8_npm mix_fifo (
    // Clock and Reset
    .s_axis_aclk    ( clk          ),  // input wire s_axis_aclk
    .s_axis_aresetn ( fifo_reset_n ),  // input wire s_axis_aresetn

    // Input (Slave)
    .s_axis_tdata  ( mix_fifo_data_in             ),   // input wire [31 : 0] s_axis_tdata
    .s_axis_tvalid ( mix_fifo_data_wr             ),   // input wire s_axis_tvalid
    .s_axis_tlast  ( axi_stream_slave_tlast       ),   // input wire s_axis_tlast
    .s_axis_tuser  ( axi_stream_slave_tuser       ),   // input wire s_axis_user
    .s_axis_tready ( axi_stream_slave_tready_int  ),   // output wire s_axis_tready

    // Output (Master)
    .m_axis_tdata  ( axi_stream_master_tdata_int  ),    // output wire [31 : 0] m_axis_tdata
    .m_axis_tvalid ( axi_stream_master_tvalid_int ),    // output wire m_axis_tvalid
    .m_axis_tlast  ( axi_stream_master_tlast_int  ),    // output wire m_axis_tlast
    .m_axis_tuser  (                              ),    // output wire m_axis_tuser
    .m_axis_tready ( mix_fifo_data_rd             )     // input wire m_axis_tready
);

generate;
    if( ENABLE_SAMPLER_MIXER_DEBUG == 1 ) begin

        (* keep = "true" *) wire [ 15 : 0 ] axi_in_data_left       = axi_stream_slave_tdata[15:0];
        (* keep = "true" *) wire [ 15 : 0 ] axi_in_data_right      = axi_stream_slave_tdata[31:16];
        (* keep = "true" *) wire [ 15 : 0 ] axi_out_data_left      = axi_stream_master_tdata[15:0];
        (* keep = "true" *) wire [ 15 : 0 ] axi_out_data_right     = axi_stream_master_tdata[31:16];

        sampler_mixer_ILA sampler_mixer_ILA (
            .clk     ( clk                           ), // input wire clk
            // AXI in
            .probe0  ( axi_in_data_left              ),
            .probe1  ( axi_in_data_right             ),
            .probe2  ( axi_stream_slave_tvalid       ),
            .probe3  ( axi_stream_slave_tlast        ),
            .probe4  ( axi_stream_slave_tuser        ),
            .probe5  ( axi_stream_slave_tready       ),
            // AXI out
            .probe6   ( axi_out_data_left            ),
            .probe7   ( axi_out_data_right           ),
            .probe8   ( axi_stream_master_tvalid     ),
            .probe9   ( axi_stream_master_tlast      ),
            .probe10  ( axi_stream_master_tuser      ),
            .probe11  ( axi_stream_master_tready     ),
            // SM
            .probe12  ( fsm_curr_st                  ),
            .probe13  ( last_stream                  ),
            // Sum
            .probe14  ( mix_data_left               ),
            .probe15  ( mix_data_right              )
        );
    end
endgenerate

endmodule

`default_nettype wire
