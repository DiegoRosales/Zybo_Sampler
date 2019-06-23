#ifndef SAMPLER_H
#define SAMPLER_H

#include "jsmn.h"

#define ENABLE_FREERTOS_MALLOC 1

#ifdef ENABLE_FREERTOS_MALLOC
    #if( ENABLE_FREERTOS_MALLOC == 1)
        #include "FreeRTOS.h"
        #define sampler_malloc pvPortMalloc
        #define sampler_free   vPortFree
    #else
        #define sampler_malloc malloc
        #define sampler_free   free
    #endif
#endif

#define SAMPLER_BASE_ADDR     XPAR_AUDIO_SAMPLER_INST_AXI_LITE_SLAVE_BASEADDR
#define SAMPLER_DMA_BASE_ADDR SAMPLER_BASE_ADDR + (0x1000)
#define MAX_VOICES 4

// Direct access to the Sampler control register
#define SAMPLER_CONTROL_REGISTER_ACCESS ((volatile SAMPLER_REGISTERS_t *)(SAMPLER_BASE_ADDR))
#define SAMPLER_DMA_REGISTER_ACCESS     ((volatile SAMPLER_DMA_REGISTERS_t *)(SAMPLER_DMA_BASE_ADDR))

// Shortcuts for the Sampler Control Access
#define SAMPLER_CONTROL_START_BIT 0
#define SAMPLER_CONTROL_STOP_BIT  1
#define SAMPLER_CONTROL_START     ( 1 << SAMPLER_CONTROL_START_BIT )
#define SAMPLER_CONTROL_STOP      ( 1 << SAMPLER_CONTROL_STOP_BIT  )


// Endinaness conversion

// 12_34 -> 34_12
#define TOGGLE_ENDIAN_16(__DATA__)( ( (__DATA__ & 0xff00) >> 8 ) | ( (__DATA__ & 0xff  ) << 8 ) )

// 12_34_56_78 -> 78_56_34_12
#define TOGGLE_ENDIAN_32(__DATA__) (( ( __DATA__ & 0xff000000) >> 24 ) | ( ( __DATA__ & 0xff0000  ) >> 8  ) | ( ( __DATA__ & 0xff00    ) << 8  ) | ( ( __DATA__ & 0xff      ) << 24 ))                                    

// Instrument information
#define MAX_INST_FILE_SIZE  20000     // 20k Characters for the json file
#define MAX_SAMPLE_SIZE     0x1F00000 // 32MB
#define MAX_NUM_OF_KEYS     128       // The MIDI spec allows for 128 keys
#define MAX_NUM_OF_VELOCITY 128       // 7 bits of veolcity information according to the MIDI specification
// Tokens
#define MAX_CHAR_IN_TOKEN_STR        256
#define NUM_OF_SAMPLE_JSON_MEMBERS   3
#define INSTRUMENT_NAME_TOKEN_STR    "instrument_name"
#define INSTRUMENT_SAMPLES_TOKEN_STR "samples"
#define SAMPLE_VEL_MIN_TOKEN_STR     "velocity_min"
#define SAMPLE_VEL_MAX_TOKEN_STR     "velocity_max"
#define SAMPLE_PATH_TOKEN_STR        "sample_file"
// WAVE Tokens
#define RIFF_ASCII_TOKEN   0x46464952 // ASCII String == "RIFF"
#define FORMAT_ASCII_TOKEN 0x45564157 // ASCII String == "WAVE"
#define FMT_ASCII_TOKEN    0x20746d66 // ASCII String == "fmt "
#define DATA_ASCII_TOKEN   0x61746164 // ASCII String == "data"

#define GET_SAMPLER_FULL_ADDR(ADDR) ( SAMPLER_BASE_ADDR + (ADDR * 4) )


