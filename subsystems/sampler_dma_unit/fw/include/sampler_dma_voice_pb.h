/////////////////////////////////////
// Sampler DMA Voice Playback Engine
/////////////////////////////////////

#ifndef _SAMPLER_DMA_VOICE_PB_H_
#define _SAMPLER_DMA_VOICE_PB_H_

// Shortcuts for the Sampler Control Access
#define SAMPLER_CONTROL_START_BIT 0
#define SAMPLER_CONTROL_STOP_BIT  1
#define SAMPLER_CONTROL_START     ( 1 << SAMPLER_CONTROL_START_BIT )
#define SAMPLER_CONTROL_STOP      ( 1 << SAMPLER_CONTROL_STOP_BIT  )


// Voice tracking
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

void     vSamplerDMAInit ( void );
uint32_t ulStopVoicePlayback( uint32_t voice_slot_number );
uint32_t ulStartVoicePlayback( uint32_t sample_addr, uint32_t sample_size );

#endif