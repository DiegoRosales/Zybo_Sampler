////////////////////////////////////////////////
// Sampler DMA Voice Playback Engine
////////////
// This file contains the driver functions
// that control the polyphonic voice playback
///////////////////////////////////////////////

// Xilinx Includes
#include "xparameters.h"
#include "xil_io.h"
#include "xil_cache.h"

// Sampler DMA Includes
#include "sampler_dma_controller_regs.h"
#include "sampler_dma_controller_reg_utils.h"
#include "sampler_dma_voice_pb.h"

// Private functions
uint16_t prv_usGetAvailableVoiceSlot( void );
void     prv_vReleaseSlot( uint16_t slot );

// Tracking variables
static VOICE_TRK_t     sampler_voices[MAX_VOICES];
static uint8_t         last_voice_slot;
static uint8_t         number_of_active_slots;
static SAMPLER_VOICE_t sampler_voices_information[MAX_VOICES];

// Initialize the sampler registers
void vSamplerDMAInit ( void ) {

    // Initialize the slots
    last_voice_slot        = 0;
    number_of_active_slots = 0;
    for( int i = 0; i < MAX_VOICES; i++ ){
        sampler_voices[ i ].voice_is_active     = 0;
        sampler_voices[ i ].previous_voice_slot = 0;
        sampler_voices[ i ].next_voice_slot     = 0;
        sampler_voices[ i ].slot_is_last        = 0;
    }

}

// This function will return the number of the voice slot available to start the playback
uint16_t prv_usGetAvailableVoiceSlot( void ) {
    uint16_t current_slot     = 0xffff;
    uint16_t previous_slot    = 0;
    uint16_t next_slot        = 0;

    // Step 1 - Get the last link of the chain
    previous_slot = last_voice_slot;

    // If there are no voices playing
    // Step 2 - Check if there are voices playing. If not, take slot 0
    if( number_of_active_slots == 0 ){
        current_slot = 0;
        sampler_voices[ current_slot ].voice_is_active     = 1;
        sampler_voices[ current_slot ].previous_voice_slot = 0;
        sampler_voices[ current_slot ].next_voice_slot     = 0;
        sampler_voices[ current_slot ].slot_is_last        = 1;
        last_voice_slot                                    = 0;
        previous_slot                                      = 0;
        number_of_active_slots                             = number_of_active_slots + 1;
        return current_slot;
    }

    // If there are voices playing
    // Step 3 - Get a free slot
    for( current_slot = 0; current_slot < MAX_VOICES; current_slot ++ ){
        if( sampler_voices[ current_slot ].voice_is_active == 0 ){
            break;
        }
    }

    if( current_slot == 0xffff ) return current_slot;

    next_slot = sampler_voices[ previous_slot ].next_voice_slot;

    // Step 4 - Insert the voice slot into the link
    sampler_voices[ current_slot ].previous_voice_slot = previous_slot;
    sampler_voices[ current_slot ].next_voice_slot     = next_slot;
    sampler_voices[ previous_slot ].next_voice_slot    = current_slot;
    sampler_voices[ previous_slot ].slot_is_last       = 0;
    sampler_voices[ next_slot ].previous_voice_slot    = current_slot; // The previous slot of the first item is the last item

    // Step 5 - Enable the slot
    sampler_voices[ current_slot ].slot_is_last    = 1;
    sampler_voices[ current_slot ].voice_is_active = 1;
    last_voice_slot                                = current_slot;
    number_of_active_slots                         = number_of_active_slots + 1;


    return current_slot;
}

void prv_vReleaseSlot( uint16_t slot ) {
    uint16_t previous_slot;
    uint16_t next_slot;

    // Sanity check. Check if there are any voices playing
    if( number_of_active_slots == 0 || number_of_active_slots > MAX_VOICES ) return;
    // Sanity check. Check if slot is valid
    if( slot > MAX_VOICES ) return;

    // If this is the last voice remaining
    if( number_of_active_slots == 1 ){
        // Clean all slots
        for ( int i = 0; i < MAX_VOICES; i++){
            sampler_voices[ i ].previous_voice_slot = 0;
            sampler_voices[ i ].next_voice_slot     = 0;
            sampler_voices[ i ].slot_is_last        = 0;
            sampler_voices[ i ].voice_is_active     = 0;
        }
        last_voice_slot        = 0;
        number_of_active_slots = 0;
    } else {
        // If there are more voices playing
        // Get the previous slot
        previous_slot = sampler_voices[ slot ].previous_voice_slot;
        next_slot     = sampler_voices[ slot ].next_voice_slot;

        // The nest slot of the previous slot is now the next slot of the current slot
        sampler_voices[ previous_slot ].next_voice_slot = next_slot;
        sampler_voices[ next_slot ].previous_voice_slot = previous_slot; // The previous slot of the first item is the last item

        // If the current slot was the last of the chain, now the previous one is the last of the chain
        if( sampler_voices[ slot ].slot_is_last ) {
            sampler_voices[ previous_slot ].slot_is_last = 1;
            last_voice_slot = previous_slot;
        }

        // Clear the slot
        sampler_voices[ slot ].previous_voice_slot = 0;
        sampler_voices[ slot ].next_voice_slot     = 0;
        sampler_voices[ slot ].slot_is_last        = 0;
        sampler_voices[ slot ].voice_is_active     = 0;
        number_of_active_slots                     = number_of_active_slots - 1;
    }

}

