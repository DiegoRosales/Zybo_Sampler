//////////////////////////////////////////////////
// Sampler DMA Controller Register Definition
//////////////////////////////////////////////////

#ifndef _SAMPLER_DMA_CONTROLLER_REGS_H_
#define _SAMPLER_DMA_CONTROLLER_REGS_H_

// Direct access to the Sampler control register
#define SAMPLER_BASE_ADDR               XPAR_SAMPLER_SAMPLER_DMA_AXI4_LITE_INTERFACE_BASEADDR
#define SAMPLER_DMA_BASE_ADDR           SAMPLER_BASE_ADDR + (0x1000)
#define SAMPLER_CONTROL_REGISTER_ACCESS ((volatile SAMPLER_REGISTERS_t *)(SAMPLER_BASE_ADDR))
#define SAMPLER_DMA_REGISTER_ACCESS     ((volatile SAMPLER_DMA_REGISTERS_t *)(SAMPLER_DMA_BASE_ADDR))
#define GET_SAMPLER_FULL_ADDR(ADDR)     ( SAMPLER_BASE_ADDR + (ADDR * 4) )
#define MAX_VOICES            64

/////////////////////////////////////////////////////////////////////////////////////////////
//  _   _               _                          ____            _     _                 //
// | | | | __ _ _ __ __| |_      ____ _ _ __ ___  |  _ \ ___  __ _(_)___| |_ ___ _ __ ___  //
// | |_| |/ _` | '__/ _` \ \ /\ / / _` | '__/ _ \ | |_) / _ \/ _` | / __| __/ _ \ '__/ __| //
// |  _  | (_| | | | (_| |\ V  V / (_| | | |  __/ |  _ <  __/ (_| | \__ \ ||  __/ |  \__ \ //
// |_| |_|\__,_|_|  \__,_| \_/\_/ \__,_|_|  \___| |_| \_\___|\__, |_|___/\__\___|_|  |___/ //
//                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////
// DMA Registers
///////////////////////////////////////////////////////////////
// |--------------------------|
// |         GENERAL          |
// | CONTROL/MISC REGISTERS   |
// |         [9:0]            |
// |==========================|
// |          RSVD            |
// |          ...             |
// |==========================|
// | Sample DMA Reg 0         |
// |--------------------------|
// | Sample DMA Reg 1         |
// |--------------------------|
// | Sample DMA Reg n         |
// |--------------------------|
///////////////////////////////////////////////////////////////

// Misc Control and Status Register (BAR = SAMPLER_BASE_ADDR)
// .----------.-------------.----------------------------.
// | Address  |  Operation  |        Register Name       |
// :----------+-------------+----------------------------:
// |  0x0     |  RO         |  SAMPLER HW VERSION        |
// :----------+-------------+----------------------------:
// |  0x1     |  RO         |  MAX VOICES                |
// :----------+-------------+----------------------------:
// |  0x2     |  RO         |  BRAM START ADDRESS        |
// :----------+-------------+----------------------------:
// |  0x3     |  RO         |  BRAM END ADDRESS          |
// :----------+-------------+----------------------------:
// |  0x4     |  RD/WR      |  RSVD[31:2] | STOP | START |
// '----------'-------------'----------------------------'

// Sample DMA Register (BAR = SAMPLER_BASE_ADDR + BRAM START ADDRESS)
// .-------------.-------------.-----------------------------------------------------------.
// |   Address   |  Operation  |        0      |      1      |      2      |      3        |
// :-------------+-------------+-----------------------------------------------------------:
// |     0x0     |    RD/WR    |                 Sample Current Address [31:0]             |
// :-------------+-------------+-----------------------------------------------------------:
// |     0x1     |    RD/WR    |                   Sample End Address [31:0]               |
// :-------------+-------------+-----------------------------------------------------------:
// |     0x2     |    RD/WR    |  Control[7:0] |   Sample Length [23:0]                    |
// :-------------+-------------+-----------------------------------------------------------:
// |     0x3     |    RD/WR    |          RSVD[15:0]         |     Next Sample[15:0]       |
// '-------------'-------------'-----------------------------------------------------------'



//***********************************************
//***********************************************
// General misc registers
//***********************************************
//***********************************************

/////////////////////////////////
// Sampler Version Register
/////////////////////////////////
typedef union {
    // Individual Fields
    struct {
        uint32_t sampler_version : 32 ; // Bit 31:0
    } field;
    // Complete Value
    uint32_t value;
} SAMPLER_VER_REG_t;

/////////////////////////////////
// Sampler Maximum Number of Voices Register
/////////////////////////////////
typedef union {
    // Individual Fields
    struct {
        uint32_t max_voices : 32 ; // Bit 31:0
    } field;
    // Complete Value
    uint32_t value;
} SAMPLER_MAX_VOICES_REG_t;

