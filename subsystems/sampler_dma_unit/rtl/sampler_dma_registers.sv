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

`define SAMPLER_VERSION 32'h0001_0001

module sampler_dma_registers #(
    parameter         MAX_VOICES        = 64,
    parameter integer OPT_MEM_ADDR_BITS = 10
) (

    ////////////////////////////////
    //////// AXI CONTROLLER ////////
    // Clock and Reset
    input wire clk,
    input wire reset_n,

    // Data signals
    input  wire [ 31 : 0 ]                    data_in,
    output wire [ 31 : 0 ]                    data_out,
    input  wire [ OPT_MEM_ADDR_BITS - 1 : 0 ] reg_addr_wr,
    input  wire [ OPT_MEM_ADDR_BITS - 1 : 0 ] reg_addr_rd,
    input  wire                               data_wren,

    // BRAM Signals for port B
    input  wire             bram_B_we,
    input  wire [ 5 : 0 ]   bram_B_addr,
    input  wire [ 127 : 0 ] bram_B_din,
    output wire [ 127 : 0 ] bram_B_dout,

    // Output Control Signals
    output wire start,
    output wire stop
    
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
localparam BRAM_DEPTH              = 256;
localparam NUM_OF_BRAM_REG_BITS    = clogb2( BRAM_DEPTH - 1 );
localparam BRAM_ADDR_LSB           = 0;
localparam BRAM_ADDR_MSB           = NUM_OF_BRAM_REG_BITS + BRAM_ADDR_LSB;
localparam BRAM_START_ADDR         = 12'b0100_0000_0000; // 0x400
localparam BRAM_END_ADDR           = BRAM_START_ADDR + BRAM_DEPTH - 1;
// DMA Register Address
localparam DMA_BASE_ADDR_REG = 1'b0;
localparam DMA_CONTROL_REG   = 1'b1;
localparam DMA_STATUS_REG    = 2'b10;
localparam DMA_CURR_ADDR_REG = 2'b11;


//////////////////////////////////////
// Signals/Registers
//////////////////////////////////////

// DMA Address and Stream control
wire  [ 31 : 0 ] dma_bram_data_out;

// Control Registers
logic [ 31 : 0 ] control_reg_data_out;
reg   [ 1 : 0 ]  control_reg;

// Address Arbiter signals
wire wr_addr_is_control_reg;
wire rd_addr_is_control_reg;
wire wr_addr_is_bram_reg;
wire rd_addr_is_bram_reg;

// Base Address Register
wire wr_addr_is_dma_base_addr_reg; 
// Control Register
wire wr_addr_is_dma_control_reg;
// Status Register
wire wr_addr_is_dma_status_reg;
// Current Address Register
wire wr_addr_is_dma_curr_addr_reg;

wire [ NUM_OF_BRAM_REG_BITS - 1 : 0 ]    wr_bram_reg_addr;   // BRAM
wire [ NUM_OF_BRAM_REG_BITS - 1 : 0 ]    rd_bram_reg_addr;   // BRAM
wire [ NUM_OF_CONTROL_REG_BITS - 1 : 0 ] wr_control_reg_num; // Control
wire [ NUM_OF_CONTROL_REG_BITS - 1 : 0 ] rd_control_reg_num; // Control

wire [ NUM_OF_BRAM_REG_BITS - 1 : 0 ]    dma_bram_addr;
wire                                     dma_bram_we;

////////////////////////////////////////
// Data Read Logic
////////////////////////////////////////
assign data_out = (rd_addr_is_bram_reg == 1'b1) ? dma_bram_data_out : ( rd_addr_is_control_reg == 1'b1 ) ? control_reg_data_out : 32'hdeaddead;

assign start = control_reg[0];
assign stop  = control_reg[1];

/////////////////////
// Address Arbiter
/////////////////////
// Control Rd/Wr
assign wr_addr_is_control_reg       = ( reg_addr_wr < BRAM_START_ADDR);
assign rd_addr_is_control_reg       = ( reg_addr_rd < BRAM_START_ADDR);

// DMA Rd/Wr
assign wr_addr_is_bram_reg          = ( ( reg_addr_wr >= BRAM_START_ADDR ) & ( reg_addr_wr <= BRAM_END_ADDR ) );
assign rd_addr_is_bram_reg          = ( ( reg_addr_rd >= BRAM_START_ADDR ) & ( reg_addr_rd <= BRAM_END_ADDR ) );

// Get the BRAM register address
assign wr_bram_reg_addr = reg_addr_wr[ BRAM_ADDR_MSB - 1 : BRAM_ADDR_LSB ];
assign rd_bram_reg_addr = reg_addr_rd[ BRAM_ADDR_MSB - 1 : BRAM_ADDR_LSB ];

// Get the control register number
assign wr_control_reg_num = reg_addr_wr[ NUM_OF_CONTROL_REG_BITS - 1 : 0 ];
assign rd_control_reg_num = reg_addr_rd[ NUM_OF_CONTROL_REG_BITS - 1 : 0 ];


// BRAM Address logic
assign dma_bram_addr = (data_wren & wr_addr_is_bram_reg)  ? wr_bram_reg_addr :      // If it's Write
                        rd_addr_is_bram_reg               ? rd_bram_reg_addr : 'h0; // If it's read

assign dma_bram_we   = (data_wren & wr_addr_is_bram_reg);

//////////////////////////////////////
// DMA Control, Status and Misc Registers
//////////////////////////////////////

always_comb begin
    case ( rd_control_reg_num )
        0: control_reg_data_out = `SAMPLER_VERSION; // TODO: Create version control
        1: control_reg_data_out = MAX_VOICES;
        2: control_reg_data_out = BRAM_START_ADDR;
        3: control_reg_data_out = BRAM_END_ADDR;
        4: control_reg_data_out = control_reg;
        default: control_reg_data_out = 32'hbeefdead;
    endcase
end

always_ff @(posedge clk, negedge reset_n) begin
    if ( ~reset_n ) begin
        control_reg <= 'h2;
    end
    else begin

        control_reg <= control_reg;

        if ( data_wren & wr_addr_is_control_reg ) begin

            if ( wr_control_reg_num == 4 ) begin
                control_reg <= data_in[ 1 : 0 ];
            end

        end
    end
end

///////////////////////////////////////////////
// BRAM Registers
///////////////////////////////////////////////

bram_dualport_i32x256_o128x64
bram_dualport_i32x256_o128x64_inst (
    // Port A
    .clka  ( clk               ), 
    .wea   ( {4{dma_bram_we}}  ), 
    .addra ( dma_bram_addr     ), 
    .dina  ( data_in           ), 
    .douta ( dma_bram_data_out ), 
    // Port B
    .clkb  ( clk             ), 
    .web   ( {16{bram_B_we}} ), 
    .addrb ( bram_B_addr     ), 
    .dinb  ( bram_B_din      ),
    .doutb ( bram_B_dout     )
);






endmodule