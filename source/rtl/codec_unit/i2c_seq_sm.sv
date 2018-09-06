/////////////////////////////////////////////////////
// This module acts as a bridge for high-level     //
// I2C RD/WR Operations to internal WB commands.   //
// This module talks to the WB Controller.         //
/////////////////////////////////////////////////////
// Rev. 0.1 - Init                                 //
/////////////////////////////////////////////////////

module i2c_seq_sm (
  input wire clk,
  input wire reset,
  
  // CODEC Register RD/WR Signals
  input  wire       codec_rd_en,
  input  wire       codec_wr_en,
  input  wire [7:0] codec_reg_addr,
  input  wire [7:0] codec_data_wr,
  output wire [7:0] codec_data_rd,
  output wire       codec_data_rd_valid,
  output wire       controller_busy,

  // Control signals to the WB Controller
  input wire        wb_read,
  input wire        wb_write,
  input wire  [7:0] wb_data_in,
  output wire [3:0] wb_address,
  output wire [7:0] wb_data_out,
  input wire        wb_data_in_valid,
  input wire        wb_done
);


localparam I2C_CTRL_CMD_ADDR        = 4'h3;
localparam I2C_CTRL_ADDR_ADDR       = 4'h2;
localparam I2C_CTRL_DATA_ADDR       = 4'h4;

localparam CODEC_I2C_ADDR           = 7'b0011010; // I2C Address of the SSM2603 CODEC

/////////////////////////////////////////////////
///////// High-level I2C State Machine //////////
localparam I2C_IDLE         = 3'h0;
localparam I2C_WAIT_FOR_ACK = 3'h1;
localparam I2C_WRITE_1      = 3'h2;
localparam I2C_WRITE_2      = 3'h3;
localparam I2C_WRITE_3      = 3'h4;
localparam I2C_WRITE_4      = 3'h5;
localparam I2C_WRITE_5      = 3'h6;
localparam I2C_WRITE_6      = 3'h7;



assign i2c_ctrl_data = i2c_ctrl_data_reg;

assign controller_busy     = controller_busy_reg | !wb_done;
assign codec_data_rd       = codec_data_rd_reg;
assign codec_data_rd_valid = codec_data_rd_valid_reg;


reg  [2:0] i2c_state_next;
wire [2:0] i2c_state_curr;

reg  [2:0] i2c_state_after_ack;

// WB State Machine Registers
reg        wb_read;
reg        wb_write;
reg  [7:0] wb_data_out;
reg  [3:0] wb_addr;
wire [7:0] wb_data_in;
wire       wb_done;
wire       wb_data_in_valid;

reg [7:0] i2c_ctrl_data_reg;
reg [2:0] i2c_ctrl_addr_reg;

// CODEC Register signals
reg       controller_busy_reg;
reg [7:0] codec_data_rd_reg;
reg       codec_data_rd_valid_reg;

// I2C Registers
reg [7:0] i2c_data;
reg [7:0] i2c_addr;
reg [7:0] i2c_int_addr;
reg [7:0] i2c_command;
reg       i2c_read_done;



/////////////////////////////////////////////////
////////////// END WB State Machines ////////////
/////////////////////////////////////////////////

//********** I2C Transactions State Machines ************//
//*******************************************************//
//** These SM control the sequence of WB instructions ***//
//** to send I2C transactions                         ***//
//*******************************************************//
//******** RW Sequence State Machine ********************//

assign i2c_state_curr = i2c_state_next;

