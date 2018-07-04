/////////////////////////////////////////////////////
// This module acts as a bridge for high-level     //
// RD/WR Operations for internal CODEC registers.  //
// This module talks to the I2C Controller through //
// the Wishbone Interface.                         //
// This module also has signals that allow the     //
// user to read registers of the I2C Controller    //
// itself (for debug)                              //
/////////////////////////////////////////////////////
// Rev. 0.1 - Init                                 //
/////////////////////////////////////////////////////
module controller_unit_top (
  input wire clk,
  input wire reset,
  input wire fifo_empty,
  input wire i2s_busy,

  // CODEC Register RD/WR Signals
  input  wire       codec_rd_en,
  input  wire       codec_wr_en,
  input  wire [7:0] codec_reg_addr,
  input  wire [7:0] codec_data_wr,
  output wire [7:0] codec_data_rd,
  

  //I2C Controller RD/WR Signals
  input  wire       i2c_ctrl_rd,
  input  wire [2:0] i2c_ctrl_addr,
  output wire [7:0] i2c_ctrl_data,

  // Controller status bit
  output wire controller_busy,

  // WB Interface
  output wire [2:0] wbs_adr_o,   // ADR_I() address
  output wire [7:0] wbs_dat_o,   // DAT_I() data out
  input  wire [7:0] wbs_dat_i,   // DAT_O() data in
  output wire       wbs_we_o,    // WE_I write enable output
  output wire       wbs_stb_o,   // STB_I strobe output
  input  wire       wbs_ack_i,   // ACK_O acknowledge input
  output wire       wbs_cyc_o    // CYC_I cycle output

  );


localparam WB_CMD        = 4'h3;
localparam WB_ADDR       = 4'h2;
localparam WB_DATA       = 4'h4;
localparam WB_CODEC_ADDR = 7'b0011010; // I2C Address of the SSM2603 CODEC

///////////////////////////////////////////
///////// Wishbone State Machine //////////
localparam WB_IDLE    = 0;
localparam WB_ADDR_WR = 1;
localparam WB_DATA_WR = 2;
localparam WB_CMD_WR  = 3;
localparam WB_ADDR_RD = 4;
localparam WB_DATA_RD = 5;
localparam WB_CMD_RD  = 6;

/////////////////////////////////////////////////
///////// High-level I2C State Machine //////////
localparam I2C_IDLE   = 0;
localparam I2C_WRITE  = 1;
localparam I2C_READ_1 = 2;
localparam I2C_READ_2 = 3;
localparam I2C_READ_3 = 4;
localparam I2C_READ_4 = 5;
localparam I2C_READ_5 = 6;
localparam I2C_READ_6 = 7;


assign wbs_adr_o = wbs_adr_o_reg;   // ADR_I() address
assign wbs_dat_o = wbs_dat_o_reg;   // DAT_I() data out
//assign wbs_dat_i = wbs_dat_i_reg;   // DAT_O() data in
assign wbs_we_o = wbs_we_o_reg;    // WE_I write enable output
assign wbs_stb_o = wbs_stb_o_reg;   // STB_I strobe output
//assign wbs_ack_i = wbs_ack_i;   // ACK_O acknowledge input
assign wbs_cyc_o = wbs_cyc_o_reg;   // CYC_I cycle output
assign i2c_ctrl_data = i2c_ctrl_data_reg;

assign controller_busy = controller_busy_reg | !wb_done;
assign codec_data_rd = codec_data_rd_reg;

reg [2:0] wbs_adr_o_reg;   // ADR_O() address
reg [7:0] wbs_dat_o_reg;   // DAT_O() data out
wire [7:0] wbs_dat_i_reg;   // DAT_I() data in
reg wbs_we_o_reg;    // WE_O write enable output
reg wbs_stb_o_reg;   // STB_O strobe output
//wire wbs_ack_i;   // ACK_I acknowledge input
reg wbs_cyc_o_reg;   // CYC_O cycle output

reg [2:0] wb_state_curr;
reg [2:0] wb_state_next;

reg [2:0] i2c_state;

// WB State Machine Registers
reg wb_read;
reg wb_write;
reg [7:0] wb_data;
reg [3:0] wb_addr;
reg wb_done;
reg wb_wait_for_ack;
reg [7:0] i2c_ctrl_data_reg;
reg [2:0] i2c_ctrl_addr_reg;

// CODEC Register signals
reg controller_busy_reg;
reg [7:0] codec_data_rd_reg;

// I2C Registers
reg [7:0] i2c_data;
reg [7:0] i2c_addr;
reg [7:0] i2c_command;
reg i2c_read_done;

