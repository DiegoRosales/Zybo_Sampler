module codec_registers (

    ////////////////////////////////
    //////// AXI CONTROLLER ////////
    // Clock and Reset
    input  wire        axi_clk,
    input  wire        axi_reset,

    // Data signals
    input  wire [31:0] data_in,
    output wire [31:0] data_out,
    input  wire [5:0]  reg_addr_wr,
	input  wire [5:0]  reg_addr_rd,
    input  wire        data_wren,
    input  wire [3:0]  byte_enable,

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
    input  wire        update_codec_i2c_rd_data

);

`include "register_params.svh"

`define CODEC_I2C_CTRL_REG_ADDR    6'h00
`define CODEC_I2C_ADDR_REG_ADDR    6'h01
`define CODEC_I2C_WR_DATA_REG_ADDR 6'h02
`define CODEC_I2C_RD_DATA_REG_ADDR 6'h03
`define MISC_DATA_0_REG_ADDR       6'h04
`define MISC_DATA_1_REG_ADDR       6'h05
`define MISC_DATA_2_REG_ADDR       6'h06


logic [31:0] reg_data_out;



///////////////////////////////////////
// Address 0
// codec_i2c_ctrl_reg
///////////////////////////////////////
wire  codec_i2c_ctrl_reg_wr_en = `DECODE_MEM_WR(`CODEC_I2C_CTRL_REG_ADDR, reg_addr_wr, data_wren);
logic [31:0] codec_i2c_ctrl_reg;
reg codec_i2c_data_wr_reg;
reg codec_i2c_data_rd_reg;
reg controller_busy_reg;
reg codec_init_done_reg;
reg data_in_valid_reg;
reg missed_ack_reg;

assign codec_i2c_ctrl_reg[0]    = codec_i2c_data_wr_reg;
assign codec_i2c_ctrl_reg[1]    = codec_i2c_data_rd_reg;
assign codec_i2c_ctrl_reg[2]    = controller_busy_reg;
assign codec_i2c_ctrl_reg[3]    = codec_init_done_reg;
assign codec_i2c_ctrl_reg[4]    = data_in_valid_reg;
assign codec_i2c_ctrl_reg[5]    = missed_ack_reg;
assign codec_i2c_ctrl_reg[31:6] = 'h0;

assign codec_i2c_data_wr = codec_i2c_data_wr_reg;
assign codec_i2c_data_rd = codec_i2c_data_rd_reg;

// Bit 0
// Data WR
`GEN_REG_SW_WR1_HW_CLR(axi_clk, axi_reset, 1, 0, `CODEC_I2C_CTRL_REG_ADDR, reg_addr_wr, data_wren, data_in[0], clear_codec_i2c_data_wr, codec_i2c_data_wr_reg)

// Bit 1
// Data RD
`GEN_REG_SW_WR1_HW_CLR(axi_clk, axi_reset, 1, 0, `CODEC_I2C_CTRL_REG_ADDR, reg_addr_wr, data_wren, data_in[1], clear_codec_i2c_data_rd, codec_i2c_data_rd_reg)

// Bit 2
// Controller Busy
`GEN_REG_SW_RO_HW_WO(axi_clk, axi_reset, 1'b0, 1'b1, controller_busy, controller_busy_reg)

// Bit 3
// CODEC Initialization Done
// This bit gets cleared by the SW when it writes a 1'b1
`GEN_REG_SW_RWC1_HW_WO(axi_clk, axi_reset, 1, 0, codec_i2c_ctrl_reg_wr_en, data_in[3],  codec_init_done, codec_init_done_reg)

// Bit 4
// Data In Valid
// This bit gets cleared by the SW when it writes a 1'b1
`GEN_REG_SW_RWC1_HW_WO(axi_clk, axi_reset, 1, 0, codec_i2c_ctrl_reg_wr_en, data_in[4],  update_codec_i2c_rd_data, data_in_valid_reg)

// Bit 5
// Missed ACK
// This bit gets cleared by the SW when it writes a 1'b1
`GEN_REG_SW_RWC1_HW_WO(axi_clk, axi_reset, 1, 0, codec_i2c_ctrl_reg_wr_en, data_in[5],  missed_ack, missed_ack_reg)

///////////////////////////////////////
// Address 1
// codec_i2c_addr
///////////////////////////////////////
reg   [31:0] codec_i2c_addr_reg;
assign codec_i2c_addr = codec_i2c_addr_reg;

`GEN_REG_SW_RW(axi_clk, axi_reset, 0, `CODEC_I2C_ADDR_REG_ADDR, reg_addr_wr, data_wren, data_in, codec_i2c_addr_reg)

///////////////////////////////////////
// Address 2
// codec_i2c_wr_data
///////////////////////////////////////
reg   [31:0] codec_i2c_wr_data_reg;
assign codec_i2c_wr_data = codec_i2c_wr_data_reg;

`GEN_REG_SW_RW(axi_clk, axi_reset, 0, `CODEC_I2C_WR_DATA_REG_ADDR, reg_addr_wr, data_wren, data_in, codec_i2c_wr_data_reg)

///////////////////////////////////////
// Address 3
// codec_i2c_rd_data
///////////////////////////////////////
reg   [31:0] codec_i2c_rd_data_reg;
wire data_rd_reset;
assign data_rd_reset = axi_reset & (~codec_i2c_data_rd_reg);
`GEN_REG_SW_RO_HW_WO(axi_clk, data_rd_reset, 32'hcafecafe, update_codec_i2c_rd_data, codec_i2c_rd_data, codec_i2c_rd_data_reg)

///////////////////////////////////////
// Address 4
// misc_data_0
///////////////////////////////////////
reg   [31:0] misc_data_0;

`GEN_REG_SW_RW(axi_clk, axi_reset, 32'habcdabcd, `MISC_DATA_0_REG_ADDR, reg_addr_wr, data_wren, data_in, misc_data_0)

///////////////////////////////////////
// Address 5
// misc_data_1
///////////////////////////////////////
reg   [31:0] misc_data_1;

`GEN_REG_SW_RW(axi_clk, axi_reset, 32'hdeaddddd, `MISC_DATA_1_REG_ADDR, reg_addr_wr, data_wren, data_in, misc_data_1)

///////////////////////////////////////
// Address 6
// misc_data_2
///////////////////////////////////////
reg   [31:0] misc_data_2;

`GEN_REG_SW_RW(axi_clk, axi_reset, 0, `MISC_DATA_2_REG_ADDR, reg_addr_wr, data_wren, data_in, misc_data_2)



////////////////////////////////////////
// Data Read Logic
////////////////////////////////////////
assign data_out = reg_data_out;

always_comb
	begin
	      // Address decoding for reading registers
	      case ( reg_addr_rd )
	        `CODEC_I2C_CTRL_REG_ADDR     : reg_data_out = codec_i2c_ctrl_reg;
	        `CODEC_I2C_ADDR_REG_ADDR    : reg_data_out = codec_i2c_addr_reg;
	        `CODEC_I2C_WR_DATA_REG_ADDR : reg_data_out = codec_i2c_wr_data_reg;
	        `CODEC_I2C_RD_DATA_REG_ADDR : reg_data_out = codec_i2c_rd_data_reg;
	        `MISC_DATA_0_REG_ADDR       : reg_data_out = misc_data_0;
	        `MISC_DATA_1_REG_ADDR       : reg_data_out = misc_data_1;
	        `MISC_DATA_2_REG_ADDR       : reg_data_out = misc_data_2;
	        default : reg_data_out = 32'hdeadbeef;
	      endcase
	end

endmodule