always @ ( posedge clk or negedge reset ) begin
  if (reset) begin
    i2c_state_next      <= I2C_IDLE;
    i2c_state_after_ack <= I2C_IDLE;
    controller_busy_reg <= 1'b0;
    i2c_addr            <= 8'h00;
    i2c_int_addr        <= 8'h00;
    i2c_data            <= 8'h00;
    i2c_command         <= 8'h00;
  end
  else begin
    controller_busy_reg <= 1'b1;
    i2c_addr            <= i2c_addr;
    i2c_int_addr        <= i2c_int_addr;
    i2c_data            <= i2c_data;
    i2c_command         <= i2c_command;
    i2c_state_next      <= i2c_state_next;
    i2c_state_after_ack <= i2c_state_after_ack;
    case (i2c_state_curr)
      I2C_IDLE: begin
        if (codec_rd_en) begin // Read register from the CODEC
          i2c_state_next      <= I2C_WRITE_1;
          i2c_addr            <= {1'b0, CODEC_I2C_ADDR}; // Always the same
          i2c_int_addr        <= codec_reg_addr; // Internal Address
          i2c_data            <= 'h0;  // Data to write to the Internal Address
          i2c_command         <= 8'b00000101; // CMD Start & CMD Write
          controller_busy_reg <= 1'b1;
        end
      end // I2C_IDLE:

      I2C_WAIT_FOR_ACK: begin // Wait for Completion
        if (wb_done) begin
          i2c_state_next <= i2c_state_after_ack;
        end // if(wb_done)
      end // I2C_WRITE_1:

      I2C_WRITE_1: begin // Step 1 - Write the I2C CODEC address to the WB I2C Controller
        i2c_state_after_ack <= I2C_WRITE_2;
        i2c_state_next      <= I2C_WAIT_FOR_ACK;
      end // I2C_WRITE_1:

      I2C_WRITE_2: begin // Step 2 - Write the Internal Address to the WB I2C Controller as Data
        i2c_state_after_ack <= I2C_WRITE_3;
        i2c_state_next      <= I2C_WAIT_FOR_ACK;
      end // I2C_WRITE_1:

      I2C_WRITE_3: begin // Step 3 - Write the I2C Command to the I2C Controller Interface
        i2c_state_after_ack <= I2C_WRITE_4;
        i2c_state_next      <= I2C_WAIT_FOR_ACK;
      end // I2C_WRITE_1:

      default: begin
        i2c_state_next <= I2C_IDLE;
      end // default:
    endcase // i2c_state_curr
  end
end // always @ ( posedge clk or negedge reset )

always @(posedge clk or negedge reset ) begin 
  if (reset) begin
    wb_read     <= 'h0;
    wb_write    <= 'h0;
    wb_data_out <= 'h0;
    wb_addr     <= 'h0;
  end // if (reset)
  else begin
    wb_read     <= 1'b0;
    wb_write    <= 1'b0;
    wb_data_out <= wb_data_out;
    wb_addr     <= wb_addr;
    case (i2c_state_curr)
      I2C_IDLE: begin
        wb_read     <= 'h0;
        wb_write    <= 'h0;
        wb_data_out <= 'h0;
        wb_addr     <= 'h0;
      end // I2C_IDLE:

      I2C_WAIT_FOR_ACK: begin // Wait for the completion
        wb_data_out <= 'h0;
        wb_addr     <= 'h0;
        wb_write    <= 1'b0;
      end // I2C_WRITE_2:

      I2C_WRITE_1: begin // Step 1 - Write the I2C CODEC address to the WB I2C Controller
        wb_data_out <= i2c_addr;
        wb_addr     <= I2C_CTRL_ADDR_ADDR;
        wb_write    <= 1'b1;
      end // I2C_WRITE_1:

      I2C_WRITE_2: begin // Step 2 - Write the Internal Address to the WB I2C Controller as Data
        wb_data_out <= i2c_int_addr;
        wb_addr     <= I2C_CTRL_DATA_ADDR;
        wb_write    <= 1'b1;
      end // I2C_WRITE_1:

      I2C_WRITE_3: begin // Step 3 - Write the I2C Command to the I2C Controller Interface
        wb_data_out <= 8'b00000011; // RD && Start
        wb_addr     <= I2C_CTRL_CMD_ADDR;
        wb_write    <= 1'b1;
      end // I2C_WRITE_1:

    endcase // i2c_state_curr
  end // else
end

endmodule