/////////////////////////////////////////////////////////////////////////////////////////////
//  _   _               _                          ____            _     _                
// | | | | __ _ _ __ __| |_      ____ _ _ __ ___  |  _ \ ___  __ _(_)___| |_ ___ _ __ ___ 
// | |_| |/ _` | '__/ _` \ \ /\ / / _` | '__/ _ \ | |_) / _ \/ _` | / __| __/ _ \ '__/ __|
// |  _  | (_| | | | (_| |\ V  V / (_| | | |  __/ |  _ <  __/ (_| | \__ \ ||  __/ |  \__ \
// |_| |_|\__,_|_|  \__,_| \_/\_/ \__,_|_|  \___| |_| \_\___|\__, |_|___/\__\___|_|  |___/
//
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


///////////////////////////////////////////////////////////////////////////////////////////////
//  ____         __ _                            ____            _     _                
// / ___|  ___  / _| |___      ____ _ _ __ ___  |  _ \ ___  __ _(_)___| |_ ___ _ __ ___ 
// \___ \ / _ \| |_| __\ \ /\ / / _` | '__/ _ \ | |_) / _ \/ _` | / __| __/ _ \ '__/ __|
//  ___) | (_) |  _| |_ \ V  V / (_| | | |  __/ |  _ <  __/ (_| | \__ \ ||  __/ |  \__ \
// |____/ \___/|_|  \__| \_/\_/ \__,_|_|  \___| |_| \_\___|\__, |_|___/\__\___|_|  |___/
//                                                         |___/                        
///////////////////////////////////////////////////////////////////////////////////////////////

typedef struct {
    uint16_t voice_is_active;
    uint16_t previous_voice_slot;
    uint16_t next_voice_slot;
    uint16_t slot_is_last;
} VOICE_TRK_t;

//////////////////////////////////////////
// Voice Information Data Structure
// This data structure will be accessed by
// the DMA engine to know where to start
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

////////////////////////////////////////////////////////////
// Sample information (RIFF/WAV)
////////////////////////////////////////////////////////////


typedef struct {
    uint32_t ChunkID;   // Big Endian
    uint32_t ChunkSize; // Little Endian
} WAVE_BASE_CHUNK_t;

typedef struct {
    WAVE_BASE_CHUNK_t BaseChunk; // ID ("RIFF") and Size
    uint32_t          Format;    // Contains the letters "WAVE" (0x57415645 big-endian form)
} RIFF_DESCRIPTOR_CHUNK_t;

typedef struct {
    WAVE_BASE_CHUNK_t BaseChunk;     // ID ("fmt ") and Size
    uint16_t          AudioFormat;   // (little endian) | PCM = 1 (i.e. Linear quantization). Values other than 1 indicate some form of compression
    uint16_t          NumChannels;   // (little endian) | Mono = 1, Stereo = 2, etc.
    uint32_t          SampleRate;    // (little endian) | 8000, 44100, etc.
    uint32_t          ByteRate;      // (little endian) | == SampleRate * NumChannels * BitsPerSample/8
    uint16_t          BlockAlign;    // (little endian) | == NumChannels * BitsPerSample/8. The number of bytes for one sample including all channels. I wonder what happens when this number isn't an integer?
    uint16_t          BitsPerSample; // (little endian) | 8 bits = 8, 16 bits = 16, etc.
} FORMAT_DESCRIPTOR_CHUNK_t;

// Canonical RIFF data structure
typedef struct {
    // RIFF Descriptor
    RIFF_DESCRIPTOR_CHUNK_t   RiffDescriptor;          // "RIFF"
    // Format Descriptor
    FORMAT_DESCRIPTOR_CHUNK_t FormatDescriptor;        // (little endian) | 4 + (8 + SubChunk1Size) + (8 + SubChunk2Size) 
} WAVE_FORMAT_t;

