///////////////////////////////////////////////////////////////
// DMA Registers
///////////////////////////////////////////////////////////////
// |--------------------------|
// | CONTROL/MISC REGISTERS   |
// |         [10:0]           |
// |==========================|
// | DMA ADDRESS REG 0        |
// |--------------------------|
// | DMA START/STOP REG 0     |
// |==========================|
// | DMA ADDRESS REG 1        |
// |--------------------------|
// | DMA START/STOP REG 1     |
// |==========================|
// | DMA ADDRESS REG n        |
// |--------------------------|
// | DMA START/STOP REG n     |
// |--------------------------|
///////////////////////////////////////////////////////////////

`define SAMPLER_VERSION 32'h0000_0001

module sampler_dma_registers #(
	parameter MAX_VOICES = 4
) (

    ////////////////////////////////
    //////// AXI CONTROLLER ////////
    // Clock and Reset
    input  wire        axi_clk,
    input  wire        axi_reset,

    // Data signals
    input  wire [31:0] data_in,
    output wire [31:0] data_out,
    input  wire [9:0]  reg_addr_wr,
	input  wire [9:0]  reg_addr_rd,
    input  wire        data_wren,
    input  wire [3:0]  byte_enable,

    // Signals from the design
	output wire [ 31 : 0 ] dma_control[ MAX_VOICES - 1 : 0 ],
	output wire [ 31 : 0 ] dma_base_addr[ MAX_VOICES - 1 : 0 ]
);

// function called clogb2 that returns an integer which has the 
// value of the ceiling of the log base 2.                      
function integer clogb2 (input integer bit_depth);              
begin                                                           
	for(clogb2=0; bit_depth>0; clogb2=clogb2+1)                   
		bit_depth = bit_depth >> 1;                                 
	end                                                           
endfunction              

//////////////////////////////////////
// Local Parameters
//////////////////////////////////////

// Control Register Parameters
localparam NUM_OF_CONTROL_REG      = 'h10; // 0 .. 15
localparam NUM_OF_CONTROL_REG_BITS = clogb2( NUM_OF_CONTROL_REG - 1 );
// DMA Register Parameters
localparam DMA_START_ADDR          = NUM_OF_CONTROL_REG;
localparam DMA_END_ADDR            = ( DMA_START_ADDR + ( MAX_VOICES * 2 ) ) - 1;
localparam NUM_OF_DMA_REG_BITS     = clogb2( MAX_VOICES - 1 ); // Get the number of bits needed to address all DMA registers


//////////////////////////////////////
// Signals/Registers
//////////////////////////////////////

// DMA Address and Stream control
reg  [ 31 : 0 ] dma_base_addr_reg[ MAX_VOICES - 1 : 0 ];
reg  [ 31 : 0 ] dma_control_reg[ MAX_VOICES - 1 : 0 ];
wire [ 31 : 0 ] dma_reg_data_out;

// Control Registers
reg   [ 31 : 0 ] control_reg[ NUM_OF_CONTROL_REG - 1 : 0 ];
logic [ 31 : 0 ] control_reg_data_out;

// Address Arbiter signals
wire                                    rd_addr_is_dma_reg;
wire                                    rd_addr_is_base_addr_reg;
wire                                    wr_addr_is_base_addr_reg;
wire [ NUM_OF_DMA_REG_BITS - 1 : 0 ]    wr_dma_reg_num; // DMA
wire [ NUM_OF_DMA_REG_BITS - 1 : 0 ]    rd_dma_reg_num; // DMA
wire [ NUM_OF_CONTROL_REG_BITS - 1 : 0 ] wr_control_reg_num; // Control
wire [ NUM_OF_CONTROL_REG_BITS - 1 : 0 ] rd_control_reg_num; // Control


/////////////////////
// Address Arbiter
/////////////////////
assign rd_addr_is_dma_reg = ( ( reg_addr_rd >= DMA_START_ADDR ) & ( reg_addr_rd <= DMA_END_ADDR ) );
assign rd_addr_is_base_addr_reg = ( reg_addr_rd[0] == 1'b0 );
assign wr_addr_is_base_addr_reg = ( reg_addr_wr[0] == 1'b0 );

// Get the register number
assign wr_dma_reg_num = reg_addr_wr[ NUM_OF_DMA_REG_BITS : 1 ];
assign rd_dma_reg_num = reg_addr_rd[ NUM_OF_DMA_REG_BITS : 1 ];

// Get the control register number
assign wr_control_reg_num = reg_addr_wr[ NUM_OF_CONTROL_REG_BITS - 1 : 0 ];
assign rd_control_reg_num = reg_addr_rd[ NUM_OF_CONTROL_REG_BITS - 1 : 0 ];

//////////////////////////////////////
// DMA Control and Misc Registers
//////////////////////////////////////

always_comb begin
	case ( rd_control_reg_num )
	0: control_reg_data_out = `SAMPLER_VERSION; // TODO: Create a version
	1: control_reg_data_out = MAX_VOICES;
	2: control_reg_data_out = DMA_START_ADDR;
	default: control_reg_data_out = 32'hbeefdead;
	endcase
end

///////////////////////////////////////////////
// DMA Address and Stream Control Registers
///////////////////////////////////////////////
// Output
assign dma_reg_data_out = ( rd_addr_is_base_addr_reg == 1'b1 ) ? dma_base_addr_reg[ rd_dma_reg_num ] : dma_control_reg[ rd_dma_reg_num ];
assign dma_base_addr = dma_base_addr_reg;
assign dma_control     = dma_control_reg;
// Input
always_ff @(posedge axi_clk or negedge axi_reset) begin
	if ( ~axi_reset ) begin
		dma_base_addr_reg <= '{default:0};
		dma_control_reg   <= '{default:0};
	end
	else begin
		if ( rd_addr_is_dma_reg == 1'b1 ) begin
			// 0, 2, 4, ...
			if ( wr_addr_is_base_addr_reg == 1'b1 ) begin
				dma_base_addr_reg[ wr_dma_reg_num ] <= data_in;
			end
			// 1, 3, 5, 7, ...
			else begin
				dma_control_reg[ wr_dma_reg_num ] <= data_in;
			end			
		end	
	end
end



////////////////////////////////////////
// Data Read Logic
////////////////////////////////////////
assign data_out = (rd_addr_is_dma_reg == 1'b1) ? dma_reg_data_out : control_reg_data_out;


endmodule