/////////////////////////////////
// Sampler Voice Information Start Address
// (address where the FW can write the voice address)
/////////////////////////////////
typedef union {
    // Individual Fields
    struct {
        uint32_t dma_start_addr : 32 ; // Bit 31:0
    } field;
    // Complete Value
    uint32_t value;
} SAMPLER_DMA_CTRL_START_ADDR_REG_t;

/////////////////////////////////
// Sampler Voice Information End Address
/////////////////////////////////
typedef union {
    // Individual Fields
    struct {
        uint32_t dma_end_addr : 32 ; // Bit 31:0
    } field;
    // Complete Value
    uint32_t value;
} SAMPLER_DMA_CTRL_END_ADDR_REG_t;

/////////////////////////////////
// Sampler Control Register
/////////////////////////////////
typedef union {
    // Individual Fields
    struct {
        uint32_t start : 1 ; // Bit 0
        uint32_t stop  : 1 ; // Bit 1
        uint32_t rsvd  : 30; // Bits [31:2]
    } field;
    // Complete Value
    uint32_t value;
} SAMPLER_CONTROL_REG_t;

typedef struct {
    SAMPLER_VER_REG_t                 SAMPLER_VER_REG;                 // Address 0
    SAMPLER_MAX_VOICES_REG_t          SAMPLER_MAX_VOICES_REG;          // Address 1
    SAMPLER_DMA_CTRL_START_ADDR_REG_t SAMPLER_DMA_CTRL_START_ADDR_REG; // Address 2
    SAMPLER_DMA_CTRL_END_ADDR_REG_t   SAMPLER_DMA_CTRL_END_ADDR_REG;   // Address 3
    SAMPLER_CONTROL_REG_t             SAMPLER_CONTROL_REG;             // Address 4
} SAMPLER_REGISTERS_t;

////////////////////////////////////////////////////////////////////

//***********************************************
//***********************************************
// DMA registers
//***********************************************
//***********************************************

////////////////////////////////////
// DMA Start Address
///////////////////////////////////
typedef union {
    // Individual Fields
    struct {
        uint32_t dma_start_addr : 32 ; // Bit 31:0
    } field;
    // Complete Value
    uint32_t value;
} SAMPLER_DMA_START_ADDR_REG_t;

////////////////////////////////////
// DMA End Address
///////////////////////////////////
typedef union {
    // Individual Fields
    struct {
        uint32_t dma_end_addr : 32 ; // Bit 31:0
    } field;
    // Complete Value
    uint32_t value;
} SAMPLER_DMA_END_ADDR_REG_t;

////////////////////////////////////
// DMA Control Bits
///////////////////////////////////
typedef union {
    // Individual Fields
    struct {
        uint32_t dma_len  : 24 ; // Bit [23:0]   // Length in number of samples
        uint32_t valid    : 1  ; // Bit 24       // Sample is valid
        uint32_t last     : 1  ; // Bit 25       // Sample is the last of the loop
        uint32_t rsvd     : 5  ; // Bits [30:26] // Reserved
        uint32_t overflow : 1  ; // Bit 31       // Sampler read all the samples
    } field;
    // Complete Value
    uint32_t value;
} SAMPLER_DMA_CONTROL_REG_t;

////////////////////////////////////
// Next Sample Register
///////////////////////////////////
typedef union {
    // Individual Fields
    // TODO: Put individual bits
    struct {
        uint32_t dma_next_sample : 16 ; // Bit [15:0]
        uint32_t rsvd            : 16 ; // Bit [31:16]
    } field;
    // Complete Value
    uint32_t value;
} SAMPLER_DMA_NEXT_SAMPLE_REG_t;

////////////////////////////////////
// DMA Current Address Register
///////////////////////////////////
typedef union {
    // Individual Fields
    struct {
        uint32_t dma_current_addr : 32 ; // Bit 31:0
    } field;
    // Complete Value
    uint32_t value;
} SAMPLER_DMA_CURRENT_ADDR_REG_t;

typedef struct {
    SAMPLER_DMA_START_ADDR_REG_t  dma_start_addr;  // Address pointing to the sample data
    SAMPLER_DMA_START_ADDR_REG_t  dma_end_addr;    // Address pointing to the end of the sample data
    SAMPLER_DMA_CONTROL_REG_t     dma_control;     // Start/Stop/etc.
    SAMPLER_DMA_NEXT_SAMPLE_REG_t dma_next_sample; // Status register
} SAMPLER_DMA_t;

typedef struct {
    SAMPLER_DMA_t sampler_dma[MAX_VOICES]; // The number of registers depends on the number of voices
} SAMPLER_DMA_REGISTERS_t;

#endif
