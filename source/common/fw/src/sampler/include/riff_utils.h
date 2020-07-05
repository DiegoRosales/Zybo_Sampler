#ifndef __RIFF_UTILS_H__
#define __RIFF_UTILS_H__

#include "sampler_cfg.h"

#ifndef RIFF_PRINTF
    #define RIFF_PRINTF xil_printf
#endif

// Debug level
#ifndef RIFF_DEBUG
    #define RIFF_DEBUG 1
#endif

#if defined(RIFF_DEBUG) 
  #if RIFF_DEBUG >= 3
    #define RIFF_PRINTF_INFO(fmt, args...)    RIFF_PRINTF("[RIFF][INFO]    : %s:%d:%s(): " fmt "\n\r", __FILE__, __LINE__, __func__, ##args)
    #define RIFF_PRINTF_WARNING(fmt, args...) RIFF_PRINTF("[RIFF][WARNING] : %s:%d:%s(): " fmt "\n\r", __FILE__, __LINE__, __func__, ##args)
    #define RIFF_PRINTF_ERROR(fmt, args...)   RIFF_PRINTF("[RIFF][ERROR]   : %s:%d:%s(): " fmt "\n\r", __FILE__, __LINE__, __func__, ##args)
    #define RIFF_PRINTF_DEBUG(fmt, args...)   RIFF_PRINTF("[RIFF][DEBUG]   : %s:%d:%s(): " fmt "\n\r", __FILE__, __LINE__, __func__, ##args)
  #elif RIFF_DEBUG == 2
    #define RIFF_PRINTF_INFO(fmt, args...)    RIFF_PRINTF("[RIFF][INFO]    : "             fmt "\n\r", ##args)
    #define RIFF_PRINTF_WARNING(fmt, args...) RIFF_PRINTF("[RIFF][WARNING] : "             fmt "\n\r", ##args)
    #define RIFF_PRINTF_ERROR(fmt, args...)   RIFF_PRINTF("[RIFF][ERROR]   : %s:%d:%s(): " fmt "\n\r", __FILE__, __LINE__, __func__, ##args)
    #define RIFF_PRINTF_DEBUG(fmt, args...)   RIFF_PRINTF("[RIFF][DEBUG]   : %s:%d:%s(): " fmt "\n\r", __FILE__, __LINE__, __func__, ##args)
  #elif RIFF_DEBUG == 1
    #define RIFF_PRINTF_INFO(fmt, args...)    RIFF_PRINTF("[RIFF][INFO]    : " fmt "\n\r", ##args)
    #define RIFF_PRINTF_WARNING(fmt, args...) RIFF_PRINTF("[RIFF][WARNING] : " fmt "\n\r", ##args)
    #define RIFF_PRINTF_ERROR(fmt, args...)   RIFF_PRINTF("[RIFF][ERROR]   : " fmt "\n\r", ##args)
    #define RIFF_PRINTF_DEBUG(fmt, args...)   RIFF_PRINTF("[RIFF][DEBUG]   : " fmt "\n\r", ##args)
  #else
    #define RIFF_PRINTF_INFO(fmt, args...)    RIFF_PRINTF("[RIFF][INFO]    : " fmt "\n\r", ##args)
    #define RIFF_PRINTF_WARNING(fmt, args...) RIFF_PRINTF("[RIFF][WARNING] : " fmt "\n\r", ##args)
    #define RIFF_PRINTF_ERROR(fmt, args...)   RIFF_PRINTF("[RIFF][ERROR]   : " fmt "\n\r", ##args)
    #define RIFF_PRINTF_DEBUG(fmt, args...)   /* Nothing */
  #endif
#else
    #define RIFF_PRINTF_INFO(fmt, args...)    RIFF_PRINTF("[INFO]    : " fmt "\n\r", ##args)
    #define RIFF_PRINTF_WARNING(fmt, args...) RIFF_PRINTF("[WARNING] : " fmt "\n\r", ##args)
    #define RIFF_PRINTF_ERROR(fmt, args...)   RIFF_PRINTF("[ERROR]   : " fmt "\n\r", ##args)
    #define RIFF_PRINTF_DEBUG(fmt, args...)   /* Nothing */
#endif

// RIFF Tokens
#define RIFF_ASCII_TOKEN   0x46464952 // ASCII String == "RIFF"
#define WAVE_ASCII_TOKEN   0x45564157 // ASCII String == "WAVE"
#define FMT_ASCII_TOKEN    0x20746d66 // ASCII String == "fmt "
#define DATA_ASCII_TOKEN   0x61746164 // ASCII String == "data"
#define LIST_ASCII_TOKEN   0x5453494c // ASCII String == "LIST"

// Get chunks
#define cmdGET_RIFF_DESCRIPTOR_CHUNK(buffer) (( RIFF_DESCRIPTOR_CHUNK_t * ) buffer) 
#define cmdGET_RIFF_LIST_DESCRIPTOR_CHUNK(buffer) (( RIFF_LIST_DESCRIPTOR_CHUNK_t * ) buffer) 
#define cmdGET_RIFF_BASE_CHUNK(buffer) (( RIFF_BASE_CHUNK_t * ) buffer) 

////////////////////////////////////////////////////////////
// RIFF and WAVE File data structures
////////////////////////////////////////////////////////////
typedef struct {
    uint32_t ChunkID;   // Big Endian
    uint32_t ChunkSize; // Little Endian
} RIFF_BASE_CHUNK_t;

typedef struct {
    RIFF_BASE_CHUNK_t BaseChunk; // ID ("RIFF") and Size
    uint32_t          FormType;  // Contains the letters "WAVE" (0x57415645 big-endian form)
} RIFF_DESCRIPTOR_CHUNK_t;

typedef struct {
    RIFF_BASE_CHUNK_t BaseChunk; // ID ("RIFF") and Size
    uint32_t          ListType;  // Contains the type of list
} RIFF_LIST_DESCRIPTOR_CHUNK_t;

typedef struct {
    RIFF_BASE_CHUNK_t BaseChunk;     // ID ("fmt ") and Size
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


void vDecodeWAVEInformation( uint8_t *riff_buffer, size_t riff_buffer_size, SAMPLE_FORMAT_t *sample_information );
void vPrintSF2Info( uint8_t* sf2_buffer, size_t sf2_buffer_len );

#endif