// This function will trigger the playback of a voice based on the voice information
uint32_t ulStartVoicePlayback( uint32_t sample_addr, uint32_t sample_size ) {
    uint32_t voice_slot          = 0;
    uint32_t previous_voice_slot = 0;
    uint32_t number_of_samples   = 0;
    SAMPLER_DMA_CONTROL_REG_t temp_ctrl_reg;
    SAMPLER_DMA_CONTROL_REG_t temp_ctrl_reg2;


    // Step 1 - Get a voice slot
    voice_slot = prv_usGetAvailableVoiceSlot();
    if( voice_slot == 0xffff ) return voice_slot;

    // Step 2 - Calculate Number of sampler
    number_of_samples = sample_size / 4; // 2x16-bit samples

    // Step 3 - Load the voice information data structure
    sampler_voices_information[voice_slot].voice_start_addr = sample_addr;
    sampler_voices_information[voice_slot].voice_size       = sample_size;

    // Step 4 - Write the voice information address to the register with the slot number
    SAMPLER_DMA_REGISTER_ACCESS->sampler_dma[voice_slot].dma_start_addr.value = sample_addr;
    SAMPLER_DMA_REGISTER_ACCESS->sampler_dma[voice_slot].dma_end_addr.value   = sample_addr + sample_size;

    // Set the control register
    temp_ctrl_reg.value         = 0; // Initialize
    temp_ctrl_reg.field.dma_len = number_of_samples;
    temp_ctrl_reg.field.valid   = 1;
    temp_ctrl_reg.field.last    = (uint32_t) sampler_voices[voice_slot].slot_is_last;

    SAMPLER_DMA_REGISTER_ACCESS->sampler_dma[voice_slot].dma_control.value    = 0;
    SAMPLER_DMA_REGISTER_ACCESS->sampler_dma[voice_slot].dma_control.value    = temp_ctrl_reg.value;

    // Step 6 - Add the voice to the chain
    if ( number_of_active_slots > 1 ) {
        previous_voice_slot       = sampler_voices[voice_slot].previous_voice_slot;
        temp_ctrl_reg2.value      = SAMPLER_DMA_REGISTER_ACCESS->sampler_dma[previous_voice_slot].dma_control.value;
        temp_ctrl_reg2.field.last = sampler_voices[previous_voice_slot].slot_is_last & 0x1;
        SAMPLER_DMA_REGISTER_ACCESS->sampler_dma[voice_slot].dma_next_sample.value          = ( sampler_voices[voice_slot].next_voice_slot & 0xffff );
        SAMPLER_DMA_REGISTER_ACCESS->sampler_dma[previous_voice_slot].dma_control.value     = temp_ctrl_reg2.value;
        SAMPLER_DMA_REGISTER_ACCESS->sampler_dma[previous_voice_slot].dma_next_sample.value = ( voice_slot & 0xffff );
    } else {
        SAMPLER_DMA_REGISTER_ACCESS->sampler_dma[voice_slot].dma_next_sample.value = voice_slot;
    }

    // Step 6 - Start the DMA
    SAMPLER_CONTROL_REGISTER_ACCESS->SAMPLER_CONTROL_REG.value = SAMPLER_CONTROL_START;

    Xil_DCacheFlush();

    return voice_slot;
}

// This function will stop the playback of the voice
uint32_t ulStopVoicePlayback( uint32_t voice_slot ) {
    uint32_t                  previous_voice_slot = 0;
    SAMPLER_DMA_CONTROL_REG_t temp_ctrl_reg;

    // Sanity check
    if( voice_slot >= MAX_VOICES ) return 1;

    // Step 1 - Remove the sample from the chain
    if ( number_of_active_slots > 1 ) {
        previous_voice_slot = sampler_voices[voice_slot].previous_voice_slot;
        temp_ctrl_reg.value = SAMPLER_DMA_REGISTER_ACCESS->sampler_dma[previous_voice_slot].dma_control.value;

        if ( sampler_voices[voice_slot].slot_is_last ) temp_ctrl_reg.field.last = 1;

        SAMPLER_DMA_REGISTER_ACCESS->sampler_dma[previous_voice_slot].dma_control.value     = temp_ctrl_reg.value;
        SAMPLER_DMA_REGISTER_ACCESS->sampler_dma[previous_voice_slot].dma_next_sample.value = sampler_voices[voice_slot].next_voice_slot;
    } else {
        // Fully stop the DMA
        SAMPLER_CONTROL_REGISTER_ACCESS->SAMPLER_CONTROL_REG.value = SAMPLER_CONTROL_STOP;
    }

    // Step 2 - Clear the DMA
    SAMPLER_DMA_REGISTER_ACCESS->sampler_dma[voice_slot].dma_start_addr.value  = 0;
    SAMPLER_DMA_REGISTER_ACCESS->sampler_dma[voice_slot].dma_end_addr.value    = 0;
    SAMPLER_DMA_REGISTER_ACCESS->sampler_dma[voice_slot].dma_control.value     = 0;
    SAMPLER_DMA_REGISTER_ACCESS->sampler_dma[voice_slot].dma_next_sample.value = 0;

    Xil_DCacheFlush();

    // Release the voice slot
    prv_vReleaseSlot( voice_slot );

    return 0;
}
