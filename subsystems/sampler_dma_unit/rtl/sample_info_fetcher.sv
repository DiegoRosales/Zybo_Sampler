

// +------------------------------------------------------------------------+
// | sample_info_fetcher.sv                                                 |
// +------------------------------------------------------------------------+
// | This module will fetch all the information regarding a given sample    |
// |                                                                        |
// | This module will expose all the decoded information to the DMA engine  |
// | to process the next request The DMA engine will indicate to go to the  |
// | next sample based on the previous sample information This module will  |
// | cycle through all samples until it reaches the last one of the loop,   |
// | indicated by the sample information fetched.                           |
// | At that moment it will indicate the DMA engine that the loop is done   |
// +------------------------------------------------------------------------+

////////////////////
// Memory Structure
////////////////////

// .---------------------------------------------------------.---------.
// |       0      |      1      |      2      |      3       |  Addr A |
// :---------------------------------------------------------+---------:
// |                Sample Current Address [31:0]            |    0    |
// :---------------------------------------------------------+---------:
// |                  Sample End Address [31:0]              |    1    |
// :---------------------------------------------------------+---------:
// | Control[7:0] |   Sample Length [23:0]                   |    2    |
// :---------------------------------------------------------+---------:
// |         RSVD[15:0]         |     Next Sample[15:0]      |    3    |
// '---------------------------------------------------------'---------'

module sample_info_fetcher #(
    parameter NUMBER_OF_SAMPLE_REG_PER_READ = 4,   // This controls the number of registers to be fetched on a single read
    parameter BRAM_DATA_WIDTH               = 128, // This controls the data width of the BRAM data
    parameter BRAM_ADDR_WIDTH               = 6,
    // Debug
    parameter ENABLE_DEBUG                  = 1

    )
    (
    input wire clk,
    input wire reset_n,

    // Control interface //
    input wire start, // Start the fetch mechanism
    input wire stop,  // Stop the fetch mechanism

    // BRAM Interface //
    output wire [ BRAM_ADDR_WIDTH - 1 : 0 ] bram_addr,
    input  wire [ BRAM_DATA_WIDTH - 1 : 0 ] bram_data_in,
    output wire [ BRAM_DATA_WIDTH - 1 : 0 ] bram_data_out,
    output wire                             bram_data_wr,

    // DMA Requester Interface //
    output wire [ 31 : 0 ] sample_addr,
    output wire [ 5 : 0 ]  sample_id,
    output wire            sample_valid,
    output wire            sample_overflow,
    output wire            sample_last,
    input  wire            load_next_sample,
    input  wire            all_samples_invalid
);

// States
localparam FSM_ST_IDLE           = 0;
localparam FSM_ST_READ           = 1;
localparam FSM_ST_WAIT_FOR_DATA  = 2;
localparam FSM_ST_WAIT           = 3;
localparam FSM_ST_WRITEBACK      = 4;
localparam FSM_ST_SAMPLE_DATA    = 5;
localparam FSM_ST_SAMPLE_WB_DATA = 6;

// This holds the fetched information
reg  [ NUMBER_OF_SAMPLE_REG_PER_READ - 1 : 0 ] [ 31 : 0 ] sample_registers;
wire [ NUMBER_OF_SAMPLE_REG_PER_READ - 1 : 0 ] [ 31 : 0 ] sample_registers_pre;
wire [ NUMBER_OF_SAMPLE_REG_PER_READ - 1 : 0 ] [ 31 : 0 ] sample_registers_wb;
reg  [ NUMBER_OF_SAMPLE_REG_PER_READ - 1 : 0 ] [ 31 : 0 ] sample_registers_wb_reg;

// State Machine
reg   [ 2 : 0 ] fsm_curr_st;
logic [ 2 : 0 ] fsm_next_st;

// States
wire fsm_curr_st_FSM_ST_IDLE;
wire fsm_curr_st_FSM_ST_READ;
wire fsm_curr_st_FSM_ST_WAIT_FOR_DATA;
wire fsm_curr_st_FSM_ST_WAIT;
wire fsm_curr_st_FSM_ST_WRITEBACK;
wire fsm_curr_st_FSM_ST_SAMPLE_DATA;
wire fsm_curr_st_FSM_ST_SAMPLE_WB_DATA;

// Read wait counter (2 clock cycles)
reg [ 1 : 0 ] read_dly_count;
wire          read_dly_count_done;

// BRAM Address
reg  [ BRAM_ADDR_WIDTH - 1 : 0 ] current_bram_addr;
wire [ BRAM_ADDR_WIDTH - 1 : 0 ] next_bram_addr;

