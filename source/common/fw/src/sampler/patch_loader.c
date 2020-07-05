///////////////////////////////////////////////
// Patch Loader
///////////////////////////////////////////////
// This contains all APIs necessary to load
// a patch
//////////////
// A patch is made of keys (MIDI keys)
// Those keys map to voices (1 or more, distinguished by Velocity)
// Those voices map to samples
// Those samples are audio tracks that need to be loaded to memory
///////////////////////////////////////////////

// C includes
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

// Xilinx Includes
#include "xil_io.h"

// FreeRTOS+FAT includes
#include "ff_stdio.h"
#include "ff_ramdisk.h"
#include "ff_sddisk.h"
#include "fat_CLI_apps.h"

// JSMN
#include "jsmn.h"
#include "jsmn_utils.h"

// Sampler includes
#include "sampler_cfg.h"
#include "riff_utils.h"
#include "patch_loader.h"

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

// Static variables
static uint8_t   json_patch_information_buffer[MAX_INST_FILE_SIZE]; // JSON File buffer
static uint8_t * sf2_patch_buffer = NULL; // SF2 Buffer

//////////////////////////////////////////////////
// Static Functions
//////////////////////////////////////////////////
static PATCH_DESCRIPTOR_t      * prv_xInitPatchDescriptor();
static KEY_VOICE_INFORMATION_t * prv_xInitVoiceInformation();
static KEY_INFORMATION_t       * prv_xInitKeyInformation();
static uint32_t                  prv_ulDecodeJSON_SamplePaths( uint32_t sample_start_token_index, uint32_t number_of_samples, jsmntok_t *tokens, uint8_t *json_patch_information_buffer, PATCH_DESCRIPTOR_t *patch_descriptor );
static uint8_t                   prv_usGetJSON_MIDINoteNumber( jsmntok_t *tok, uint8_t *instrument_info_buffer );
static uint32_t                  prv_ulStr2Int( const char *input_string, uint32_t input_string_length );
static uint32_t                  prv_ulDecodeJSON_PatchInfo( uint8_t *json_patch_information_buffer, PATCH_DESCRIPTOR_t *patch_descriptor );
static uint32_t                  prv_ulLoadSamplesFromDescriptor( PATCH_DESCRIPTOR_t *patch_descriptor, const char *json_file_root_dir );
#if ENABLE_SAMPLE_REALIGN == 1
static uint32_t                  prv_ulRealignAudioData( KEY_VOICE_INFORMATION_t *voice_information );
#endif

// This function will load a patch given a JSON patch information file
PATCH_DESCRIPTOR_t * ulLoadPatchFromJSON( const char * json_file_dirname, const char * json_file_fullpath) {

    PATCH_DESCRIPTOR_t *patch_descriptor = NULL;
    uint32_t error = 0;

    PATCH_LOADER_PRINTF_DEBUG("This is a test");

    // Step 1 - Open the json file containing the instrument information
    PATCH_LOADER_PRINTF_INFO("Step 1 - Load the JSON File");
    xLoadFileToMemory( json_file_fullpath, json_patch_information_buffer, (size_t) MAX_INST_FILE_SIZE );

    // Step 2 - Initialize the instrument information
    PATCH_LOADER_PRINTF_INFO("Step 2 - Initializing the instrument information");

    if ( patch_descriptor == NULL ){
        patch_descriptor = prv_xInitPatchDescriptor();
        // Check if the initialization succeeded
        if ( patch_descriptor == NULL ){
            PATCH_LOADER_PRINTF_ERROR("Instrument information could not be initialized!!");
            return NULL;
        } else {
            PATCH_LOADER_PRINTF_INFO("Patch descriptor initialized on address 0x%x", patch_descriptor);
        }
    } else {
        PATCH_LOADER_PRINTF_INFO("Instrument information was already initialized at 0x%x", patch_descriptor);
        patch_descriptor->instrument_loaded = 0; // Unset in case it was already loaded
    }

    PATCH_LOADER_PRINTF_INFO("Step 2 - Done!");

    // Step 3 - Decode the JSON file using JSMN
    PATCH_LOADER_PRINTF_INFO("Step 3 - Decoding the patch information...");
    error = prv_ulDecodeJSON_PatchInfo( json_patch_information_buffer, patch_descriptor );
    if ( error ) {
        PATCH_LOADER_PRINTF_ERROR("There was a problem when decoding the JSON Patch information!!");
        return NULL;
    }
    PATCH_LOADER_PRINTF_INFO("Step 3 - Done!");

    // Step 4 - Load all the samples into memory
    // Initialize the variables
    PATCH_LOADER_PRINTF_INFO("Step 4 - Loading samples into memory...");
    error = prv_ulLoadSamplesFromDescriptor( patch_descriptor, json_file_dirname );
    if ( error ) {
        PATCH_LOADER_PRINTF_ERROR("There was a problem when loading the samples into memory!!");
        return NULL;
    }
    patch_descriptor->instrument_loaded = 1;
    PATCH_LOADER_PRINTF_INFO("Step 4 - Done!");

    if(patch_descriptor == NULL) {
        PATCH_LOADER_PRINTF_ERROR("Somehow the patch descriptor lost its information. patch_descriptor == NULL");
        return NULL;
    } else {
        PATCH_LOADER_PRINTF_INFO("patch_descriptor == 0x%x", patch_descriptor);
    }

    PATCH_LOADER_PRINTF("------------\n\r");
    PATCH_LOADER_PRINTF("Instrument Succesfully Loaded!\n\r");
    PATCH_LOADER_PRINTF("------------\n\r\n\r");

    return patch_descriptor;
}

