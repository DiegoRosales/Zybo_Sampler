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
static uint8_t json_patch_information_buffer[MAX_INST_FILE_SIZE]; // JSON File buffer

//////////////////////////////////////////////////
// Static Functions
//////////////////////////////////////////////////
static PATCH_DESCRIPTOR_t      * prv_xInitPatchDescriptor();
static KEY_VOICE_INFORMATION_t * prv_xInitVoiceInformation();
static KEY_INFORMATION_t       * prv_xInitKeyInformation();
static uint32_t                  prv_ulDecodeJSON_SamplePaths( uint32_t sample_start_token_index, uint32_t number_of_samples, jsmntok_t *tokens, uint8_t *json_patch_information_buffer, PATCH_DESCRIPTOR_t *patch_descriptor );
static uint8_t                   prv_usGetJSON_MIDINoteNumber( jsmntok_t *tok, uint8_t *instrument_info_buffer );
static uint32_t                  prv_ulRealignAudioData( KEY_VOICE_INFORMATION_t *voice_information );
static uint32_t                  prv_ulStr2Int( const char *input_string, uint32_t input_string_length );

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
PATCH_DESCRIPTOR_t* prv_xInitPatchDescriptor() {

    PATCH_DESCRIPTOR_t* patch_descriptor = sampler_malloc( sizeof(PATCH_DESCRIPTOR_t) );
    if ( patch_descriptor == NULL ) {
        xil_printf("[ERROR] - Memory allocation for the instrument info failed. Requested size = %d bytes\n\r", sizeof(PATCH_DESCRIPTOR_t));
        return NULL;
    } else {
        xil_printf("[INFO] - Memory allocation for the instrument info succeeded. Memory location: 0x%x\n\r", patch_descriptor );

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
        xil_printf( "[ERROR] - Memory allocation for the Voice Information failed!" );
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
        xil_printf( "[ERROR] - Memory allocation for the Key Information failed!" );
        return NULL;
    }

    memset( key_information, 0x00, sizeof( KEY_INFORMATION_t ) );

    return key_information;
}


// This function will load a patch given a JSON patch information file
uint32_t ulLoadPatchFromJSON( const char * json_file_dirname, const char * json_file_fullpath, PATCH_DESCRIPTOR_t * patch_descriptor ) {

    
    uint32_t error = 0;

    // Step 1 - Open the json file containing the instrument information
    xil_printf("Step 1 - Load the JSON File\n\r");
    load_file_to_memory( json_file_fullpath, json_patch_information_buffer, (size_t) MAX_INST_FILE_SIZE );

    // Step 2 - Initialize the instrument information
    xil_printf("Step 2 - Initializing the instrument information\n\r");

    if ( patch_descriptor == NULL ){
        patch_descriptor = prv_xInitPatchDescriptor();
        // Check if the initialization succeeded
        if ( patch_descriptor == NULL ){
            xil_printf("[ERROR] - Instrument information could not be initialized!!\n\r");
            return 1;
        }
    } else {
        xil_printf("[INFO] - Instrument information was already initialized at 0x%x\n\r", patch_descriptor);
        patch_descriptor->instrument_loaded = 0; // Unset in case it was already loaded
    }

    xil_printf("Step 2 - Done!\n\r");

    // Step 3 - Decode the JSON file using JSMN
    xil_printf("Step 3 - Decoding the instrument information...\n\r");
    ulDecodeJSON_PatchInfo( json_patch_information_buffer, patch_descriptor );
    xil_printf("Step 3 - Done!\n\r");

    // Step 4 - Load all the samples into memory
    // Initialize the variables
    xil_printf("Step 4 - Loading samples into memory...\n\r");
    error = ulLoadSamplesFromDescriptor( patch_descriptor, json_file_dirname );
    if ( error ) {
        xil_printf("[ERROR] - There was a problem when loading the samples into memory!!\n\r");
        return 1;
    }
    xil_printf("---\n\r");
    xil_printf("[INFO] - Loaded %d keys\n\r", patch_descriptor->total_keys);
    xil_printf("[INFO] - Total Memory Used = %d bytes\n\r", patch_descriptor->total_size);
    xil_printf("Step 4 - Done!\n\r");

    // Step 5 - Load the DMA data structures
    xil_printf("Step 5 - Populating the sampler DMA data structures...\n\r");
    ulConfigDMADataStructure( patch_descriptor );
    patch_descriptor->instrument_loaded = 1;
    xil_printf("Step 5 - Done!\n\r");

    xil_printf("------------\n\r");
    xil_printf("Instrument Succesfully Loaded!\n\r");
    xil_printf("------------\n\r\n\r");

    return 0;
}

