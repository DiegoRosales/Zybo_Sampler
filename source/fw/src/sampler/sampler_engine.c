////////////////////////////////////////////////////////
// Sampler Driver
////////////////////////////////////////////////////////
// C includes
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

// Xilinx Includes
#include "xil_io.h"

//information about AXI peripherals
#include "xparameters.h"

// Sampler Includes
#include "sampler_dma_controller_regs.h"
#include "sampler_dma_controller_reg_utils.h"
#include "sampler_dma_voice_pb.h"
#include "sampler_cfg.h"
#include "patch_loader.h"
#include "sampler_engine.h"

// Lookup table to correlate note names with MIDI notes
static const NOTE_LUT_STRUCT_t MIDI_NOTES_LUT[12] = {
    {"Ax",   21}, // Starts from A0
    {"Ax_S", 22},
    {"Bx",   23}, // Starts from B0
    {"Cx",   12}, // Starts From C1
    {"Cx_S", 13},
    {"Dx",   14},
    {"Dx_S", 15},
    {"Ex",   16},
    {"Fx",   17},
    {"Fx_S", 18},
    {"Gx",   19},
    {"Gx_S", 20}	
};

// This function converts an string in int or hex to a uint32_t
static uint32_t prv_ulStrToInt( const char *input_string ) {

    const char *start_char = input_string;
    char *end_char;
    uint32_t output_int;

    // Check if hex by identifying the '0x'
    if( strncmp( start_char, (const char *) "0x", 2 ) == 0 ) {
        start_char += 2; // Go forward 2 characters
        output_int = (uint32_t)strtoul(start_char, &end_char, 16);
    } else {
        output_int = (uint32_t)strtoul(start_char, &end_char, 10);
    }

    return output_int;

}

// This function stops the playback for everything
uint32_t ulStopAllPlayback( PATCH_DESCRIPTOR_t *instrument_information ) {
    KEY_INFORMATION_t       *current_key    = NULL;
    KEY_VOICE_INFORMATION_t *current_voice  = NULL;
    uint32_t                 key            = 0;
    uint32_t                 velocity_range = 0;
    uint32_t                 voice_slot     = 0;

    // Stop the engine
    SAMPLER_CONTROL_REGISTER_ACCESS->SAMPLER_CONTROL_REG.value = SAMPLER_CONTROL_STOP;

    // Stop the playback
    for ( voice_slot = 0; voice_slot < MAX_VOICES; voice_slot++ ) ulStopVoicePlayback( voice_slot );

    if( instrument_information == NULL ) return 0;

    // Reset the flags
    for (key = 0; key < MAX_NUM_OF_KEYS; key++) {
        if( instrument_information->key_information[key] == NULL ) continue;

        current_key = instrument_information->key_information[key];

        for ( velocity_range = 0; velocity_range < MAX_NUM_OF_VELOCITY; velocity_range++ ) {

            if( current_key->key_voice_information[velocity_range] == NULL ) continue;

            current_voice = current_key->key_voice_information[velocity_range];

            if ( current_voice->current_status != 0 ) {
                SAMPLER_PRINTF_INFO("[%d][%d] Stopping voice playback of slot %d", key, velocity_range, current_voice->current_slot);
                current_voice->current_status = 0;
                current_voice->current_slot   = 0;
            }
        }
    }

    return 0;

}

// This function starts the playback of a sample given the key/velocity parameters and the instrument information
uint32_t ulPlayInstrumentKey( uint8_t key, uint8_t velocity, PATCH_DESCRIPTOR_t *instrument_information ) {

    int                      velocity_range = 0;
    KEY_INFORMATION_t       *current_key = NULL;
    KEY_VOICE_INFORMATION_t *current_voice = NULL;
    uint32_t                 voice_slot = 0;

    // Sanity check

    if ( instrument_information == NULL ) {
        SAMPLER_PRINTF_ERROR("[ERROR] - Instrument information = NULL");
        return 1;
    }

    if ( instrument_information->instrument_loaded == 0 ) {
        SAMPLER_PRINTF_ERROR("[ERROR] - No instrument has been loaded");
        return 1;		
    }

    if ( instrument_information->key_information[key] == NULL ) {
        SAMPLER_PRINTF_ERROR("[ERROR] - There is no information related to this key: %d", key);
        return 1;
    }

    current_key = instrument_information->key_information[key];



    // If velocity is 0, it means to stop
    if ( velocity == 0 ) {
        for ( velocity_range = 0; velocity_range < MAX_NUM_OF_VELOCITY; velocity_range++ ) {

            if( current_key->key_voice_information[velocity_range] == NULL ) {
                continue;
            }

            current_voice = current_key->key_voice_information[velocity_range];

            if ( current_voice->current_status != 0 ) {
                SAMPLER_PRINTF_INFO("[INFO] - Stopping voice playback of slot %d", current_voice->current_slot);
                ulStopVoicePlayback( current_voice->current_slot );
                current_voice->current_status = 0;
                current_voice->current_slot   = 0;
            }
        }

        return 0;
    }

    for ( velocity_range = 0; velocity_range < MAX_NUM_OF_VELOCITY; velocity_range++ ) {

        // Check if the velocity information exists
        if( current_key->key_voice_information[velocity_range] == NULL ) {
            continue;
        }

        current_voice = current_key->key_voice_information[velocity_range];

        // Check if requested velocity falls within the range
        if ( (velocity <= current_voice->velocity_min) && (velocity >= current_voice->velocity_max) ) {
            continue;
        }

        // Check if the sample is not already being played back
        if ( current_voice->current_status != 0 ) {
            SAMPLER_PRINTF_ERROR("Current sample is being played on slot %d", current_voice->current_slot);
            return 3;
        }

        // Check if sample is present
        if ( current_voice->sample_present == 0 ) {
            SAMPLER_PRINTF_ERROR("There's no sample for the specified velocity! %d", current_voice->current_slot);
            return 2;
        }

        // Start playback
        voice_slot = ulStartVoicePlayback( (uint32_t) current_voice->sample_format.data_start_ptr, // Audio data pointer
                                                      current_voice->sample_format.audio_data_size // Audio data size
                                            );
        
        // If there are no available slots, don't update the status
        if ( voice_slot == 0xffff ) {
            SAMPLER_PRINTF_ERROR("No available slots found! %d", voice_slot);
            break;
        }

        SAMPLER_PRINTF_INFO("Started playback on slot %d", voice_slot);

        current_voice->current_slot   = voice_slot;
        current_voice->current_status = 1;
        break;
    }

    return 0;

}

// This function will return the hex value of a MIDI note
uint8_t usGetMIDINoteNumber( const char *note_name ) {
    uint8_t midi_note = 0;

    const char *note_letter = note_name;
    const char *note_number = note_letter + 1;
    const char *sharp_flag  = note_letter + 3;

    uint32_t note_number_int = prv_ulStrToInt( note_number );

    for( int i = 0; i < 12; i++ ) {
        if( MIDI_NOTES_LUT[i].note_name[0] == toupper(*note_letter) ) {
            midi_note = MIDI_NOTES_LUT[i].note_number + (12 * note_number_int);
            if ( toupper(*sharp_flag) == 'S' ) {
                midi_note++;
            }
            return midi_note;
        }
    }
    return 0;
}

