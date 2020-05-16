#ifndef __SAMPLER_H__
#define __SAMPLER_H__

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

#include "jsmn_utils.h"

// Enable/disable data realignment
#define ENABLE_SAMPLE_REALIGN 0

// Endinaness conversion
// 12_34 -> 34_12
#define TOGGLE_ENDIAN_16(__DATA__)( ( (__DATA__ & 0xff00) >> 8 ) | ( (__DATA__ & 0xff  ) << 8 ) )

// 12_34_56_78 -> 78_56_34_12
#define TOGGLE_ENDIAN_32(__DATA__) (( ( __DATA__ & 0xff000000) >> 24 ) | ( ( __DATA__ & 0xff0000  ) >> 8  ) | ( ( __DATA__ & 0xff00    ) << 8  ) | ( ( __DATA__ & 0xff      ) << 24 ))                                    

// Instrument information
#define MAX_INST_FILE_SIZE  20000     // 20k Characters for the json file
#define MAX_SF3_FILE_SIZE   0x7F00000 // 133MB
#define MAX_SAMPLE_SIZE     0x1F00000 // 32MB
#define MAX_NUM_OF_KEYS     128       // The MIDI spec allows for 128 keys
#define MAX_NUM_OF_VELOCITY 128       // 7 bits of veolcity information according to the MIDI specification
// Tokens
#define NUM_OF_SAMPLE_JSON_MEMBERS   3
#define INSTRUMENT_NAME_TOKEN_STR    "instrument_name"
#define INSTRUMENT_SAMPLES_TOKEN_STR "samples"
#define SAMPLE_VEL_MIN_TOKEN_STR     "velocity_min"
#define SAMPLE_VEL_MAX_TOKEN_STR     "velocity_max"
#define SAMPLE_PATH_TOKEN_STR        "sample_file"
#define MAX_PATH_LEN                 100
// Sample file format
#define SAMPLE_FORMAT_RAW            0
#define SAMPLE_FORMAT_WAVE           1
#define SAMPLE_FORMAT_SF3            2
#define SAMPLE_FORMAT_OTHER          127

////////////////////////////////////////////////////////////
// Sample descriptor data structure
////////////////////////////////////////////////////////////

// Information extracted from the RIFF file
typedef struct {
    uint8_t        sample_file_format; // 0 == No format (RAW data)
    uint8_t       *sample_file_buffer; // Sample file pointer
    uint16_t       audio_format;       // PCM = 1 (i.e. Linear quantization). Values other than 1 indicate some form of compression
    uint16_t       number_of_channels; // Mono = 1, Stereo = 2, etc.
    uint32_t       sample_rate;        // 8000, 44100, etc.
    uint32_t       byte_rate;          // == SampleRate * NumChannels * BitsPerSample/8
    uint16_t       block_align;        // == NumChannels * BitsPerSample/8. The number of bytes for one sample including all channels. I wonder what happens when this number isn't an integer?
    uint16_t       bits_per_sample;    // 8 bits = 8, 16 bits = 16, etc.
    uint32_t       audio_data_size;    // Size of the actual audio data
    uint8_t       *data_start_ptr;     // Memory location where the audio data starts
} SAMPLE_FORMAT_t; // Note. Raw data is little endian

////////////////////////////////////////////////////////////
// Patch descriptor data structure
////////////////////////////////////////////////////////////

typedef struct {
    uint8_t          current_status;                     // 1 = Currently in playback, 0 = Idle
    uint8_t          current_slot;                       // Current slot
    uint8_t          velocity_min;                       // Lower end of the velocity curve
    uint8_t          velocity_max;                       // Higher end of the velocity curve
    uint8_t          sample_present;                     // A sample is present
    uint8_t          sample_path[MAX_CHAR_IN_TOKEN_STR]; // Path of the sample relative to the information file
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
} PATCH_DESCRIPTOR_t;

// This structure is used to create the lookup table to correlate the JSON note names with the MIDI note numbers
typedef struct {
    uint8_t note_name[4]; // Example: "C3_S" (C3 Sharp)
    uint8_t note_number;  // Example: 49
} NOTE_LUT_STRUCT_t;

#endif
