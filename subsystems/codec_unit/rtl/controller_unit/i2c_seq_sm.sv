/////////////////////////////////////////////////////
// This module acts as a bridge for high-level     //
// I2C RD/WR Operations to internal WB commands.   //
// This module talks to the WB Controller.         //
/////////////////////////////////////////////////////
// Rev. 0.1 - Init                                 //
// Rev. 0.2 - Sequencing issues                    //
/////////////////////////////////////////////////////

module i2c_seq_sm (
  input wire clk,
  input wire reset_n,

  // CODEC Register RD/WR Signals
  input  wire       codec_rd_en,
  input  wire       codec_wr_en,
  input  wire [7:0] codec_reg_addr,
  input  wire [8:0] codec_data_in,
  output wire [8:0] codec_data_out,
  output wire       codec_data_out_valid,
  output wire       controller_busy,

  // Control signals to the WB Controller
  output wire       wb_read,
  output wire       wb_write,
  output wire [3:0] wb_address,
  output wire [7:0] wb_data_out,
  input wire  [7:0] wb_data_in,
  input wire        wb_data_in_valid,
  input wire        wb_done,

  // Misc
  output wire       missed_ack
);

localparam I2C_CTRL_STS0_ADDR       = 4'h0;
localparam I2C_CTRL_STS1_ADDR       = 4'h1;
localparam I2C_CTRL_CMD_ADDR        = 4'h3;
localparam I2C_CTRL_ADDR_ADDR       = 4'h2;
localparam I2C_CTRL_DATA_ADDR       = 4'h4;

localparam CODEC_I2C_ADDR           = 7'b0011010; // I2C Address of the SSM2603 CODEC

/////////////////////////////////////////////////
/////////// I2C WB Command Registers ////////////
localparam CMD_START       = 8'b00000001; // Bit 0
localparam CMD_READ        = 8'b00000010; // Bit 1
localparam CMD_WRITE       = 8'b00000100; // Bit 2
localparam CMD_MULTIPLE_WR = 8'b00001000; // Bit 3
localparam CMD_STOP        = 8'b00010000; // Bit 4

/////////////////////////////////////////////////
///////// High-level I2C State Machine //////////
localparam I2C_IDLE             = 4'h0;
localparam I2C_WAIT_FOR_ACK     = 4'h1;
localparam I2C_WAIT_FOR_RD_ACK  = 4'h2;
localparam I2C_WRITE_DEV_ADDR   = 4'h3;
localparam I2C_WRITE_INT_ADDR   = 4'h4;
localparam I2C_WRITE_WB_CMD     = 4'h5;
localparam I2C_READ_WB_REG      = 4'h6;
localparam I2C_WAIT_WR_XFR_DONE = 4'h7;
localparam I2C_GET_DATA_RD      = 4'h8;
localparam I2C_WRITE_DATA       = 4'h9;
localparam I2C_GET_RD_STS       = 4'ha;
localparam I2C_WR_STOP_CMD      = 4'hb;

reg  [3:0] i2c_state_next;
wire [3:0] i2c_state_curr;
reg  [3:0] i2c_state_after_ack;

reg i2c_xfer_started;
reg i2c_xfer_is_rd;
reg int_addr_sent;
reg first_read_sent;
reg second_read_sent;
reg first_read_received;
// WB State Machine Registers
reg        wb_read_reg     ;
reg        wb_write_reg    ;
reg  [7:0] wb_data_out_reg ;
reg  [3:0] wb_address_reg  ;
reg  [3:0] next_wb_addr_reg;
reg  [7:0] wb_data_in_reg  ;
reg        missed_ack_reg  ;

reg [7:0] i2c_ctrl_data_reg;
reg [2:0] i2c_ctrl_addr_reg;

// CODEC Register signals
reg       controller_busy_reg;
reg [8:0] codec_data_out_reg;
reg       codec_data_out_valid_reg;

// I2C Registers
reg [8:0] i2c_data; // 9 bits
reg [7:0] i2c_addr;
reg [7:0] i2c_int_addr;
reg [7:0] i2c_command;
reg       i2c_read_done;



assign i2c_ctrl_data = i2c_ctrl_data_reg;