// DMA Address
wire [ 31 : 0 ] next_sample_addr;
wire [ 31 : 0 ] sample_end_addr;
wire            sample_addr_overflow;

// Sample Length
wire [ 23 : 0 ] sample_len;

// Control and status register
wire [ 7 : 0 ] control_and_status;
wire [ 7 : 0 ] next_control_and_status;
wire           curr_sample_valid;
wire           curr_sample_overflow;
wire           curr_sample_last;

//////////////////////////////////

assign fsm_curr_st_FSM_ST_IDLE           = ( fsm_curr_st == FSM_ST_IDLE );
assign fsm_curr_st_FSM_ST_READ           = ( fsm_curr_st == FSM_ST_READ );
assign fsm_curr_st_FSM_ST_WAIT_FOR_DATA  = ( fsm_curr_st == FSM_ST_WAIT_FOR_DATA );
assign fsm_curr_st_FSM_ST_WAIT           = ( fsm_curr_st == FSM_ST_WAIT );
assign fsm_curr_st_FSM_ST_WRITEBACK      = ( fsm_curr_st == FSM_ST_WRITEBACK );
assign fsm_curr_st_FSM_ST_SAMPLE_DATA    = ( fsm_curr_st == FSM_ST_SAMPLE_DATA );
assign fsm_curr_st_FSM_ST_SAMPLE_WB_DATA = ( fsm_curr_st == FSM_ST_SAMPLE_WB_DATA );


///////////////////////////////////////
// Read/Write State Machine
///////////////////////////////////////

assign bram_data_out = sample_registers_wb_reg;
assign bram_data_wr  = fsm_curr_st_FSM_ST_WRITEBACK;

// Current state FF
always_ff @(posedge clk, negedge reset_n) begin
    if (~reset_n) begin
        fsm_curr_st <= FSM_ST_IDLE;
    end
    else begin
        fsm_curr_st <= fsm_next_st;
    end
end

// Next State combinational logic
always_comb begin
    case (fsm_curr_st)
        FSM_ST_IDLE: begin
            if ( start && ~stop ) fsm_next_st = FSM_ST_READ;
            else                  fsm_next_st = FSM_ST_IDLE;
        end

        FSM_ST_READ: begin
            fsm_next_st = FSM_ST_WAIT_FOR_DATA;
        end

        FSM_ST_WAIT_FOR_DATA: begin
            if ( read_dly_count_done ) fsm_next_st = FSM_ST_SAMPLE_DATA;
            else                       fsm_next_st = FSM_ST_WAIT_FOR_DATA;
        end

        FSM_ST_SAMPLE_DATA: begin
            fsm_next_st = FSM_ST_SAMPLE_WB_DATA;
        end

        FSM_ST_SAMPLE_WB_DATA: begin
            if ( ~curr_sample_valid | curr_sample_overflow ) fsm_next_st = FSM_ST_WAIT;      // Skip Writeback if the sample was invalid
            else                                             fsm_next_st = FSM_ST_WRITEBACK; // Go to writeback
        end

        // Write back the new address and the status
        FSM_ST_WRITEBACK: begin
            fsm_next_st = FSM_ST_WAIT;
        end

        // Wait for the request to get the next sample information
        FSM_ST_WAIT: begin
            if ( stop | all_samples_invalid ) begin
                fsm_next_st = FSM_ST_IDLE;
            end
            else begin
                if ( load_next_sample | ~curr_sample_valid) begin
                    fsm_next_st = FSM_ST_READ;
                end
                else begin
                    fsm_next_st = FSM_ST_WAIT;
                end
            end
            
        end


        default: begin
            fsm_next_st = FSM_ST_IDLE;
        end
    endcase
end


///////////////////////////////////////
// Read Delay Counter
///////////////////////////////////////

assign read_dly_count_done = &read_dly_count; // Count to at least 2'b10

always_ff @(posedge clk, negedge reset_n) begin
    if (~reset_n) begin
        read_dly_count <= 2'b00;
    end
    else begin
        read_dly_count <= 2'b00;

        if ( fsm_curr_st_FSM_ST_WAIT_FOR_DATA ) begin
            read_dly_count <= read_dly_count + 1'b1;
        end
    end
end

///////////////////////////////////////
// Next BRAM Address FF
///////////////////////////////////////

assign bram_addr = current_bram_addr;

always_ff @(posedge clk, negedge reset_n) begin
    if (~reset_n) begin
        current_bram_addr  <= 'h0;
    end
    else begin

        current_bram_addr  <= current_bram_addr;

        // The default address is 0
        if ( stop ) begin
            current_bram_addr  <= 'h0;
        end
        else if ( fsm_curr_st_FSM_ST_WAIT && load_next_sample ) begin
            current_bram_addr <= next_bram_addr; // Load the next address
        end
    end
