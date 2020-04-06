module codec_registers #(
	// Number of register address bits
	parameter integer OPT_MEM_ADDR_BITS = 5
)
(

  ////////////////////////////////
  //////// AXI CONTROLLER ////////
  // Clock and Reset
  input  wire        axi_clk,
  input  wire        axi_reset,

  // Data signals
  input  wire [ 31 : 0 ]                    data_in,
  output wire [ 31 : 0 ]                    data_out,
  input  wire [ OPT_MEM_ADDR_BITS - 1 : 0 ] reg_addr_wr,
  input  wire [ OPT_MEM_ADDR_BITS - 1 : 0 ] reg_addr_rd,
  input  wire                               data_wren,
  input  wire [ 3 : 0 ]                     byte_enable,

  // Signals from the design
  input  wire        clear_codec_i2c_data_wr,
  input  wire        clear_codec_i2c_data_rd,
  output wire        codec_i2c_data_wr,
  output wire        codec_i2c_data_rd,
  input  wire        controller_busy,
  input  wire        codec_init_done,
  input  wire        data_in_valid,
  input  wire        missed_ack,
  output wire [31:0] codec_i2c_addr,
  output wire [31:0] codec_i2c_wr_data,
  input  wire [31:0] codec_i2c_rd_data,
  input  wire        update_codec_i2c_rd_data,
  output wire        controller_reset,
  input  wire [63:0] audio_data_out,
  /////////////////////////
  //// Counter Signals ////
  /////////////////////////
  // AXI CLK //
  input wire [31:0] DOWNSTREAM_axis_wr_data_count,
  input wire [31:0] UPSTREAM_axis_rd_data_count,
  // Audio CLK //
  input wire [31:0] DOWNSTREAM_axis_rd_data_count,
  input wire [31:0] UPSTREAM_axis_wr_data_count

);

`include "register_params.svh"

`define CODEC_I2C_CTRL_REG_ADDR                6'h00
`define CODEC_I2C_ADDR_REG_ADDR                6'h01
`define CODEC_I2C_WR_DATA_REG_ADDR             6'h02
`define CODEC_I2C_RD_DATA_REG_ADDR             6'h03
`define MISC_DATA_0_REG_ADDR                   6'h04
`define MISC_DATA_1_REG_ADDR                   6'h05
`define MISC_DATA_2_REG_ADDR                   6'h06
`define DOWNSTREAM_AXIS_WR_DATA_COUNT_REG_ADDR 6'h08
`define UPSTREAM_AXIS_RD_DATA_COUNT_REG_ADDR   6'h09
`define DOWNSTREAM_AXIS_RD_DATA_COUNT_REG_ADDR 6'h0a
`define UPSTREAM_AXIS_WR_DATA_COUNT_REG_ADDR   6'h0b

logic [31:0] reg_data_out;



///////////////////////////////////////
// Address 0
// codec_i2c_ctrl_reg
///////////////////////////////////////
// Write Enable
wire codec_i2c_ctrl_reg_wr_en    = `DECODE_MEM_WR(`CODEC_I2C_CTRL_REG_ADDR, reg_addr_wr, data_wren);

// Registers
logic [31:0] codec_i2c_ctrl_reg;
reg codec_i2c_data_wr_reg;
reg codec_i2c_data_rd_reg;
reg controller_busy_reg;
reg codec_init_done_reg;
reg data_in_valid_reg;
reg missed_ack_reg;
reg controller_reset_reg;

// Assignments
assign codec_i2c_ctrl_reg[0]    = codec_i2c_data_wr_reg;
assign codec_i2c_ctrl_reg[1]    = codec_i2c_data_rd_reg;
assign codec_i2c_ctrl_reg[2]    = controller_busy_reg;
assign codec_i2c_ctrl_reg[3]    = codec_init_done_reg;
assign codec_i2c_ctrl_reg[4]    = data_in_valid_reg;
assign codec_i2c_ctrl_reg[5]    = missed_ack_reg;
assign codec_i2c_ctrl_reg[31]   = controller_reset_reg;
assign codec_i2c_ctrl_reg[30:6] = 'h0;

assign codec_i2c_data_wr = codec_i2c_data_wr_reg;
assign codec_i2c_data_rd = codec_i2c_data_rd_reg;
assign controller_reset  = controller_reset_reg;

// Bit 0
// Data WR
`GEN_REG_SW_WR1_HW_CLR(axi_clk, axi_reset,              // Clock and Reset
						1,                              // Size
						0,                              // Reset Value
						codec_i2c_ctrl_reg_wr_en,       // WR Enable
						data_in[0],                     // Data In
						clear_codec_i2c_data_wr,        // Clear
						codec_i2c_data_wr_reg)          // Register

// Bit 1
// Data RD
`GEN_REG_SW_WR1_HW_CLR(axi_clk, axi_reset,              // Clock and Reset
						1,                              // Size
						0,                              // Reset Value
						codec_i2c_ctrl_reg_wr_en,       // WR Enable
						data_in[1],                     // Data In
						clear_codec_i2c_data_rd,        // Clear
						codec_i2c_data_rd_reg)          // Register