assign controller_busy      = controller_busy_reg;
assign codec_data_out       = codec_data_out_reg;
assign codec_data_out_valid = codec_data_out_valid_reg;

// Outputs to the WB Controller

assign wb_read     = wb_read_reg    ;
assign wb_write    = wb_write_reg   ;
assign wb_address  = wb_address_reg ;
assign wb_data_out = wb_data_out_reg;

// Misc outputs
assign missed_ack = missed_ack_reg;

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

always @ ( posedge clk or negedge reset_n ) begin
  if (!reset_n) begin
    i2c_state_next       <= I2C_IDLE;
    i2c_state_after_ack  <= I2C_IDLE;
    controller_busy_reg  <= 1'b0;
    i2c_addr             <= 8'h00;
    i2c_int_addr         <= 8'h00;
    i2c_data             <= 8'h00;
    i2c_command          <= 8'h00;

    wb_read_reg          <= 'h0;
    wb_write_reg         <= 'h0;
    wb_data_out_reg      <= 'h0;
    wb_data_in_reg       <= 'h0;
    wb_address_reg       <= 'h0;    

    next_wb_addr_reg     <= 'h0;
    i2c_xfer_started     <= 1'b0;
    i2c_xfer_is_rd       <= 1'b0;
    int_addr_sent        <= 1'b0;
    first_read_sent      <= 1'b0;
    second_read_sent     <= 1'b0;
    first_read_received  <= 1'b0;

    codec_data_out_reg       <= 8'h00;
    codec_data_out_valid_reg <= 1'b0;
    missed_ack_reg           <= 1'b0;

  end
  else begin
    controller_busy_reg <= controller_busy_reg;
    i2c_addr            <= i2c_addr;
    i2c_int_addr        <= i2c_int_addr;
    i2c_data            <= i2c_data;
    i2c_command         <= i2c_command;
    i2c_state_next      <= i2c_state_next;
    i2c_state_after_ack <= i2c_state_after_ack;

    wb_read_reg         <= 1'b0;
    wb_write_reg        <= 1'b0;
    wb_data_out_reg     <= wb_data_out_reg;
    wb_data_in_reg      <= wb_data_in_reg;
    wb_address_reg      <= wb_address_reg;

    next_wb_addr_reg    <= next_wb_addr_reg;
    i2c_xfer_started    <= i2c_xfer_started;
    i2c_xfer_is_rd      <= i2c_xfer_is_rd;

    codec_data_out_valid_reg <= codec_data_out_valid_reg;
    codec_data_out_reg       <= codec_data_out_reg;

    int_addr_sent            <= int_addr_sent;
    first_read_sent          <= first_read_sent;
    second_read_sent         <= second_read_sent;
    first_read_received      <= first_read_received;

    missed_ack_reg           <= missed_ack_reg;

    case (i2c_state_curr)
      I2C_IDLE: begin
        i2c_xfer_is_rd           <= 1'b0;
        wb_read_reg              <= 'h0;
        wb_write_reg             <= 'h0;
        wb_data_out_reg          <= wb_data_out_reg;
        wb_address_reg           <= wb_address_reg;
        i2c_xfer_started         <= i2c_xfer_started;
        controller_busy_reg      <= 1'b0;
        codec_data_out_valid_reg <= 1'b0;
        if (codec_rd_en) begin // Read register from the CODEC
          i2c_state_next           <= I2C_WRITE_DEV_ADDR;
          i2c_addr                 <= {1'b0, CODEC_I2C_ADDR}; // Always the same
          // For RD operations, the internal address is shifted 1 bit to the right and the LSB is always 1'b1
          i2c_int_addr             <= {codec_reg_addr[6:0], 1'b0}; // Internal Address
          i2c_data                 <= 'h0;                         // Data to write to the Internal Address
          controller_busy_reg      <= 1'b1;
          i2c_xfer_is_rd           <= 1'b1;
          codec_data_out_valid_reg <= 1'b0;
          int_addr_sent            <= 1'b0;
          first_read_sent          <= 1'b0;
          second_read_sent         <= 1'b0;
          first_read_received      <= 1'b0;
        end
        if (codec_wr_en) begin // Write register to the CODEC
          i2c_state_next           <= I2C_WRITE_DEV_ADDR;
          i2c_addr                 <= {1'b0, CODEC_I2C_ADDR}; // Always the same
          // For Write operations, the MSB of the WR Data is in the LSB of the Address
          i2c_int_addr             <= {codec_reg_addr[6:0], codec_data_in[8]}; // Internal Address
          i2c_data                 <= codec_data_in[7:0];                      // Data to write to the Internal Address
          controller_busy_reg      <= 1'b1;
          codec_data_out_valid_reg <= 1'b0;
          int_addr_sent            <= 1'b0;
          first_read_sent          <= 1'b0;
          second_read_sent         <= 1'b0;
        end        
      end // I2C_IDLE:

      I2C_WAIT_FOR_ACK: begin // Wait for Completion
        if (wb_done) begin
          i2c_state_next <= i2c_state_after_ack;
        end // if(wb_done)
      end

      I2C_WAIT_FOR_RD_ACK: begin // Wait for Completion for a RD request. Sample the data_in
        if (wb_done && wb_data_in_valid) begin
          i2c_state_next <= i2c_state_after_ack;
          wb_data_in_reg <= wb_data_in;
          if (wb_address_reg == I2C_CTRL_DATA_ADDR) begin
            codec_data_out_valid_reg <= first_read_received;
            codec_data_out_reg[7:0]  <= (first_read_received) ? codec_data_out_reg[7:0] : wb_data_in;
            codec_data_out_reg[8]    <= first_read_received ? wb_data_in[0] : 1'b0;
            first_read_received      <= 1'b1;
          end
        end
      end

      I2C_READ_WB_REG: begin // Go to this state when you want to read a register from the I2C controller
        i2c_state_next      <= I2C_WAIT_FOR_RD_ACK;

        wb_address_reg      <= next_wb_addr_reg;
        wb_read_reg         <= 1'b1;
      end

      I2C_WRITE_DEV_ADDR: begin // Step 1 - Write the I2C CODEC Device address to the WB I2C Controller
        i2c_state_after_ack <= I2C_WRITE_INT_ADDR;
        i2c_state_next      <= I2C_WAIT_FOR_ACK;

        wb_data_out_reg <= i2c_addr;
        wb_address_reg  <= I2C_CTRL_ADDR_ADDR;
        wb_write_reg    <= 1'b1;
      end

      I2C_WRITE_INT_ADDR: begin // Step 2 - Write the Internal Address to the WB I2C Controller as Data
        i2c_state_after_ack <= (i2c_xfer_is_rd) ? I2C_WRITE_WB_CMD : I2C_WRITE_DATA;
        i2c_state_next      <= I2C_WAIT_FOR_ACK;

        wb_data_out_reg <= i2c_int_addr;
        wb_address_reg  <= I2C_CTRL_DATA_ADDR;
        wb_write_reg    <= 1'b1;
      end

      I2C_WRITE_DATA: begin // Step 3 - Write the data to be written to the I2C device
        i2c_state_after_ack <= I2C_WRITE_WB_CMD;
        i2c_state_next      <= I2C_WAIT_FOR_ACK;

        wb_data_out_reg <= i2c_data;
        wb_address_reg  <= I2C_CTRL_DATA_ADDR;
        wb_write_reg    <= 1'b1;
      end

      I2C_WRITE_WB_CMD: begin // Step 4 - Write the I2C Command to the I2C Controller Interface
        // For RD operations, if the address hasn't been sent, send it before performing a RD request.
        // For WR operations, you need to send the device address again
        i2c_state_after_ack <= (i2c_xfer_is_rd && !(int_addr_sent && first_read_sent)) ? I2C_WRITE_WB_CMD : I2C_WR_STOP_CMD;
                                                          
        i2c_state_next      <= I2C_WAIT_FOR_ACK;

        // For RD operations, if the address hasn't been sent to the device, send it before performing a RD request.
        // For WR operations you can start the transaction right away
        wb_data_out_reg <= (i2c_xfer_is_rd == 1'b0) ? (CMD_START | CMD_WRITE) :
                           (int_addr_sent  == 1'b0) ? (CMD_WRITE) : (first_read_sent) ?  (CMD_READ) : // Second read (for the MS bit)
                                                                                         (CMD_READ | CMD_START); // First read
        

        wb_address_reg  <= I2C_CTRL_CMD_ADDR;
        wb_write_reg    <= 1'b1;

        i2c_xfer_started <= 1'b0;
        wb_data_in_reg   <= 8'h00; // Clear the Data In

        int_addr_sent    <= 1'b1;
        first_read_sent  <= int_addr_sent;
        second_read_sent <= first_read_sent;
      end

      I2C_WR_STOP_CMD: begin // Step 4.5 - Send the STOP bit to stop after the whole transaction is done
        wb_address_reg  <= I2C_CTRL_CMD_ADDR;
        wb_data_out_reg <= CMD_STOP;
        wb_write_reg    <= 1'b1;

        i2c_state_next      <= I2C_WAIT_FOR_ACK;
        i2c_state_after_ack <= (i2c_xfer_is_rd) ? I2C_WAIT_WR_XFR_DONE : 
                               (int_addr_sent)  ? I2C_WAIT_WR_XFR_DONE : I2C_WRITE_DEV_ADDR;

      end
      
      I2C_WAIT_WR_XFR_DONE: begin // Step 5 - Poll the status register until the transaction is done
        // The transfer has started, wait for the busy bit to clear
        if (i2c_xfer_started) begin // Check for the Busy bit to go 1 -> 0
          if (wb_data_in_reg[0] == 1'b1) begin // Busy bit is still 1
            i2c_state_next      <= I2C_READ_WB_REG;
            i2c_state_after_ack <= I2C_WAIT_WR_XFR_DONE;            

            next_wb_addr_reg    <= I2C_CTRL_STS0_ADDR;
          end
          else begin // Busy bit is 0
            i2c_xfer_started    <= 1'b0;
            // If the address has been sent, then read the data. Otherwise send the command to read the data
            i2c_state_next      <= (i2c_xfer_is_rd == 1'b0) ? I2C_IDLE : I2C_GET_RD_STS;
            missed_ack_reg      <= wb_data_in_reg[3];
          end
        end
        // The transfer hasn't started yet. Wait for the busy bit to assert
        else begin
          if (wb_data_in_reg[0] == 1'b0) begin // Check for the Busy bit to go 0 -> 1
            i2c_state_next      <= I2C_READ_WB_REG;
            i2c_state_after_ack <= I2C_WAIT_WR_XFR_DONE;            

            next_wb_addr_reg    <= I2C_CTRL_STS0_ADDR;
          end
          else begin 
            i2c_xfer_started    <= 1'b1;
            i2c_state_next      <= I2C_WAIT_WR_XFR_DONE;
          end
        end
      end

      I2C_GET_RD_STS: begin // Check the status bits to see if there was a missed_ack
        if (missed_ack_reg) begin
          i2c_state_next <= I2C_IDLE;
        end 
        else begin // There was not a missed ack. The next step is to check the  FIFO Status
          // Read the status register 2
          next_wb_addr_reg    <= I2C_CTRL_STS1_ADDR;
          i2c_state_next      <= I2C_READ_WB_REG;
          i2c_state_after_ack <= I2C_GET_DATA_RD;
        end
      end

      I2C_GET_DATA_RD: begin
        if (wb_data_in_reg[6] == 1'b1) begin // FIFO is empty. Read again
          i2c_state_next      <= I2C_READ_WB_REG;
          i2c_state_after_ack <= I2C_GET_DATA_RD;
          next_wb_addr_reg    <= I2C_CTRL_STS1_ADDR;
        end
        else begin // FIFO is not empty. Let's read the data
          next_wb_addr_reg    <= I2C_CTRL_DATA_ADDR;
          i2c_state_next      <= I2C_READ_WB_REG;
          i2c_state_after_ack <= (first_read_received) ? I2C_IDLE : I2C_GET_RD_STS; // Read the FIFO again to get the MS bit
        end
      end

      default: begin
        i2c_state_next <= I2C_IDLE;
      end // default:
    endcase // i2c_state_curr
  end
end // always @ ( posedge clk or negedge reset_n )

endmodule