// SV Include file

// Decodes a memory write using the provided address
`define DECODE_MEM_WR(ADDR, ADDR_WR, WR) ((ADDR == ADDR_WR) & (WR == 1'b1))


// Generates a Flipflop Register
`define GEN_REG(CLK, RST, REGISTER, DEF_VAL, WR, WR_DATA)\
    always_ff @(posedge CLK or negedge RST) \
        if (~RST) REGISTER <= DEF_VAL; \
        else REGISTER      <= (WR) ? WR_DATA : REGISTER; \

// Generate an AXI register that the sofware sets to 1 and gets cleared by the HW
// CLK     = AXI Clock
// RST     = AXI Reset
// DEF_VAL = Value of the register after reset
// ADDR    = Register Address
// ADDR_WR = AXI Address Signal
// WR      = AXI WR Signal
// REG     = Register Signal
// SET_REG = Signal that sets the register
// CLR_REG = Signal that clears the register
`define GEN_REG_SW_WR1_HW_CLR(CLK, RST, SIZE, DEF_VAL, WR, SET_REG, CLR_REG, REG) \
    logic UPDATE_``REG``; \
    logic [SIZE - 1 : 0] NEXT_``REG``; \
    assign UPDATE_``REG`` = ( WR & SET_REG) | CLR_REG; \
    assign NEXT_``REG``   = ( WR & SET_REG); \
    `GEN_REG(CLK, RST, REG, DEF_VAL, UPDATE_``REG``, NEXT_``REG``)

// Generate an AXI register that the sofware can RD and WR
// CLK     = AXI Clock
// RST     = AXI Reset
// DEF_VAL = Value of the register after reset
// ADDR    = Register Address
// ADDR_WR = AXI Address Signal
// WR      = AXI WR Signal
// WR_DATA = AXI Data to be written
// REG     = Register Signal
`define GEN_REG_SW_RW(CLK, RST, DEF_VAL, MEM_WR, WR_DATA, REG) \
    `GEN_REG(CLK, RST, REG, DEF_VAL, MEM_WR, WR_DATA)

// Generate an AXI register that the hardware can WR and the Software can RD
// CLK     = AXI Clock
// RST     = AXI Reset
// DEF_VAL = Value of the register after reset
// ADDR    = Register Address
// ADDR_WR = AXI Address Signal
// WR      = AXI WR Signal
// WR_DATA = AXI Data to be written
// REG     = Register Signal
`define GEN_REG_SW_RO_HW_WO(CLK, RST, DEF_VAL, WR, WR_DATA, REG) \
    `GEN_REG(CLK, RST, REG, DEF_VAL, WR, WR_DATA)    

// Generate an AXI register that the HW sets to 1 and gets cleared by the SW
// CLK     = AXI Clock
// RST     = AXI Reset
// DEF_VAL = Value of the register after reset
// ADDR    = Register Address
// ADDR_WR = AXI Address Signal
// WR      = AXI WR Signal
// REG     = Register Signal
// SET_REG = Signal that sets the register
// CLR_REG = Signal that clears the register
`define GEN_REG_SW_RWC1_HW_WO(CLK, RST, SIZE, DEF_VAL, WRITE_EN, CLR_REG, SET_REG, REG) \
    logic UPDATE_``REG``; \
    logic [SIZE - 1 : 0] NEXT_``REG``; \
    assign UPDATE_``REG`` = (WRITE_EN & CLR_REG) | SET_REG; \
    assign NEXT_``REG``   = (WRITE_EN & CLR_REG) ? 1'b0 : 1'b1; \
    `GEN_REG(CLK, RST, REG, DEF_VAL, UPDATE_``REG``, NEXT_``REG``)

`define REG_SYNC(CLK1, CLK2, SIZE, IN, OUT, NAME) \
    reg [SIZE - 1 : 0 ] ``NAME``_SYNC1; \
    reg [SIZE - 1 : 0 ] ``NAME``_SYNC2; \
    reg [SIZE - 1 : 0 ] ``NAME``_SYNC3; \
    assign OUT = ``NAME``_SYNC3; \
    always_ff @(posedge CLK1)  ``NAME``_SYNC1 <= IN; \
    always_ff @(posedge CLK1)  ``NAME``_SYNC2 <= ``NAME``_SYNC1; \
    always_ff @(posedge CLK2)  ``NAME``_SYNC3 <= ``NAME``_SYNC2;