// Edge detecting signals
reg i2c_ctrl_rd_reg;
wire i2c_ctrl_rd_edge;
reg codec_rd_en_reg;
wire codec_rd_en_edge;
reg codec_wr_en_reg;
wire codec_wr_en_edge;

assign i2c_ctrl_rd_edge = i2c_ctrl_rd_reg & i2c_ctrl_rd;
assign codec_rd_en_edge = codec_rd_en_reg & codec_rd_en;
assign codec_wr_en_edge = codec_wr_en_reg & codec_wr_en;

always @ (posedge clk) begin
  i2c_ctrl_rd_reg <= !i2c_ctrl_rd;
  codec_rd_en_reg <= !codec_rd_en;
  codec_wr_en_reg <= !codec_wr_en;
end

//////////////////////////////////////////////////////
////////////////// WB State Machines /////////////////
//// These state machines control the WB Interface ///
//// And translate WR/RD instructions to WB //////////
always @ ( posedge clk or posedge reset ) begin
  if (reset == 1'b1) begin
    wb_state_curr <= WB_IDLE;
    wb_done <= 1'b1;
    wb_wait_for_ack <= 1'b0;
    i2c_ctrl_data_reg <= 8'h00;
  end
  else begin
    wb_done <= 1'b0;
    wb_wait_for_ack <= 1'b0;
    i2c_ctrl_data_reg <= i2c_ctrl_data_reg;
    case (wb_state_curr)
      WB_IDLE: begin // Does Nothing. Waits for wb_read or wb_write
        if (wb_write) begin
          wb_done <= 1'b0;
          wb_state_curr <= WB_ADDR_WR;
        end
        else if (i2c_ctrl_rd_edge) begin
          wb_done <= 1'b0;
          i2c_ctrl_addr_reg <= i2c_ctrl_addr;
          wb_state_curr <= WB_ADDR_RD;
        end
        else begin
          wb_done <= 1'b1;
          wb_state_curr <= WB_IDLE;
        end;
      end
      //////// WR States //////
      WB_ADDR_WR: begin // Sets the WB address. Waits for ACK
        if(wbs_ack_i) begin
          wb_state_curr <= WB_DATA_WR;
          wb_wait_for_ack <= 1'b0;
        end
        else begin
          wb_wait_for_ack <= 1'b1;
        end;
      end

      WB_DATA_WR: begin // Sets WB Data. Waits for ACK
        if(wbs_ack_i) begin
          wb_state_curr <= WB_CMD_WR;
          wb_wait_for_ack <= 1'b0;
        end
        else begin
          wb_wait_for_ack <= 1'b1;
        end;
      end

      WB_CMD_WR: begin // Sets WB CMD. Waits for ACK
        if(wbs_ack_i) begin
          wb_state_curr <= WB_IDLE;
          wb_done <= 1'b1;
          wb_wait_for_ack <= 1'b0;
        end
        else begin
          wb_wait_for_ack <= 1'b1;
        end;
      end

      //////// RD States //////
      WB_ADDR_RD: begin
        if(wbs_ack_i) begin
          wb_state_curr <= WB_IDLE;
          i2c_ctrl_data_reg <= wbs_dat_i;
          wb_wait_for_ack <= 1'b0;
        end
        else begin
          wb_wait_for_ack <= 1'b1;
        end;
      end

    endcase // case(wb_state_curr)
  end //if (reset == 1'b1) begin
end

// Logic State machine
always @ (posedge clk or negedge reset ) begin
  if (reset == 1'b1) begin
    wbs_we_o_reg <= 1'b0;
    wbs_stb_o_reg <= 1'b0;
    wbs_cyc_o_reg <= 1'b0;
    wbs_adr_o_reg <= 0;
    wbs_dat_o_reg <= 0;
  end
  else begin
    wbs_we_o_reg <= 1'b1;
    wbs_stb_o_reg <= 1'b0;
    wbs_cyc_o_reg <= 1'b0;
    wbs_dat_o_reg <= wbs_dat_o_reg;
    wbs_dat_o_reg <= wbs_dat_o_reg;

    case (wb_state_curr)
      WB_IDLE: begin // Does Nothing. Waits for wb_read or wb_write
        wbs_we_o_reg <= 1'b0;
        wbs_stb_o_reg <= 1'b0;
        wbs_cyc_o_reg <= 1'b0;
        if (wb_write) begin

        end
      end
      //////// WR States //////
      WB_ADDR_WR: begin // Sets the WB address. Waits for ACK
        wbs_adr_o_reg <= WB_ADDR;
        wbs_dat_o_reg <= i2c_addr;
        wbs_stb_o_reg <= 1'b1;
        wbs_cyc_o_reg <= 1'b1;
        if(wb_wait_for_ack) begin
          wbs_stb_o_reg <= 1'b0;
        end
      end

      WB_DATA_WR: begin // Sets WB Data. Waits for ACK
        wbs_adr_o_reg <= WB_DATA;
        wbs_dat_o_reg <= i2c_data;
        wbs_stb_o_reg <= 1'b1;
        wbs_cyc_o_reg <= 1'b1;
        if(wb_wait_for_ack) begin
          wbs_stb_o_reg <= 1'b0;
        end
      end

      WB_CMD_WR: begin
        wbs_adr_o_reg <= WB_CMD;
        wbs_dat_o_reg <= i2c_command;
        wbs_stb_o_reg <= 1'b1;
        wbs_cyc_o_reg <= 1'b1;
        if(wb_wait_for_ack) begin
          wbs_stb_o_reg <= 1'b0;
        end
      end

      //////// RD States ///////
      WB_ADDR_RD: begin
        wbs_adr_o_reg <= i2c_ctrl_addr_reg;
        wbs_stb_o_reg <= 1'b1;
        wbs_cyc_o_reg <= 1'b1;
        wbs_we_o_reg <= 1'b0;
        if(wb_wait_for_ack) begin
          wbs_stb_o_reg <= 1'b0;
        end
      end
    endcase //case (wb_state_curr)
  end
end

/////////////////////////////////////////////////
////////////// END WB State Machines ////////////
/////////////////////////////////////////////////

//********** I2C Transactions State Machines *********//
//****************************************************//
//** These control the sequence of WB instructions ***//
//** To send I2C transactions ************************//
//----------------------------------------------------//
//******** RW Sequence State Machine *****************//
always @ ( posedge clk or negedge reset ) begin
  if (reset) begin
    i2c_state <= I2C_IDLE;
    wb_read <= 1'b0;
    wb_write <= 1'b0;
    controller_busy_reg <= 1'b0;
    i2c_addr <= 8'h00;
    i2c_data <= 8'h00;
    i2c_command <= 8'h00;
  end
  else begin
    wb_read <= 1'b0;
    wb_write <= 1'b0;
    controller_busy_reg <= 1'b1;
    i2c_addr <= i2c_addr;
    i2c_data <= i2c_data;
    i2c_command <= i2c_command;
    case (i2c_state)
      I2C_IDLE: begin
        if (codec_wr_en_edge) begin // Write register to CODEC
          i2c_state <= I2C_WRITE;
          i2c_addr <= {1'b0, WB_CODEC_ADDR}; // Always the same
          i2c_data <= codec_data_wr;
          i2c_command <= 8'b00000101; // CMD Start & CMD Write
          wb_write <= 1'b1;
          controller_busy_reg <= 1'b1;
        end
        else if (codec_rd_en_edge) begin // Read register from CODEC
          // Step 1 - Write register addr to device
          i2c_state <= I2C_READ_1;
          i2c_addr <= {1'b0, WB_CODEC_ADDR}; // Always the same
          i2c_data <= codec_reg_addr; // Device Register Addr
          i2c_command <= 8'b00000101; // CMD Start & CMD Write
          wb_write <= 1'b1;
          controller_busy_reg <= 1'b1;
        end
        else begin
          i2c_state <= I2C_IDLE;
          controller_busy_reg <= 1'b0;
        end
      end

      I2C_READ_1: begin // Wait for wb to start working
        if (wb_done == 1'b0) begin
          i2c_state <= I2C_READ_2;
        end
      end

      I2C_READ_2: begin // Step 2 - Send I2C rd command to device
        if (wb_done) begin
          i2c_state <= I2C_READ_3;
          i2c_addr <= {1'b0, WB_CODEC_ADDR}; // Always the same
          i2c_data <= 8'h00;
          i2c_command <= 8'b0000011; // CMD Start & CMD Read
          wb_write <= 1'b1;
        end
      end

      I2C_READ_3: begin
        if (wb_done == 1'b0) begin
          i2c_state <= I2C_READ_4;
        end
      end

      I2C_READ_4: begin
        if (wb_done) begin
          i2c_state <= I2C_READ_5;
          i2c_command <= 8'b0010000; // CMD Stop
          wb_write <= 1'b1;
        end
      end

      I2C_READ_5: begin
        if (wb_done == 1'b0) begin
          i2c_state <= I2C_READ_6;
        end
      end

      I2C_READ_6: begin
        if (wb_done) begin
          i2c_state <= I2C_IDLE;
        end
      end

      I2C_WRITE: begin
        if (wb_done) begin
          i2c_state <= I2C_IDLE;
        end
      end
    endcase
  end
end
endmodule