// Bit 2
// Controller Busy
// This is a Read Only Register
`GEN_REG_SW_RO_HW_WO(axi_clk, axi_reset,   // Clock and Reset
					1'b0,                  // Size
					1'b1,                  // Reset Value
					controller_busy,       // Signal
					controller_busy_reg)   // Register

// Bit 3
// CODEC Initialization Done
// This bit gets cleared by the SW when it writes a 1'b1
// This bit gets set when the HW set a 1'b1
`GEN_REG_SW_RWC1_HW_WO(axi_clk, axi_reset,         // Clock and Reset
						1,                         // Size
						0,                         // Reset Value
						codec_i2c_ctrl_reg_wr_en,  // Write Enable
						data_in[3],                // Clear Bit
						codec_init_done,           // Pulse Signal
						codec_init_done_reg)       // Register

// Bit 4
// Data In Valid
// This bit gets cleared by the SW when it writes a 1'b1
`GEN_REG_SW_RWC1_HW_WO(axi_clk, axi_reset,        // Clock and Reset
						1,                        // Size
						0,                        // Reset Value
						codec_i2c_ctrl_reg_wr_en, // Write Enable
						data_in[4],               // Clear Bit
						update_codec_i2c_rd_data, // Pulse Signal
						data_in_valid_reg)        // Register

// Bit 5
// Missed ACK
// This bit gets cleared by the SW when it writes a 1'b1
`GEN_REG_SW_RWC1_HW_WO(axi_clk, axi_reset,        // Clock and Reset
						1,                        // Size
						0,                        // Reset Value
						codec_i2c_ctrl_reg_wr_en, // Write Enable 
						data_in[5],               // Clear Bit  
						missed_ack,               // Pulse Signal
						missed_ack_reg)           // Register

// Bit 31
// Controller Reset
// This bit gets set by the SW when it writes a 1'b1 and cleared by the HW when the reset sequence completes
`GEN_REG_SW_WR1_HW_CLR(axi_clk, axi_reset,              // Clock and Reset
						1,                              // Size
						0,                              // Reset Value
						codec_i2c_ctrl_reg_wr_en,       // WR Enable
						data_in[31],                    // Data In
						codec_init_done,                // Clear
						controller_reset_reg)           // Register

///////////////////////////////////////
// Address 1
// codec_i2c_addr
///////////////////////////////////////
// Wite Enable
wire codec_i2c_addr_reg_wr_en = `DECODE_MEM_WR(`CODEC_I2C_ADDR_REG_ADDR, reg_addr_wr, data_wren);
// Register
reg   [31:0] codec_i2c_addr_reg;
// Assignment
assign codec_i2c_addr = codec_i2c_addr_reg;

`GEN_REG_SW_RW(axi_clk, axi_reset,        // Clock and Reset
				0,                        // Reset Value
				codec_i2c_addr_reg_wr_en, // Write Enable
				data_in,                  // Data In
				codec_i2c_addr_reg)       // Register

///////////////////////////////////////
// Address 2
// codec_i2c_wr_data
///////////////////////////////////////
// Wite Enable
wire codec_i2c_wr_data_reg_wr_en = `DECODE_MEM_WR(`CODEC_I2C_WR_DATA_REG_ADDR, reg_addr_wr, data_wren);
// Register
reg   [31:0] codec_i2c_wr_data_reg;
// Assignment
assign codec_i2c_wr_data = codec_i2c_wr_data_reg;

`GEN_REG_SW_RW(axi_clk, axi_reset,           // Clock and Reset 
				0,                           // Reset Value
				codec_i2c_wr_data_reg_wr_en, // Write Enable
				data_in,                     // Data In
				codec_i2c_wr_data_reg)       // Register

///////////////////////////////////////
// Address 3
// codec_i2c_rd_data
///////////////////////////////////////
reg   [31:0] codec_i2c_rd_data_reg;
wire data_rd_reset;
assign data_rd_reset = axi_reset & (~codec_i2c_data_rd_reg);

// This register is read by the SW and written by the HW
// It is reset every time there is an CODEC read request
`GEN_REG_SW_RO_HW_WO(axi_clk, data_rd_reset,      // Clock and Reset
						32'hcafecafe,             // Reset Value
						update_codec_i2c_rd_data, // Write Enable
						codec_i2c_rd_data,        // Data In
						codec_i2c_rd_data_reg)    // Register

///////////////////////////////////////
// Address 4
// misc_data_0
///////////////////////////////////////
// Write Enable
wire misc_data_0_wr_en = `DECODE_MEM_WR(`MISC_DATA_0_REG_ADDR, reg_addr_wr, data_wren);
// Register
reg   [31:0] misc_data_0;