// This function will load a SoundFont3 file
PATCH_DESCRIPTOR_t * ulLoadPatchFromSF2( const char * sf2_file_fullpath ) {
    PATCH_DESCRIPTOR_t *patch_descriptor = NULL;
    size_t              sf2_patch_buffer_len;

    // Step 1 - Open the json file containing the instrument information
    PATCH_LOADER_PRINTF_INFO("Step 1 - Load the SF2 File");
    sf2_patch_buffer_len = xLoadFileToMemory_malloc( sf2_file_fullpath, &sf2_patch_buffer, MAX_SF2_FILE_SIZE, 0 );

    if ( sf2_patch_buffer_len == 0 || sf2_patch_buffer == NULL ) {
        PATCH_LOADER_PRINTF_ERROR("Error while loading the SF2 file!");
        return NULL;
    }

    vPrintSF2Info( sf2_patch_buffer, sf2_patch_buffer_len );

    return patch_descriptor;

}

// This function will print the information of a SoundFont3 file
void vPrintSF2FileInfo( const char * sf2_file_fullpath ) {
    uint8_t            * local_sf2_patch_buffer;
    size_t               local_sf2_patch_buffer_len;

    // Step 1 - Open the json file containing the instrument information
    PATCH_LOADER_PRINTF_INFO("Step 1 - Load the SF2 File");
    local_sf2_patch_buffer_len = xLoadFileToMemory_malloc( sf2_file_fullpath, &local_sf2_patch_buffer, MAX_SF2_FILE_SIZE, 0 );

    if ( local_sf2_patch_buffer_len == 0 || local_sf2_patch_buffer == NULL ) {
        PATCH_LOADER_PRINTF_ERROR("Error while loading the SF2 file!");
        return;
    }

    // Step 2 - Print SF2 information
    vPrintSF2Info( local_sf2_patch_buffer, local_sf2_patch_buffer_len );

    // Step 3 - Unload the SF2 file
    vClearMemoryBuffer( local_sf2_patch_buffer );
}

