#ifndef SAMPLER_H
#define SAMPLER_H

#define SAMPLER_BASE_ADDR     XPAR_AUDIO_SAMPLER_INST_AXI_LITE_SLAVE_BASEADDR
#define SAMPLER_DMA_BASE_ADDR SAMPLER_BASE_ADDR + (0x40)
#define MAX_VOICES 4

// Direct access to the Sampler control register
#define SAMPLER_CONTROL_REGISTER_ACCESS ((volatile SAMPLER_REGISTERS_t *)(SAMPLER_BASE_ADDR))
#define SAMPLER_DMA_REGISTER_ACCESS     ((volatile SAMPLER_DMA_REGISTERS_t *)(SAMPLER_DMA_BASE_ADDR))

// Instrument information
#define MAX_INST_FILE_SIZE  20000 // 20k Characters for the json file
#define MAX_NUM_OF_KEYS     128   // The MIDI spec allows for 128 keys
#define MAX_NUM_OF_VELOCITY 128   // 7 bits of veolcity information according to the MIDI specification
// Tokens
#define MAX_CHAR_IN_TOKEN_STR        256
#define NUM_OF_SAMPLE_JSON_MEMBERS   3
#define INSTRUMENT_NAME_TOKEN_STR    "instrument_name"
#define INSTRUMENT_SAMPLES_TOKEN_STR "samples"
#define SAMPLE_VEL_MIN_TOKEN_STR     "velocity_min"
#define SAMPLE_VEL_MAX_TOKEN_STR     "velocity_max"
#define SAMPLE_PATH_TOKEN_STR        "sample_file"

#define GET_SAMPLER_FULL_ADDR(ADDR) ( SAMPLER_BASE_ADDR + (ADDR * 4) )
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

////////////////////////////////////////////////////////////
// Instrument information
////////////////////////////////////////////////////////////

typedef struct {
    uint8_t  velocity_min;                       // Lower end of the velocity curve
    uint8_t  velocity_max;                       // Higher end of the velocity curve
    uint32_t sample_addr;                        // Address of the sample that matches the Key+Velocity
    uint32_t sample_size;                        // Size of the sample that matches the Key+Velocity
    uint8_t  sample_present;                     // A sample is present
    uint8_t  sample_path[MAX_CHAR_IN_TOKEN_STR]; // Path of the sample relative to the information file
    uint8_t *sample_buffer                       // Pointer to the sample buffer where the sample will be loaded
} KEY_VOICE_INFORMATION_t;

typedef struct {
    uint8_t                  number_of_velocity_ranges; // Number of velocity ranges
    KEY_VOICE_INFORMATION_t  *key_voice_information[MAX_NUM_OF_VELOCITY];     // Pointer to the first key voice information (the lowest velocity)
} KEY_INFORMATION_t;

typedef struct {
    uint8_t           instrument_name[MAX_CHAR_IN_TOKEN_STR]; // 256 Characters
    KEY_INFORMATION_t *key_information[MAX_NUM_OF_KEYS];                     // Pointer to the key information of key 0
} INSTRUMENT_INFORMATION_t;


// This structure is used to create the lookup table to correlate the JSON note names with the MIDI note numbers
typedef struct {
    uint8_t note_name[4]; // Example: "C3_S" (C3 Sharp)
    uint8_t note_number;  // Example: 49
} NOTE_LUT_STRUCT_t;

uint32_t SamplerRegWr(uint32_t addr, uint32_t value, uint32_t check);
uint32_t SamplerRegRd(uint32_t addr);


uint32_t get_available_voice_slot( void );
uint32_t stop_voice_playback( uint32_t voice_slot_number );
uint32_t start_voice_playback( uint32_t sample_addr, uint32_t sample_size );

uint32_t get_sampler_version();

INSTRUMENT_INFORMATION_t* init_instrument_information( uint8_t number_of_keys, uint8_t number_of_velocity_ranges );
uint32_t decode_instrument_information( uint8_t *instrument_info_buffer, INSTRUMENT_INFORMATION_t *instrument_info );

#endif