// This function will decode the JSON file containing the
// instrument information and will populate the instrument data structures
uint32_t ulDecodeJSON_PatchInfo( uint8_t *json_patch_information_buffer, PATCH_DESCRIPTOR_t *patch_descriptor ) {
    // JSMN Variables
    jsmn_parser parser;
    jsmntok_t   tokens[1000];
    int         parser_result;

    // Patch Variables
    uint32_t number_of_samples;
    uint32_t sample_start_token_index;

    // Step 1 - Initialize the parser
    jsmn_init(&parser);


    // Step 2 - Parse the buffer
    // js - pointer to JSON string
    // tokens - an array of tokens available
    // 1000 - number of tokens available
    parser_result = jsmn_parse(&parser, (const char *) json_patch_information_buffer, strlen((const char *) json_patch_information_buffer), tokens, 1000);

    // Step 3 - Check for errors
    if ( parser_result < 0 ) {
        xil_printf( "[ERROR] - There was a problem decoding the instrument information. Error code = %d\n\r", parser_result );
        return 1;
    }
    else {
        xil_printf( "[INFO] - Instrument information parsing was succesful!\n\r" );
    }

    // Step 4 - Extract the information
    // Step 4.1 - Get the instrument name
    for ( int i = 0; i < parser_result ; i++ ) {
        if ( l_json_equal( (const char *) json_patch_information_buffer, &tokens[i], INSTRUMENT_NAME_TOKEN_STR ) ) {
            l_json_get_string((const char *) json_patch_information_buffer, &tokens[i + 1], (char *) patch_descriptor->instrument_name );
            xil_printf("Instrument Name: %s", patch_descriptor->instrument_name );
            xil_printf("\n\r");
            break;
        }
    }

    // Step 4.2 - Extract the sample paths
    for ( int i = 0; i < parser_result ; i++ ) {
        if ( l_json_equal( (const char *) json_patch_information_buffer, &tokens[i], INSTRUMENT_SAMPLES_TOKEN_STR ) ) {
            number_of_samples        = (uint32_t) tokens[i + 1].size;
            sample_start_token_index = i + 2;
            xil_printf("Number of samples: %d\n\r", number_of_samples );
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
                    //xil_printf("KEY[%d]: velocity_min = %d\n\r", midi_note, patch_descriptor->key_information[midi_note].key_voice_information[0].velocity_min);
                } else if( l_json_equal( (const char *)json_patch_information_buffer, &tokens[j], SAMPLE_VEL_MAX_TOKEN_STR ) ) {
                    current_voice->velocity_max = prv_ulStr2Int( (char *)(json_patch_information_buffer + tokens[j + 1].start), ( tokens[j + 1].end - tokens[j + 1].start ) );
                    //xil_printf("KEY[%d]: velocity_max = %d\n\r", midi_note, patch_descriptor->key_information[midi_note].key_voice_information[0].velocity_max);
                } else if( l_json_equal( (const char *)json_patch_information_buffer, &tokens[j], SAMPLE_PATH_TOKEN_STR ) ) {
                    current_voice->sample_present = 1;
                    l_json_get_string( (const char *)json_patch_information_buffer, &tokens[j + 1], (char *) current_voice->sample_path );
                    xil_printf("KEY[%d]: sample_path = %s\n\r", midi_note, current_voice->sample_path);
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

// This function populates the data structure that is going to be read via DMA
// by the PL to get the sample information
uint32_t ulConfigDMADataStructure( PATCH_DESCRIPTOR_t *patch_descriptor ) {
    int key        = 0;
    int vel_range  = 0;
    uint32_t error = 0;
    KEY_INFORMATION_t       *current_key   = NULL;
    KEY_VOICE_INFORMATION_t *current_voice = NULL;


    for (key = 0; key < MAX_NUM_OF_KEYS; key++) {

        if ( patch_descriptor->key_information[key] == NULL ) continue;

        current_key = patch_descriptor->key_information[key];

        for (vel_range = 0; vel_range < 1; vel_range++) {

            if ( current_key->key_voice_information[vel_range] == NULL ) continue;

            current_voice = current_key->key_voice_information[vel_range];

            if ( patch_descriptor->key_information[key]->key_voice_information[vel_range]->sample_present != 0 ) {
                error = ulDecodeRIFFInformation(
                                                current_voice->sample_buffer,
                                                current_voice->sample_size,
                                                &current_voice->sample_format
                                            );
                current_voice->current_status = 0;
                current_voice->current_slot   = 0;
                if ( error != 0 ) {
                    return error;
                }

                error = prv_ulRealignAudioData( current_voice );

            }
        }
    }

    return error;
}

// This function will load the samples of a descriptor into memory
uint32_t ulLoadSamplesFromDescriptor( PATCH_DESCRIPTOR_t *patch_descriptor, const char *json_file_root_dir ) {

    // Initialize the variables
    uint32_t key        = 0;
    uint32_t vel_range  = 0;    
    uint32_t file_size  = 0;

    char     full_path[MAX_PATH_LEN]; // Path to the sample

    patch_descriptor->total_size = 0;
    patch_descriptor->total_keys = 0;

    KEY_INFORMATION_t       *current_key;
    KEY_VOICE_INFORMATION_t *current_voice;

    for (key = 0; key < MAX_NUM_OF_KEYS; key++) {

        current_key = patch_descriptor->key_information[key];

        if ( current_key != NULL ) {

            for (vel_range = 0; vel_range < 1; vel_range++) {

                current_voice = current_key->key_voice_information[vel_range];

                if ( current_voice != NULL ) {
                    if ( current_voice->sample_present != 0 ) {

                        // Copy the full path
                        memset( full_path, 0x00, MAX_PATH_LEN );
                        strcat( full_path, json_file_root_dir);
                        strcat( full_path, "/");
                        strcat( full_path, (const char *) current_voice->sample_path);

                        current_voice->sample_buffer = NULL;
                        //xil_printf("[INFO] - [%d][%d] Loading Sample \"%s\"\n\r", key, vel_range, current_voice->sample_path );
                        xil_printf(".");
                        file_size = load_file_to_memory_malloc( 
                                                                full_path,
                                                                &current_voice->sample_buffer,
                                                                (size_t) MAX_SAMPLE_SIZE,
                                                                sizeof(uint32_t) // Overhead to allow realignment
                                                                );
                        
                        current_voice->sample_size = file_size;
                        patch_descriptor->total_size += file_size;
                        patch_descriptor->total_keys++;
                        if ( current_voice->sample_buffer == NULL || file_size == 0 ) {
                            xil_printf("\n\r");
                            return 1;                          
                        }
                    }
                }
            }
        }
    }

    xil_printf("\n\r");

    return 0;
}


// This function realigns the 16-bit audio data so that it can be properly accessed
// through DMA without complex HW implementations
uint32_t prv_ulRealignAudioData( KEY_VOICE_INFORMATION_t *voice_information ) {

    uint8_t *aligned_buffer_ptr = NULL;
    uint8_t *temp_data_buffer   = NULL;
    
    // Sanity check
    if ( voice_information == NULL ) return 1;
    if ( voice_information->sample_buffer == NULL ) return 1;
    if ( voice_information->sample_format.data_start_ptr == NULL ) return 1;
    if ( voice_information->sample_format.audio_data_size == 0 ) return 1;

    // Check if by chance the data is already aligned
    if ( ( (int) voice_information->sample_format.data_start_ptr % (int) 4) == 0 ) return 0;

    // If data needs realignment, copy the unaligned data to a temp memory location
    // and then copy back the data on the appropriate offset. Finally, release the memory

    // Step 1 - Malloc the required temoporary space
    aligned_buffer_ptr = voice_information->sample_format.data_start_ptr + ( (int) 4 - ( (int) voice_information->sample_format.data_start_ptr % (int) 4 ) );

    temp_data_buffer = sampler_malloc( (size_t) voice_information->sample_format.audio_data_size );
    // Fail if there's not enugh space for malloc
    if ( temp_data_buffer == NULL ) {
        xil_printf( "[ERROR] - Malloc for the temporary realignment buffer failed! Requested size = %d bytes", voice_information->sample_format.audio_data_size );
        return 1;
    }

    // Step 2 - Copy the contents
    memcpy( temp_data_buffer, voice_information->sample_format.data_start_ptr, (size_t) voice_information->sample_format.audio_data_size );

    // Step 3 - Copy back the contents
    memcpy( aligned_buffer_ptr, temp_data_buffer, (size_t) voice_information->sample_format.audio_data_size );

    // Step 4 - Free the temporary memory
    sampler_free( temp_data_buffer );

    // Step 5 - Assign the new pointer
    voice_information->sample_format.data_start_ptr = aligned_buffer_ptr;

    return 0;
}