// This function converts an string in int or hex to a uint32_t
static uint32_t prv_ulStr2Int( const char *input_string, uint32_t input_string_length ) {
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

// This function will initialize the data structure of a patch
PATCH_DESCRIPTOR_t * prv_xInitPatchDescriptor() {

    PATCH_DESCRIPTOR_t * patch_descriptor = sampler_malloc( sizeof(PATCH_DESCRIPTOR_t) );
    if ( patch_descriptor == NULL ) {
        PATCH_LOADER_PRINTF_ERROR("Memory allocation for the instrument info failed. Requested size = %d bytes", sizeof(PATCH_DESCRIPTOR_t));
        return NULL;
    } else {
        PATCH_LOADER_PRINTF_INFO("Memory allocation for the instrument info succeeded. Memory location: 0x%x", patch_descriptor );

        // Initialize the structure
        memset( patch_descriptor, 0x00 , sizeof(PATCH_DESCRIPTOR_t) );
    }

    return patch_descriptor;
}

// Initialize key voice information
KEY_VOICE_INFORMATION_t *prv_xInitVoiceInformation() {

    KEY_VOICE_INFORMATION_t *voice_information = sampler_malloc( sizeof( KEY_VOICE_INFORMATION_t ) );

    // Sanity check
    if( voice_information == NULL ){
        PATCH_LOADER_PRINTF_ERROR("Memory allocation for the Voice Information failed!");
        return NULL;
    }

    memset( voice_information, 0x00, sizeof( KEY_VOICE_INFORMATION_t ) );

    return voice_information;
}

// Initialize key information
KEY_INFORMATION_t * prv_xInitKeyInformation( ) {

    KEY_INFORMATION_t *key_information = sampler_malloc( sizeof( KEY_INFORMATION_t ) );

    // Sanity check
    if( key_information == NULL ){
        PATCH_LOADER_PRINTF_ERROR("[ERROR] - Memory allocation for the Key Information failed!");
        return NULL;
    }

    memset( key_information, 0x00, sizeof( KEY_INFORMATION_t ) );

    return key_information;
}

// This function will decode the JSON file containing the
// instrument information and will populate the instrument data structures
uint32_t prv_ulDecodeJSON_PatchInfo( uint8_t *json_patch_information_buffer, PATCH_DESCRIPTOR_t *patch_descriptor ) {
    // JSMN Variables
    jsmn_parser parser;
    jsmntok_t   tokens[1000];
    int         parser_result;

    // Patch Variables
    uint32_t number_of_samples;
    uint32_t sample_start_token_index;

    // Sanity check
    if( patch_descriptor == NULL ) {
        PATCH_LOADER_PRINTF_ERROR("JSON Decoder failed. patch_descriptor == NULL");
        return 1;
    }

    // Step 1 - Initialize the parser
    jsmn_init(&parser);


    // Step 2 - Parse the buffer
    // js - pointer to JSON string
    // tokens - an array of tokens available
    // 1000 - number of tokens available
    parser_result = jsmn_parse(&parser, (const char *) json_patch_information_buffer, strlen((const char *) json_patch_information_buffer), tokens, 1000);

    // Step 3 - Check for errors
    if ( parser_result < 0 ) {
        PATCH_LOADER_PRINTF_ERROR("There was a problem decoding the instrument information. Error code = %d", parser_result);
        return 1;
    }
    else {
        PATCH_LOADER_PRINTF_INFO("Instrument information parsing was succesful!");
    }

    // Step 4 - Extract the information
    // Step 4.1 - Get the instrument name
    for ( int i = 0; i < parser_result ; i++ ) {
        if ( l_json_equal( (const char *) json_patch_information_buffer, &tokens[i], INSTRUMENT_NAME_TOKEN_STR ) ) {
            l_json_get_string((const char *) json_patch_information_buffer, &tokens[i + 1], (char *) patch_descriptor->instrument_name );
            PATCH_LOADER_PRINTF_INFO("Instrument Name: %s", patch_descriptor->instrument_name );
            break;
        }
    }

    // Step 4.2 - Extract the sample paths
    for ( int i = 0; i < parser_result ; i++ ) {
        if ( l_json_equal( (const char *) json_patch_information_buffer, &tokens[i], INSTRUMENT_SAMPLES_TOKEN_STR ) ) {
            number_of_samples        = (uint32_t) tokens[i + 1].size;
            sample_start_token_index = i + 2;
            PATCH_LOADER_PRINTF_INFO("Number of samples: %d", number_of_samples );
            prv_ulDecodeJSON_SamplePaths( sample_start_token_index, number_of_samples, tokens, json_patch_information_buffer, patch_descriptor );
            break;
        }
    }
    return 0;

}

// This function will extract the sample paths from the information file
// This will also allocate and initialize the information when it hasn't been allocated yet
uint32_t prv_ulDecodeJSON_SamplePaths( uint32_t sample_start_token_index, uint32_t number_of_samples, jsmntok_t *tokens, uint8_t *json_patch_information_buffer, PATCH_DESCRIPTOR_t *patch_descriptor ) {
    uint8_t midi_note;
    uint32_t note_name_index;
    uint32_t key_info_index;

    KEY_INFORMATION_t       *current_key   = NULL;
    KEY_VOICE_INFORMATION_t *current_voice = NULL;

    for( int i = 0; i < number_of_samples ; i++) {
        note_name_index = sample_start_token_index + (i * (NUM_OF_SAMPLE_JSON_MEMBERS + 1) * 2);
        key_info_index  = note_name_index + 2;
        // Get the MIDI note
        midi_note = prv_usGetJSON_MIDINoteNumber(&tokens[note_name_index], json_patch_information_buffer);

        if ( midi_note < MAX_NUM_OF_KEYS ) {

            // Allocate the memory if the key information doesn't exist
            if( patch_descriptor->key_information[midi_note] == NULL ) {
                patch_descriptor->key_information[midi_note] = prv_xInitKeyInformation();
                if( patch_descriptor->key_information[midi_note] == NULL ) return 0;
            }

            current_key = patch_descriptor->key_information[midi_note];

            // TODO: Add multiple velocity switches
            if( current_key->key_voice_information[0] == NULL ) {
                current_key->key_voice_information[0] = prv_xInitVoiceInformation();
                if( current_key->key_voice_information[0] == NULL ) return 0;
            }

            current_voice = current_key->key_voice_information[0];

            // Get the rest of the information
            for( int j = key_info_index; j < ( key_info_index + (NUM_OF_SAMPLE_JSON_MEMBERS * 2) ); j += 2 ) {
                if( l_json_equal( (const char *)json_patch_information_buffer, &tokens[j], SAMPLE_VEL_MIN_TOKEN_STR ) ) {
                    current_voice->velocity_min = prv_ulStr2Int( (char *)(json_patch_information_buffer + tokens[j + 1].start), ( tokens[j + 1].end - tokens[j + 1].start ) );
                    //PATCH_LOADER_PRINTF_DEBUG("KEY[%d]: velocity_min = %d", midi_note, patch_descriptor->key_information[midi_note].key_voice_information[0].velocity_min);
                } else if( l_json_equal( (const char *)json_patch_information_buffer, &tokens[j], SAMPLE_VEL_MAX_TOKEN_STR ) ) {
                    current_voice->velocity_max = prv_ulStr2Int( (char *)(json_patch_information_buffer + tokens[j + 1].start), ( tokens[j + 1].end - tokens[j + 1].start ) );
                    //PATCH_LOADER_PRINTF_DEBUG("KEY[%d]: velocity_max = %d", midi_note, patch_descriptor->key_information[midi_note].key_voice_information[0].velocity_max);
                } else if( l_json_equal( (const char *)json_patch_information_buffer, &tokens[j], SAMPLE_PATH_TOKEN_STR ) ) {
                    current_voice->sample_present = 1;
                    l_json_get_string( (const char *)json_patch_information_buffer, &tokens[j + 1], (char *) current_voice->sample_path );
                    PATCH_LOADER_PRINTF_DEBUG("KEY[%d]: sample_path = %s", midi_note, current_voice->sample_path);
                }
            }
        }
    }

    return 0;

}

// This function will return the hex MIDI note number of a given JSON patch information field
uint8_t prv_usGetJSON_MIDINoteNumber( jsmntok_t *tok, uint8_t *json_patch_information_buffer ) {
    uint8_t midi_note = 0;

    uint8_t *note_letter_addr = json_patch_information_buffer + tok->start;
    uint8_t *note_number_addr = note_letter_addr + 1;
    uint8_t *sharp_flag_addr  = note_letter_addr + 3;

    char note_letter = (char) *note_letter_addr;
    char note_number = (char) *note_number_addr;
    char sharp_flag  = (char) *sharp_flag_addr;

    uint32_t note_number_int = prv_ulStr2Int( &note_number, 1 );

    for( int i = 0; i < 12; i++ ) {
        if( MIDI_NOTES_LUT[i].note_name[0] == note_letter ) {
            midi_note = MIDI_NOTES_LUT[i].note_number + (12 * note_number_int);
            if ( sharp_flag == 'S' ) {
                midi_note++;
            }
            return midi_note;
        }
    }
    return 0;
}

// This function will load the samples of a descriptor into memory
uint32_t prv_ulLoadSamplesFromDescriptor( PATCH_DESCRIPTOR_t *patch_descriptor, const char *json_file_root_dir ) {

    // Initialize the variables
    uint32_t  key              = 0;
    uint32_t  vel_range        = 0;    
    uint32_t  error            = 0;
    uint8_t * riff_buffer      = NULL;
    size_t    riff_buffer_size = 0;
    char      full_path[MAX_PATH_LEN]; // Path to the sample

    // Sanity check
    if (patch_descriptor == NULL) {
        PATCH_LOADER_PRINTF_ERROR("Sample loader failed. patch_descriptor == NULL");
        return 1;
    }

    patch_descriptor->total_size = 0;
    patch_descriptor->total_keys = 0;

    KEY_INFORMATION_t       *current_key;
    KEY_VOICE_INFORMATION_t *current_voice;

    // DMA Data Structure
    SAMPLE_FORMAT_t         *current_sample_format;

    for (key = 0; key < MAX_NUM_OF_KEYS; key++) {

        current_key = patch_descriptor->key_information[key];
        if ( current_key == NULL ) continue;

        for (vel_range = 0; vel_range < 1; vel_range++) {

            current_voice                 = current_key->key_voice_information[vel_range];
            if ( (current_voice == NULL) || (current_voice->sample_present == 0) ) continue;

            // Initialize status
            current_voice->current_status = 0;
            current_voice->current_slot   = 0;
            current_sample_format         = &current_voice->sample_format;

            // Copy the full path
            memset( full_path, 0x00, MAX_PATH_LEN );
            strcat( full_path, json_file_root_dir);
            strcat( full_path, "/");
            strcat( full_path, (const char *) current_voice->sample_path);
            #if PATCH_LOADER_DEBUG < 1
                PATCH_LOADER_PRINTF(".");
            #else
                PATCH_LOADER_PRINTF_DEBUG("[%d][%d] Loading Sample \"%s\"", key, vel_range, current_voice->sample_path );
            #endif

            // Load the RIFF File into memory
            riff_buffer      = NULL;
            riff_buffer_size = xLoadFileToMemory_malloc( 
                                                            full_path,
                                                            &riff_buffer,
                                                            (size_t) MAX_SAMPLE_SIZE,
                                                            sizeof(uint32_t) // Overhead to allow realignment
                                                        );
            if ( riff_buffer == NULL || riff_buffer_size == 0 ) {
                PATCH_LOADER_PRINTF_ERROR("Failed loading the RIFF file into memory");
                return 1;                          
            }
            
            patch_descriptor->total_size += riff_buffer_size;
            patch_descriptor->total_keys++;

            // Extract the RIFF information and configure the DMA data structures for the PL DMA functionality
            vDecodeWAVEInformation( riff_buffer, riff_buffer_size, current_sample_format );

            // Check for errors
            if ( (current_sample_format->audio_data_size == 0) || (current_sample_format->data_start_ptr == NULL)) {
                PATCH_LOADER_PRINTF_ERROR("Failed decoding the RIFF audio data");
                return error;
            }

            // Data realignment mechanism
            #if ENABLE_SAMPLE_REALIGN == 1
                error = prv_ulRealignAudioData( current_voice );

                if ( error != 0 ) {
                    PATCH_LOADER_PRINTF_ERROR("Failed realigning the RIFF audio data");
                    return error;
                }

                // Release the memory for the next file
                vClearMemoryBuffer( riff_buffer );
                riff_buffer = NULL;
            #endif
        }
    }

    PATCH_LOADER_PRINTF("\n\r---\n\r");
    PATCH_LOADER_PRINTF_INFO("Loaded %d keys", patch_descriptor->total_keys);
    PATCH_LOADER_PRINTF_INFO("Total Memory Used = %d bytes", patch_descriptor->total_size);

    return 0;
}

#if ENABLE_SAMPLE_REALIGN == 1
// This function realigns the 16-bit audio data so that it can be properly accessed through DMA without complex HW implementations
// To do this, the data needs to start in an address that is multiple of 4 (ej. 0xffff0000, 0xffff0004, 0xffff0008, 0xffff000c, etc.)
uint32_t prv_ulRealignAudioData( KEY_VOICE_INFORMATION_t *voice_information ) {

    uint8_t *aligned_buffer_ptr = NULL;
    
    // Sanity check
    if ( voice_information == NULL ) return 1;
    if ( voice_information->sample_format.data_start_ptr == NULL ) return 1;
    if ( voice_information->sample_format.audio_data_size == 0 ) return 1;

    // If data needs realignment, copy the unaligned data to a temp memory location
    // and then copy back the data on the appropriate offset.

    // Step 1 - Malloc the required temoporary space
    aligned_buffer_ptr = sampler_malloc( (size_t) voice_information->sample_format.audio_data_size );

    // Fail if there's not enugh space for malloc
    if ( aligned_buffer_ptr == NULL ) {
        PATCH_LOADER_PRINTF_ERROR("Malloc for the temporary realignment buffer failed! Requested size = %d bytes", voice_information->sample_format.audio_data_size);
        return 1;
    }

    // Step 2 - Copy the contents
    //memcpy( temp_data_buffer, voice_information->sample_format.data_start_ptr, (size_t) voice_information->sample_format.audio_data_size );
    memcpy( aligned_buffer_ptr, voice_information->sample_format.data_start_ptr, (size_t) voice_information->sample_format.audio_data_size );

    // Step 3 - Assign the new pointer
    voice_information->sample_format.data_start_ptr = aligned_buffer_ptr;

    return 0;
}
#endif
