module codec_registers (

    ////////////////////////////////
    //////// AXI CONTROLLER ////////
    // Clock and Reset
    input  wire        axi_clk,
    input  wire        axi_reset,

    // Data signals
    input  wire [31:0] data_in,
    output wire [31:0] data_out,
    input  wire [5:0]  reg_addr,
    input  wire        data_wren,
    input  wire [3:0]  byte_enable,

    // Signals from the design
    input wire        clear_codec_i2c_data_wr,
    input wire        clear_codec_i2c_data_rd,
    input wire [31:0] codec_i2c_rd_data,
    input wire        update_codec_i2c_rd_data

);

`include "register_params.inc"

reg [31:0] reg_data_out;

logic [31:0] codec_i2c_ctrl_reg;

// codec_i2c_ctrl_reg
// Address 0
// Bit 0
reg codec_i2c_data_wr;
`GEN_REG_SW_WR1_HW_CLR(axi_clk, axi_reset, 1, 0, 6'h00, reg_addr, data_wren, data_in[0], clear_codec_i2c_data_wr, codec_i2c_data_wr)

// Bit 1
reg codec_i2c_data_rd;
`GEN_REG_SW_WR1_HW_CLR(axi_clk, axi_reset, 1, 0, 6'h00, reg_addr, data_wren, data_in[1], clear_codec_i2c_data_rd, codec_i2c_data_rd)

// codec_i2c_addr
// Address 1
reg   [31:0] codec_i2c_addr_reg;
`GEN_REG_SW_RW(axi_clk, axi_reset, 0, 6'h01, reg_addr, data_wren, data_in[31:0], codec_i2c_addr_reg)

// codec_i2c_wr_data
// Address 2
reg   [31:0] codec_i2c_wr_data_reg;
`GEN_REG_SW_RW(axi_clk, axi_reset, 0, 6'h02, reg_addr, data_wren, data_in[31:0], codec_i2c_wr_data_reg)

// codec_i2c_wr_data
// Address 3
reg   [31:0] codec_i2c_rd_data_reg;
`GEN_REG_SW_RO_HW_WO(axi_clk, axi_reset, 0, update_codec_i2c_rd_data, codec_i2c_rd_data, codec_i2c_rd_data_reg)


assign codec_i2c_ctrl_reg[0]    = codec_i2c_data_wr;
assign codec_i2c_ctrl_reg[1]    = codec_i2c_data_rd;
assign codec_i2c_ctrl_reg[31:2] = {30{1'b1}};

assign data_out                 = reg_data_out;

always @(*)
	begin
	      // Address decoding for reading registers
	      case ( reg_addr )
	        6'h00   : reg_data_out <= codec_i2c_ctrl_reg;
	        6'h01   : reg_data_out <= codec_i2c_addr_reg;
	        6'h02   : reg_data_out <= codec_i2c_wr_data_reg;
	        6'h03   : reg_data_out <= codec_i2c_rd_data_reg;
	        //6'h04   : reg_data_out <= slv_reg4;
	        //6'h05   : reg_data_out <= slv_reg5;
	        //6'h06   : reg_data_out <= slv_reg6;
	        //6'h07   : reg_data_out <= slv_reg7;
	        //6'h08   : reg_data_out <= slv_reg8;
	        //6'h09   : reg_data_out <= slv_reg9;
	        //6'h0A   : reg_data_out <= slv_reg10;
	        //6'h0B   : reg_data_out <= slv_reg11;
	        //6'h0C   : reg_data_out <= slv_reg12;
	        //6'h0D   : reg_data_out <= slv_reg13;
	        //6'h0E   : reg_data_out <= slv_reg14;
	        //6'h0F   : reg_data_out <= slv_reg15;
	        //6'h10   : reg_data_out <= slv_reg16;
	        //6'h11   : reg_data_out <= slv_reg17;
	        //6'h12   : reg_data_out <= slv_reg18;
	        //6'h13   : reg_data_out <= slv_reg19;
	        //6'h14   : reg_data_out <= slv_reg20;
	        //6'h15   : reg_data_out <= slv_reg21;
	        //6'h16   : reg_data_out <= slv_reg22;
	        //6'h17   : reg_data_out <= slv_reg23;
	        //6'h18   : reg_data_out <= slv_reg24;
	        //6'h19   : reg_data_out <= slv_reg25;
	        //6'h1A   : reg_data_out <= slv_reg26;
	        //6'h1B   : reg_data_out <= slv_reg27;
	        //6'h1C   : reg_data_out <= slv_reg28;
	        //6'h1D   : reg_data_out <= slv_reg29;
	        //6'h1E   : reg_data_out <= slv_reg30;
	        //6'h1F   : reg_data_out <= slv_reg31;
	        //6'h20   : reg_data_out <= slv_reg32;
	        //6'h21   : reg_data_out <= slv_reg33;
	        //6'h22   : reg_data_out <= slv_reg34;
	        //6'h23   : reg_data_out <= slv_reg35;
	        //6'h24   : reg_data_out <= slv_reg36;
	        //6'h25   : reg_data_out <= slv_reg37;
	        //6'h26   : reg_data_out <= slv_reg38;
	        //6'h27   : reg_data_out <= slv_reg39;
	        default : reg_data_out <= 32'hdeadbeef;
	      endcase
	end

endmodule