typedef struct {
    uint16_t audio_format;       // PCM = 1 (i.e. Linear quantization). Values other than 1 indicate some form of compression
    uint16_t number_of_channels; // Mono = 1, Stereo = 2, etc.
    uint32_t sample_rate;        // 8000, 44100, etc.
    uint32_t byte_rate;          // == SampleRate * NumChannels * BitsPerSample/8
    uint16_t block_align;        // == NumChannels * BitsPerSample/8. The number of bytes for one sample including all channels. I wonder what happens when this number isn't an integer?
    uint16_t bits_per_sample;    // 8 bits = 8, 16 bits = 16, etc.
    uint32_t audio_data_size;    // Size of the actual audio data
    uint8_t *data_start_ptr;     // Memory location where the audio data starts
} SAMPLE_FORMAT_t; // Note. Raw data is little endian

////////////////////////////////////////////////////////////
// Instrument information
////////////////////////////////////////////////////////////

typedef struct {
    uint8_t          current_status;                     // 1 = Currently in playback, 0 = Idle
    uint8_t          current_slot;                       // Current slot
    uint8_t          velocity_min;                       // Lower end of the velocity curve
    uint8_t          velocity_max;                       // Higher end of the velocity curve
    uint32_t         sample_addr;                        // Address of the sample that matches the Key+Velocity
    size_t           sample_size;                        // Size of the sample that matches the Key+Velocity
    uint8_t          sample_present;                     // A sample is present
    uint8_t          sample_path[MAX_CHAR_IN_TOKEN_STR]; // Path of the sample relative to the information file
    uint8_t         *sample_buffer;                      // Pointer to the sample buffer where the sample will be loaded
    SAMPLE_FORMAT_t  sample_format;                      // The sample format
} KEY_VOICE_INFORMATION_t;

typedef struct {
    uint8_t                  number_of_velocity_ranges; // Number of velocity ranges
    KEY_VOICE_INFORMATION_t  *key_voice_information[MAX_NUM_OF_VELOCITY];     // Pointer to the first key voice information (the lowest velocity)
} KEY_INFORMATION_t;

typedef struct {
    uint8_t            instrument_name[MAX_CHAR_IN_TOKEN_STR]; // 256 Characters
    uint8_t            instrument_loaded;                      // Indicates that the instrument has been loaded
    uint32_t           total_size;                             // Indicates the memory consumption for the instrument
    uint32_t           total_keys;                             // Indicates the number of keys loaded
    KEY_INFORMATION_t *key_information[MAX_NUM_OF_KEYS];       // Pointer to the key information of key 0
} INSTRUMENT_INFORMATION_t;


// This structure is used to create the lookup table to correlate the JSON note names with the MIDI note numbers
typedef struct {
    uint8_t note_name[4]; // Example: "C3_S" (C3 Sharp)
    uint8_t note_number;  // Example: 49
} NOTE_LUT_STRUCT_t;

uint32_t SamplerRegWr(uint32_t addr, uint32_t value, uint32_t check);
uint32_t SamplerRegRd(uint32_t addr);


uint16_t get_available_voice_slot( void );
void     release_slot( uint16_t slot );
uint32_t stop_voice_playback( uint32_t voice_slot_number );
uint32_t start_voice_playback( uint32_t sample_addr, uint32_t sample_size );

uint32_t get_sampler_version();

void sampler_init ( void );

uint8_t get_json_midi_note_number( jsmntok_t *tok, uint8_t *instrument_info_buffer );
uint8_t get_midi_note_number( char *note_name );

uint32_t stop_all( INSTRUMENT_INFORMATION_t *instrument_information );
uint32_t play_instrument_key( uint8_t key, uint8_t velocity, INSTRUMENT_INFORMATION_t *instrument_information );

KEY_VOICE_INFORMATION_t *init_voice_information();
KEY_INFORMATION_t * init_key_information();
INSTRUMENT_INFORMATION_t* init_instrument_information();

uint32_t decode_instrument_information( uint8_t *instrument_info_buffer, INSTRUMENT_INFORMATION_t *instrument_info );
uint32_t load_sample_information( INSTRUMENT_INFORMATION_t *instrument_information );
uint32_t get_riff_information( uint8_t *sample_buffer, size_t sample_size, SAMPLE_FORMAT_t *riff_information );
uint32_t realign_audio_data( KEY_VOICE_INFORMATION_t *voice_information );

#endif
