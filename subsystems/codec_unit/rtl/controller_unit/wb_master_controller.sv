/////////////////////////////////////////////////////
// This module performs RD/WR Operations through   //
// the WB interface                                //
//                                                 //
//                                                 //
//                                                 //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////
// Rev. 0.1 - Init                                 //
/////////////////////////////////////////////////////

module wb_master_controller (
  input wire clk,
  input wire reset_n,

  // WB Interface
  output wire [2:0] wbs_adr_o,   // ADR_I() address
  output wire [7:0] wbs_dat_o,   // DAT_I() data out
  input  wire [7:0] wbs_dat_i,   // DAT_O() data in
  output wire       wbs_we_o,    // WE_I write enable output
  output wire       wbs_stb_o,   // STB_I strobe output
  input  wire       wbs_ack_i,   // ACK_O acknowledge input
  output wire       wbs_cyc_o,    // CYC_I cycle output

  // Control Signals
  input wire read,
  input wire write,

  // Data Signals
  input wire  [7:0] data_in,
  input wire  [3:0] address,
  output wire [7:0] data_out,

  // Status Signals
  output wire data_out_valid,
  output wire done
);

///////////////////////////////////////////
///////// Wishbone State Machine //////////
localparam WB_IDLE            = 0;
localparam WB_WAIT_FOR_WR_ACK = 1;
localparam WB_WAIT_FOR_RD_ACK = 2;
localparam WB_DATA_WR         = 3;

// Registers
reg       wb_read;
reg       wb_write;
reg [7:0] wb_data;
reg [7:0] wb_data_in;
reg [3:0] wb_addr;
reg       wb_done;
reg       wb_data_in_valid;

reg  [2:0] wbs_adr_o_reg;   // ADR_O() address
reg  [7:0] wbs_dat_o_reg;   // DAT_O() data out
reg        wbs_we_o_reg;    // WE_O write enable output
reg        wbs_stb_o_reg;   // STB_O strobe output
reg        wbs_cyc_o_reg;   // CYC_O cycle output

wire [2:0] wb_state_curr;
reg  [2:0] wb_state_next;

// Assignments
assign wb_state_curr = wb_state_next;

assign wbs_adr_o = wbs_adr_o_reg;   // ADR_I() address
assign wbs_dat_o = wbs_dat_o_reg;   // DAT_I() data out
assign wbs_we_o  = wbs_we_o_reg;    // WE_I write enable output
assign wbs_stb_o = wbs_stb_o_reg;   // STB_I strobe output
assign wbs_cyc_o = wbs_cyc_o_reg;   // CYC_I cycle output

assign done           = wb_done;
assign data_out_valid = wb_data_in_valid;
assign data_out       = wb_data_in;

//////////////////////////////////////////////////////
////////////////// WB State Machines /////////////////
//// These state machines control the WB Interface ///
//// And translate WR/RD instructions to WB //////////
always @ ( posedge clk or negedge reset_n ) begin
  if (reset_n == 1'b0) begin
    // Output to the SM
    wb_state_next    <= WB_IDLE;
    wb_done          <= 1'b0;
    wb_data_in       <= 8'h00;
    wb_data_in_valid <= 1'b0;
    // WB Signals
    wbs_we_o_reg     <= 1'b0;
    wbs_stb_o_reg    <= 1'b0;
    wbs_cyc_o_reg    <= 1'b0;
    wbs_adr_o_reg    <= 0;
    wbs_dat_o_reg    <= 0;
  end
  else begin
    // Output to the SM
    wb_done          <= 1'b0;
    wb_state_next    <= wb_state_curr;
    wb_data_in_valid <= 1'b0;
    wb_data_in       <= wb_data_in;

    // WB Signals
    wbs_we_o_reg     <= 1'b0;
    wbs_stb_o_reg    <= wbs_stb_o_reg;
    wbs_cyc_o_reg    <= wbs_cyc_o_reg;
    wbs_dat_o_reg    <= wbs_dat_o_reg;
    wbs_dat_o_reg    <= wbs_dat_o_reg;
    case (wb_state_curr)
      WB_IDLE: begin // Does Nothing. Waits for wb_read or wb_write
        wbs_stb_o_reg <= 1'b0;
        wbs_cyc_o_reg <= 1'b0;
        // Writes data to a WB register
        if (write) begin 
          wb_state_next <= WB_DATA_WR;

          wbs_adr_o_reg <= address;
          wbs_dat_o_reg <= data_in;
          
          wbs_cyc_o_reg <= 1'b1;
        end
        // Reads data to a WB register
        if (read) begin 
          wb_state_next <= WB_WAIT_FOR_RD_ACK;

          wbs_adr_o_reg <= address;
          wbs_stb_o_reg <= 1'b1;
          wbs_cyc_o_reg <= 1'b1;
        end        
      end

      WB_DATA_WR: begin // Sets WB Data. Waits for ACK
        wb_state_next <= WB_WAIT_FOR_WR_ACK;
        wbs_stb_o_reg <= 1'b1;
        wbs_we_o_reg  <= 1'b1;
      end

      WB_WAIT_FOR_RD_ACK: begin // Waits for a RD Ack
        if (wbs_ack_i) begin
          wb_data_in       <= wbs_dat_i;
          wb_data_in_valid <= 1'b1;

          wbs_stb_o_reg    <='h0;
          wbs_cyc_o_reg    <='h0;

          wb_state_next    <= WB_IDLE;
          wb_done          <= 1'b1;
        end
      end

      WB_WAIT_FOR_WR_ACK: begin        
      	if (wbs_ack_i) begin
      		wb_done       <= 1'b1;
      		wb_state_next <= WB_IDLE;

          wbs_stb_o_reg <='h0;
          wbs_cyc_o_reg <='h0;
      	end // if (wbs_ack_i)
      end // WB_WAIT_FOR_ACK:
    endcase // case(wb_state_curr)
  end //if (reset_n == 1'b0) begin
end

/////////////////////////////////////////////////
////////////// END WB State Machines ////////////
/////////////////////////////////////////////////

endmodule