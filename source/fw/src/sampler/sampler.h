#ifndef SAMPLER_H
#define SAMPLER_H

#define SAMPLER_BASE_ADDR XPAR_AUDIO_SAMPLER_INST_AXI_LITE_SLAVE_BASEADDR
#define MAX_VOICES 4

// Direct access to the Sampler control register
#define SAMPLER_CONTROL_REGISTER_ACCESS ((volatile SAMPLER_REGISTERS_t *)(SAMPLER_BASE_ADDR))
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
    SAMPLER_VER_REG_t            SAMPLER_VER_REG_REG;            // Address 0
    SAMPLER_MAX_VOICES_REG_t     SAMPLER_MAX_VOICES_REG_REG;     // Address 1
    SAMPLER_DMA_START_ADDR_REG_t SAMPLER_DMA_START_ADDR_REG_REG; // Address 2
} SAMPLER_REGISTERS_t;

typedef struct {
    uint32_t dma_addr; // Address pointing to the voice information
    uint32_t dma_control;
} SAMPLER_DMA_t;

uint32_t SamplerRegWr(uint32_t addr, uint32_t value, uint32_t check);
uint32_t SamplerRegRd(uint32_t addr);

uint32_t get_sampler_version();

#endif