`GEN_REG_SW_RO_HW_WO(axi_clk, data_rd_reset,      // Clock and Reset
						32'hcafecafe,             // Reset Value
						1'b1,                     // Write Enable
						audio_data_out[31:0],     // Data In
						misc_data_0)              // Register


///////////////////////////////////////
// Address 5
// misc_data_1
///////////////////////////////////////
// Write Enable
wire misc_data_1_wr_en = `DECODE_MEM_WR(`MISC_DATA_1_REG_ADDR, reg_addr_wr, data_wren);
// Register
reg   [31:0] misc_data_1;

`GEN_REG_SW_RO_HW_WO(axi_clk, data_rd_reset,      // Clock and Reset
						32'hcafecafe,             // Reset Value
						1'b1,                     // Write Enable
						audio_data_out[63:32],    // Data In
						misc_data_1)              // Register
///////////////////////////////////////
// Address 6
// misc_data_2
///////////////////////////////////////
// Write Enable
wire misc_data_2_wr_en = `DECODE_MEM_WR(`MISC_DATA_2_REG_ADDR, reg_addr_wr, data_wren);
// Register
reg   [31:0] misc_data_2;

`GEN_REG_SW_RW(axi_clk, axi_reset, 0, misc_data_2_wr_en, data_in, misc_data_2)


///////////////////////////////////////
// Address 7
// DOWNSTREAM_axis_wr_data_count
///////////////////////////////////////
reg [31:0] DOWNSTREAM_axis_wr_data_count_reg;
`GEN_REG_SW_RO_HW_WO(axi_clk, axi_reset,                   // Clock and Reset
						32'hcafecafe,                      // Reset Value
						1'b1,                              // Write Enable
						DOWNSTREAM_axis_wr_data_count,     // Data In
						DOWNSTREAM_axis_wr_data_count_reg) // Register

///////////////////////////////////////
// Address 8
// UPSTREAM_axis_rd_data_count
///////////////////////////////////////
reg [31:0] UPSTREAM_axis_rd_data_count_reg;
`GEN_REG_SW_RO_HW_WO(axi_clk, axi_reset,                  // Clock and Reset
						32'hcafecafe,                     // Reset Value
						1'b1,                             // Write Enable
						UPSTREAM_axis_rd_data_count,      // Data In
						UPSTREAM_axis_rd_data_count_reg)  // Register

///////////////////////////////////////
// Address 9
// DOWNSTREAM_axis_rd_data_count
///////////////////////////////////////
reg [31:0] DOWNSTREAM_axis_rd_data_count_reg;
`GEN_REG_SW_RO_HW_WO(axi_clk, axi_reset,                   // Clock and Reset
						32'hcafecafe,                      // Reset Value
						1'b1,                              // Write Enable
						DOWNSTREAM_axis_rd_data_count,     // Data In
						DOWNSTREAM_axis_rd_data_count_reg) // Register

///////////////////////////////////////
// Address 10
// UPSTREAM_axis_wr_data_count
///////////////////////////////////////
reg [31:0] UPSTREAM_axis_wr_data_count_reg;
`GEN_REG_SW_RO_HW_WO(axi_clk, axi_reset,                  // Clock and Reset
						32'hcafecafe,                     // Reset Value
						1'b1,                             // Write Enable
						UPSTREAM_axis_wr_data_count,      // Data In
						UPSTREAM_axis_wr_data_count_reg)  // Register

////////////////////////////////////////
// Data Read Logic
////////////////////////////////////////
assign data_out = reg_data_out;

always_comb
	begin
	      // Address decoding for reading registers
	      case ( reg_addr_rd )
	        `CODEC_I2C_CTRL_REG_ADDR                : reg_data_out = codec_i2c_ctrl_reg;
	        `CODEC_I2C_ADDR_REG_ADDR                : reg_data_out = codec_i2c_addr_reg;
	        `CODEC_I2C_WR_DATA_REG_ADDR             : reg_data_out = codec_i2c_wr_data_reg;
	        `CODEC_I2C_RD_DATA_REG_ADDR             : reg_data_out = codec_i2c_rd_data_reg;
	        `MISC_DATA_0_REG_ADDR                   : reg_data_out = misc_data_0;
	        `MISC_DATA_1_REG_ADDR                   : reg_data_out = misc_data_1;
	        `MISC_DATA_2_REG_ADDR                   : reg_data_out = misc_data_2;
			`DOWNSTREAM_AXIS_WR_DATA_COUNT_REG_ADDR : reg_data_out = DOWNSTREAM_axis_wr_data_count_reg;
			`UPSTREAM_AXIS_RD_DATA_COUNT_REG_ADDR   : reg_data_out = UPSTREAM_axis_rd_data_count_reg;
			`DOWNSTREAM_AXIS_RD_DATA_COUNT_REG_ADDR : reg_data_out = DOWNSTREAM_axis_rd_data_count_reg;
			`UPSTREAM_AXIS_WR_DATA_COUNT_REG_ADDR   : reg_data_out = UPSTREAM_axis_wr_data_count_reg;
	        default : reg_data_out = 32'hdeadbeef;
	      endcase
	end

endmodule