#ifndef SAMPLER_H
#define SAMPLER_H

#define SAMPLER_BASE_ADDR     XPAR_AUDIO_SAMPLER_INST_AXI_LITE_SLAVE_BASEADDR
#define SAMPLER_DMA_BASE_ADDR SAMPLER_BASE_ADDR + 0x10
#define MAX_VOICES 4

// Direct access to the Sampler control register
#define SAMPLER_CONTROL_REGISTER_ACCESS ((volatile SAMPLER_REGISTERS_t *)(SAMPLER_BASE_ADDR))
#define SAMPLER_DMA_REGISTER_ACCESS     ((volatile SAMPLER_DMA_REGISTERS_t *)(SAMPLER_DMA_BASE_ADDR))
//////////////////////////////////////////
// Voice Information Data Structure
//////////////////////////////////////////
// |--------------------------|
// |       START ADDRESS      | [0]
// |==========================|
// |       STREAM LENGTH      | [1]
// |--------------------------|
// |<-------- 32-bit -------->|
//////////////////////////////////////////

typedef struct {
    uint32_t voice_start_addr;
    uint32_t voice_size;
} SAMPLER_VOICE_t;

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
// (sampler address where the FW can write the voice address)
/////////////////////////////////
typedef union {
    // Individual Fields
    struct {
        uint32_t dma_start_addr : 32 ; // Bit 31:0
    } field;
    // Complete Value
    uint32_t value;
} SAMPLER_DMA_START_ADDR_REG_t;

typedef struct {
    SAMPLER_VER_REG_t            SAMPLER_VER_REG;            // Address 0
    SAMPLER_MAX_VOICES_REG_t     SAMPLER_MAX_VOICES_REG;     // Address 1
    SAMPLER_DMA_START_ADDR_REG_t SAMPLER_DMA_START_ADDR_REG; // Address 2
} SAMPLER_REGISTERS_t;


//////////////////////////////////////////////////
////////////////////////////////////
// DMA Information Address
///////////////////////////////////
typedef union {
    // Individual Fields
    struct {
        uint32_t dma_info_addr : 32 ; // Bit 31:0
    } field;
    // Complete Value
    uint32_t value;
} SAMPLER_DMA_INFO_ADDR_REG_t;

////////////////////////////////////
// DMA Control Bits
///////////////////////////////////
typedef union {
    // Individual Fields
    struct {
        uint32_t start : 1 ; // Bit 0
        uint32_t stop  : 1 ; // Bit 1
    } field;
    // Complete Value
    uint32_t value;
} SAMPLER_DMA_CONTROL_REG_t;


typedef struct {
    SAMPLER_DMA_INFO_ADDR_REG_t dma_addr; // Address pointing to the voice information
    SAMPLER_DMA_CONTROL_REG_t   dma_control;
} SAMPLER_DMA_t;

typedef struct {
    SAMPLER_DMA_t sampler_dma[MAX_VOICES]; // The number of registers depends on the number of voices
} SAMPLER_DMA_REGISTERS_t;

uint32_t SamplerRegWr(uint32_t addr, uint32_t value, uint32_t check);
uint32_t SamplerRegRd(uint32_t addr);


uint32_t get_available_voice_slot( void );
uint32_t stop_voice_playback( uint32_t voice_slot_number );
uint32_t start_voice_playback( uint32_t sample_addr, uint32_t sample_size );

uint32_t get_sampler_version();

#endif