end

///////////////////////////////////////
// Sample Data Decoding
///////////////////////////////////////

assign sample_addr        = sample_registers[0];
assign sample_end_addr    = sample_registers[1];
assign sample_len         = sample_registers[2][23:0];
assign control_and_status = sample_registers[2][31:24];
assign sample_id          = current_bram_addr;
assign next_bram_addr     = sample_registers_pre[3][BRAM_ADDR_WIDTH - 1 : 0]; // Take the next BRAM address directly in case the FW changed it while waiting

// Get the current control and status bits
assign curr_sample_valid       = control_and_status[0];
assign curr_sample_last        = control_and_status[1]; // Last slot
assign curr_sample_overflow    = control_and_status[7];


assign sample_valid    = fsm_curr_st_FSM_ST_WAIT & curr_sample_valid;
assign sample_last     = fsm_curr_st_FSM_ST_WAIT & curr_sample_valid & curr_sample_last;
assign sample_overflow = sample_addr_overflow | curr_sample_overflow;

// Calculate the next sample address
// 1 DMA access = 64x32bit transfer = 256 bytes
assign next_sample_addr = sample_addr + 32'h100;

// Check if the next address is still within range
assign sample_addr_overflow = ( next_sample_addr > sample_end_addr );

// Control and status register for writeback
assign next_control_and_status[6:0] = control_and_status[6:0];
assign next_control_and_status[7]   = sample_addr_overflow;

///////////////////////////////////////
// Sample Data FF
///////////////////////////////////////

assign sample_registers_pre = bram_data_in;

always_ff @(posedge clk, negedge reset_n) begin
    if (~reset_n) begin
        sample_registers <= 'h0;
    end
    else begin

        sample_registers <= sample_registers;

        // Sample the data whenever there's new data ready
        if ( fsm_curr_st_FSM_ST_SAMPLE_DATA ) begin
            sample_registers <= sample_registers_pre;
        end
    end
end

///////////////////////////////////////
// Sample Data Writeback FF
///////////////////////////////////////

assign sample_registers_wb[0]        = curr_sample_overflow ? sample_addr : next_sample_addr;
assign sample_registers_wb[1]        = sample_registers[1];
assign sample_registers_wb[2][23:0]  = sample_len;
assign sample_registers_wb[2][31:24] = next_control_and_status;
assign sample_registers_wb[3]        = sample_registers[3];

always_ff @(posedge clk, negedge reset_n) begin
    if (~reset_n) begin
        sample_registers_wb_reg <= 'h0;
    end
    else begin

        sample_registers_wb_reg <= sample_registers_wb_reg;

        // Sample the data whenever there's new data ready
        if ( fsm_curr_st_FSM_ST_SAMPLE_WB_DATA ) begin
            sample_registers_wb_reg[0] <= sample_registers_wb[0];
            sample_registers_wb_reg[1] <= sample_registers_wb[1];
            sample_registers_wb_reg[2] <= sample_registers_wb[2];
            sample_registers_wb_reg[3] <= sample_registers_wb[3];
        end
    end
end

//////////////////////////////////////////////////////
// Debug Probe
//////////////////////////////////////////////////////

generate;
    if( ENABLE_DEBUG == 1 ) begin
        sampler_info_fetcher_ILA sampler_info_fetcher_ILA (
            .clk(clk), // input wire clk

            .probe0  ( start               ), // input wire [0:0]  probe0  
            .probe1  ( stop                ), // input wire [0:0]  probe1 
            .probe2  ( bram_addr           ), // input wire [5:0]  probe2 
            .probe3  ( sample_addr         ), // input wire [31:0]  probe3 
            .probe4  ( sample_id           ), // input wire [5:0]  probe4 
            .probe5  ( sample_valid        ), // input wire [0:0]  probe5 
            .probe6  ( sample_last         ), // input wire [0:0]  probe6 
            .probe7  ( load_next_sample    ), // input wire [0:0]  probe7 
            .probe8  ( fsm_curr_st         ), // input wire [2:0]  probe8 
            .probe9  ( sample_registers[0] ), // input wire [31:0]  probe9
            .probe10 ( sample_registers[1] ), // input wire [31:0]  probe10
            .probe11 ( sample_registers[2] ), // input wire [31:0]  probe11
            .probe12 ( sample_registers[3] ), // input wire [31:0]  probe12
            .probe13 ( sample_overflow     )  // input wire [0:0]  probe12
        );
    end
endgenerate



endmodule