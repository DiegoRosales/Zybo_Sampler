///////////////////////////////////////////////////////////////
// DMA Registers
///////////////////////////////////////////////////////////////
// |--------------------------|
// |         GENERAL          |
// | CONTROL/MISC REGISTERS   |
// |         [9:0]            |
// |==========================|
// | DMA ADDRESS REG 0        |
// |--------------------------|
// | DMA START/STOP REG 0     |
// |--------------------------|
// | DMA STATUS REG 0         |
// |--------------------------|
// | DMA CURRENT ADDR REG 0   |
// |==========================|
// |          ...             |
// |==========================|
// | DMA ADDRESS REG n        |
// |--------------------------|
// | DMA START/STOP REG n     |
// |--------------------------|
// | DMA STATUS REG n         |
// |--------------------------|
// | DMA CURRENT ADDR REG n   |
// |--------------------------|
///////////////////////////////////////////////////////////////

`define SAMPLER_VERSION 32'h0000_0001

module sampler_dma_registers #(
	parameter         MAX_VOICES = 4,
	parameter integer OPT_MEM_ADDR_BITS = 10
) (

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
	output wire [ 31 : 0 ] dma_control[ MAX_VOICES - 1 : 0 ],
	output wire [ 31 : 0 ] dma_base_addr[ MAX_VOICES - 1 : 0 ],
	input  wire [ 31 : 0 ] dma_status[ MAX_VOICES - 1 : 0 ],
	input  wire [ 31 : 0 ] dma_curr_addr[ MAX_VOICES - 1 : 0 ]
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
localparam NUM_OF_DMA_REGS         = 4; // Four registers per DMA voice
localparam TOTAL_NUM_OF_DMA_REGS   = MAX_VOICES * NUM_OF_DMA_REGS; // Total amout of addressable registers
localparam DMA_START_ADDR          = NUM_OF_CONTROL_REG;
localparam DMA_END_ADDR            = DMA_START_ADDR + TOTAL_NUM_OF_DMA_REGS - 1;
localparam NUM_OF_DMA_REG_BITS     = clogb2( TOTAL_NUM_OF_DMA_REGS - 1 ); // Get the number of bits needed to address all DMA registers
// DMA Register Address
localparam DMA_BASE_ADDR_REG = 2'b00;
localparam DMA_CONTROL_REG   = 2'b01;
localparam DMA_STATUS_REG    = 2'b10;
localparam DMA_CURR_ADDR_REG = 2'b11;


//////////////////////////////////////
// Signals/Registers
//////////////////////////////////////

// DMA Address and Stream control
reg   [ 31 : 0 ] dma_base_addr_reg[ MAX_VOICES - 1 : 0 ];
reg   [ 31 : 0 ] dma_control_reg[ MAX_VOICES - 1 : 0 ];
reg   [ 31 : 0 ] dma_status_reg[ MAX_VOICES - 1 : 0 ];
reg   [ 31 : 0 ] dma_curr_addr_reg[ MAX_VOICES - 1 : 0 ];
logic [ 31 : 0 ] dma_reg_data_out;

// Control Registers
reg   [ 31 : 0 ] control_reg[ NUM_OF_CONTROL_REG - 1 : 0 ];
logic [ 31 : 0 ] control_reg_data_out;

// Address Arbiter signals
wire                                    wr_addr_is_control_reg;
wire                                    rd_addr_is_control_reg;
wire                                    wr_addr_is_dma_reg;
wire                                    rd_addr_is_dma_reg;

// Base Address Register
wire wr_addr_is_dma_base_addr_reg; 
// Control Register
wire wr_addr_is_dma_control_reg;
// Status Register
wire wr_addr_is_dma_status_reg;
// Current Address Register
wire wr_addr_is_dma_curr_addr_reg;

wire [ NUM_OF_DMA_REG_BITS - 1 : 0 ]    wr_dma_reg_num; // DMA
wire [ NUM_OF_DMA_REG_BITS - 1 : 0 ]    rd_dma_reg_num; // DMA
wire [ NUM_OF_CONTROL_REG_BITS - 1 : 0 ] wr_control_reg_num; // Control
wire [ NUM_OF_CONTROL_REG_BITS - 1 : 0 ] rd_control_reg_num; // Control


/////////////////////
// Address Arbiter
/////////////////////
// Write
assign wr_addr_is_control_reg       = ( reg_addr_wr < DMA_START_ADDR);
assign wr_addr_is_dma_reg           = ( ( reg_addr_wr >= DMA_START_ADDR ) & ( reg_addr_wr <= DMA_END_ADDR ) );

// Read
assign rd_addr_is_control_reg       = ( reg_addr_rd < DMA_START_ADDR);
assign rd_addr_is_dma_reg           = ( ( reg_addr_rd >= DMA_START_ADDR ) & ( reg_addr_rd <= DMA_END_ADDR ) );

// Get the DMA register number
assign wr_dma_reg_num = reg_addr_wr[ NUM_OF_DMA_REG_BITS - 1 : 2 ]; // Lower two bits used to address the 4 registers
assign rd_dma_reg_num = reg_addr_rd[ NUM_OF_DMA_REG_BITS - 1 : 2 ]; // Lower two bits used to address the 4 registers

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

// Output to the AXI interface
always_comb begin
	case ( reg_addr_rd[1:0] )
		DMA_BASE_ADDR_REG: dma_reg_data_out = dma_base_addr_reg[ rd_dma_reg_num ]; 
		DMA_CONTROL_REG:   dma_reg_data_out = dma_control_reg[ rd_dma_reg_num ];
		DMA_STATUS_REG:    dma_reg_data_out = dma_status_reg[ rd_dma_reg_num ];
		DMA_CURR_ADDR_REG: dma_reg_data_out = dma_curr_addr_reg[ rd_dma_reg_num ]; 
		default:           dma_reg_data_out = 32'hbeefbeef;
	endcase
end

// Output to the design
assign dma_base_addr    = dma_base_addr_reg;
assign dma_control      = dma_control_reg;

// Input
always_ff @(posedge axi_clk or negedge axi_reset) begin
	if ( ~axi_reset ) begin
		dma_base_addr_reg <= '{default:0};
		dma_control_reg   <= '{default:0};
		dma_status_reg    <= '{default:0};
		dma_curr_addr_reg <= '{default:0};
	end
	else begin
		dma_base_addr_reg <= dma_base_addr_reg;
		dma_control_reg   <= dma_control_reg;
		dma_status_reg    <= dma_status;
		dma_curr_addr_reg <= dma_curr_addr;
		if ( data_wren == 1'b1 && wr_addr_is_dma_reg == 1'b1 ) begin
			case ( reg_addr_wr[1:0] )
				DMA_BASE_ADDR_REG: dma_base_addr_reg[ wr_dma_reg_num ] <= data_in;
				DMA_CONTROL_REG:   dma_control_reg[ wr_dma_reg_num ]   <= data_in;
			endcase		
		end
	end
end



////////////////////////////////////////
// Data Read Logic
////////////////////////////////////////
assign data_out = (rd_addr_is_dma_reg == 1'b1) ? dma_reg_data_out : ( rd_addr_is_control_reg == 1'b1 ) ? control_reg_data_out : 32'hdeaddead;


endmodule