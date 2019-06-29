////////////////////////////////////////////////////////
// Sampler Driver
////////////////////////////////////////////////////////
// Xilinx Includes
#include "xil_io.h"

//information about AXI peripherals
#include "xparameters.h"

// Sampler Includes
#include "sampler.h"

// JSON Parser
#include "jsmn.h"

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

static VOICE_TRK_t     sampler_voices[MAX_VOICES];
static uint8_t         last_voice_slot;
static uint8_t         number_of_active_slots;
static SAMPLER_VOICE_t sampler_voices_information[MAX_VOICES];


// This function converts an string in int or hex to a uint32_t
static uint32_t str2int( char *input_string, uint32_t input_string_length ) {

    char *start_char = input_string;
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

static int jsoneq(const char *json, jsmntok_t *tok, const char *s) {
    int token_end   = tok->end;
    int token_start = tok->start;
    int token_len   = token_end - token_start;
    if ( ( tok->type == JSMN_STRING ) && ( ( (int) strlen(s) ) == ( token_len ) ) && ( strncmp( json + token_start, s, token_len ) == 0 ) ) {
        return 1;
    }
    return 0;
}

static int jsonprint(const char *json, jsmntok_t *tok) {
    int token_end        = tok->end;
    int token_start      = tok->start;
    int token_len        = token_end - token_start + 1;
    char *token_str[MAX_CHAR_IN_TOKEN_STR];
    memset( token_str, 0x00, (MAX_CHAR_IN_TOKEN_STR * sizeof(char)) );

    if ( ( tok->type == JSMN_STRING ) && ( token_len <= MAX_CHAR_IN_TOKEN_STR ) ) {
        snprintf( token_str, token_len, json + token_start );
        xil_printf( token_str );
        return 0;
    }
    return 1;
}

static int json_snprintf(const char *json, jsmntok_t *tok, char *output_buffer) {
    int token_end        = tok->end;
    int token_start      = tok->start;
    int token_len        = token_end - token_start + 1;
    memset( output_buffer, 0x00, MAX_CHAR_IN_TOKEN_STR );

    if ( ( tok->type == JSMN_STRING ) && ( token_len < MAX_CHAR_IN_TOKEN_STR ) ) {
        snprintf( output_buffer, token_len, json + token_start );
        return 0;
    }
    return 1;
}

uint32_t SamplerRegWr(uint32_t addr, uint32_t value, uint32_t check) {
    uint32_t readback  = 0;
    uint32_t ok        = 0;
    uint32_t full_addr = GET_SAMPLER_FULL_ADDR(addr);

    Xil_Out32(full_addr, value);

    if(check) {
        readback = Xil_In32(full_addr);
        ok       = (readback == value);
    }

    return ok;
}

uint32_t SamplerRegRd(uint32_t addr) {
    uint32_t readback  = 0;
    uint32_t full_addr = GET_SAMPLER_FULL_ADDR(addr);

    readback = Xil_In32(full_addr);

    return readback;
}

// Initialize the sampler registers
void sampler_init ( void ) {

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
uint16_t get_available_voice_slot( void ) {
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

    // Step 4 - Enable the slot
    sampler_voices[ current_slot ].slot_is_last    = 1;
    sampler_voices[ current_slot ].voice_is_active = 1;
    last_voice_slot                                = current_slot;
    number_of_active_slots                         = number_of_active_slots + 1;


    return current_slot;
}

void release_slot( uint16_t slot ) {
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
        last_voice_slot                            = 0;
        number_of_active_slots                     = 0;
        return;
    }

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

    return;

} 

uint32_t get_sampler_version( void ) {
    return SAMPLER_CONTROL_REGISTER_ACCESS->SAMPLER_VER_REG.value;
}

// This function will trigger the playback of a voice based on the voice information
uint32_t start_voice_playback( uint32_t sample_addr, uint32_t sample_size ) {
    uint32_t voice_slot          = 0;
    uint32_t previous_voice_slot = 0;
    uint32_t number_of_samples   = 0;
    SAMPLER_DMA_CONTROL_REG_t temp_ctrl_reg;
    SAMPLER_DMA_CONTROL_REG_t temp_ctrl_reg2;


    // Step 1 - Get a voice slot
    voice_slot = get_available_voice_slot();
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
uint32_t stop_voice_playback( uint32_t voice_slot ) {
    uint32_t                  previous_voice_slot = 0;
    SAMPLER_DMA_CONTROL_REG_t temp_ctrl_reg;

    // Sanity check
    if( voice_slot >= MAX_VOICES ) return 1;
    
    SAMPLER_DMA_REGISTERS_t temp_reg;

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
    //SAMPLER_DMA_REGISTER_ACCESS->sampler_dma[voice_slot].dma_next_sample.value = 0;

    // Release the voice slot
    release_slot( voice_slot );

    return 0;
}

// This function stops the playback for everything
uint32_t stop_all( INSTRUMENT_INFORMATION_t *instrument_information ) {
    KEY_INFORMATION_t       *current_key    = NULL;
    KEY_VOICE_INFORMATION_t *current_voice  = NULL;
    uint32_t                 key            = 0;
    uint32_t                 velocity_range = 0;
    uint32_t                 voice_slot     = 0;

    // Stop the engine
    SAMPLER_CONTROL_REGISTER_ACCESS->SAMPLER_CONTROL_REG.value = SAMPLER_CONTROL_STOP;

    // Stop the playback
    for ( voice_slot = 0; voice_slot < MAX_VOICES; voice_slot++ ) stop_voice_playback( voice_slot );

    if( instrument_information == NULL ) return 0;

    // Reset the flags
    for (key = 0; key < MAX_NUM_OF_KEYS; key++) {
        if( instrument_information->key_information[key] == NULL ) continue;

        current_key = instrument_information->key_information[key];

        for ( velocity_range = 0; velocity_range < MAX_NUM_OF_VELOCITY; velocity_range++ ) {

            if( current_key->key_voice_information[velocity_range] == NULL ) continue;

            current_voice = current_key->key_voice_information[velocity_range];

            if ( current_voice->current_status != 0 ) {
                xil_printf("[INFO] - [%d][%d] Stopping voice playback of slot %d\n\r", key, velocity_range, current_voice->current_slot);
                current_voice->current_status = 0;
                current_voice->current_slot   = 0;
            }
        }
    }

    return 0;

}

// This function starts the playback of a sample given the key/velocity parameters and the instrument information
uint32_t play_instrument_key( uint8_t key, uint8_t velocity, INSTRUMENT_INFORMATION_t *instrument_information ) {

    int                      velocity_range = 0;
    KEY_INFORMATION_t       *current_key = NULL;
    KEY_VOICE_INFORMATION_t *current_voice = NULL;
    uint32_t                 voice_slot = 0;

    // Sanity check

    if ( instrument_information == NULL ) {
        xil_printf("[ERROR] - Instrument information = NULL\n\r");
        return 1;
    }

    if ( instrument_information->instrument_loaded == 0 ) {
        xil_printf("[ERROR] - No instrument has been loaded\n\r");
        return 1;		
    }

    if ( instrument_information->key_information[key] == NULL ) {
        xil_printf("[ERROR] - There is no information related to this key: %d\n\r", key);
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
                xil_printf("[INFO] - Stopping voice playback of slot %d\n\r", current_voice->current_slot);
                stop_voice_playback( current_voice->current_slot );
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
            xil_printf("[ERROR] - Current sample is being played on slot %d\n\r", current_voice->current_slot);
            return 3;
        }

        // Check if sample is present
        if ( current_voice->sample_present == 0 ) {
            xil_printf("[ERROR] - There's no sample for the specified velocity! %d\n\r", current_voice->current_slot);
            return 2;
        }

        // Start playback
        voice_slot = start_voice_playback( (uint32_t) current_voice->sample_format.data_start_ptr, // Audio data pointer
                                                      current_voice->sample_format.audio_data_size // Audio data size
                                            );
        
        // If there are no available slots, don't update the status
        if ( voice_slot == 0xffff ) {
            xil_printf("[ERROR] - No available slots found! %d\n\r", voice_slot);
            break;
        }

        xil_printf("[INFO] - Started playback on slot %d\n\r", voice_slot);

        current_voice->current_slot   = voice_slot;
        current_voice->current_status = 1;
        break;
    }

    return 0;

}

// Initialize key voice information
KEY_VOICE_INFORMATION_t *init_voice_information() {

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
KEY_INFORMATION_t * init_key_information( ) {

    KEY_INFORMATION_t *key_information = sampler_malloc( sizeof( KEY_INFORMATION_t ) );

    // Sanity check
    if( key_information == NULL ){
        xil_printf( "[ERROR] - Memory allocation for the Key Information failed!" );
        return NULL;
    }

    memset( key_information, 0x00, sizeof( KEY_INFORMATION_t ) );

    return key_information;
}

// This function will initialize the data structure of an instrument
INSTRUMENT_INFORMATION_t* init_instrument_information() {

    INSTRUMENT_INFORMATION_t* instrument_info = sampler_malloc( sizeof(INSTRUMENT_INFORMATION_t) );
    if ( instrument_info == NULL ) {
        xil_printf("[ERROR] - Memory allocation for the instrument info failed. Requested size = %d bytes\n\r", sizeof(INSTRUMENT_INFORMATION_t));
        return NULL;
    } else {
        xil_printf("[INFO] - Memory allocation for the instrument info succeeded. Memory location: 0x%x\n\r", instrument_info );
        int key       = 0;
        int vel_range = 0;

        // Initialize the structure
        memset( instrument_info, 0x00 , sizeof(INSTRUMENT_INFORMATION_t) );
    }

    return instrument_info;
}

uint8_t get_json_midi_note_number( jsmntok_t *tok, uint8_t *instrument_info_buffer ) {
    uint8_t midi_note = 0;

    uint8_t *note_letter_addr = instrument_info_buffer + tok->start;
    uint8_t *note_number_addr = note_letter_addr + 1;
    uint8_t *sharp_flag_addr  = note_letter_addr + 3;

    char note_letter = (char) *note_letter_addr;
    char note_number = (char) *note_number_addr;
    char sharp_flag  = (char) *sharp_flag_addr;

    uint32_t note_number_int = str2int( &note_number, 1 );

    for( int i = 0; i < 12; i++ ) {
        if( MIDI_NOTES_LUT[i].note_name[0] == note_letter ) {
            //if( note_letter != 'A' && note_letter != 'B' ) {
            //	note_number_int--;
            //}
            midi_note = MIDI_NOTES_LUT[i].note_number + (12 * note_number_int);
            if ( sharp_flag == 'S' ) {
                midi_note++;
            }
            return midi_note;
        }
    }
    return 0;
}

uint8_t get_midi_note_number( char *note_name ) {
    uint8_t midi_note = 0;

    char *note_letter = note_name;
    char *note_number = note_letter + 1;
    char *sharp_flag  = note_letter + 3;

    uint32_t note_number_int = str2int( note_number, 1 );

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

// This function will extract the sample paths from the information file
// This will also allocate and initialize the information when it hasn't been allocated yet
uint32_t extract_sample_paths( uint32_t sample_start_token_index, uint32_t number_of_samples, jsmntok_t *tokens, uint8_t *instrument_info_buffer, INSTRUMENT_INFORMATION_t *instrument_info ) {
    uint8_t midi_note;
    uint32_t note_name_index;
    uint32_t key_info_index;

    KEY_INFORMATION_t       *current_key   = NULL;
    KEY_VOICE_INFORMATION_t *current_voice = NULL;

    //for( int i = sample_start_token_index; i < (number_of_samples * NUM_OF_SAMPLE_JSON_MEMBERS * 2); i = i + (NUM_OF_SAMPLE_JSON_MEMBERS * 2) + 1 ) {
    for( int i = 0; i < number_of_samples ; i++) {
        note_name_index = sample_start_token_index + (i * (NUM_OF_SAMPLE_JSON_MEMBERS + 1) * 2);
        key_info_index  = note_name_index + 2;
        // Get the MIDI note
        midi_note = get_json_midi_note_number(&tokens[note_name_index], instrument_info_buffer);

        if ( midi_note < MAX_NUM_OF_KEYS ) {

            // Allocate the memory if the key information doesn't exist
            if( instrument_info->key_information[midi_note] == NULL ) {
                instrument_info->key_information[midi_note] = init_key_information();
                if( instrument_info->key_information[midi_note] == NULL ) return 0;
            }

            current_key = instrument_info->key_information[midi_note];

            // TODO: Add multiple velocity switches
            if( current_key->key_voice_information[0] == NULL ) {
                current_key->key_voice_information[0] = init_voice_information();
                if( current_key->key_voice_information[0] == NULL ) return 0;
            }

            current_voice = current_key->key_voice_information[0];

            // Get the rest of the information
            for( int j = key_info_index; j < ( key_info_index + (NUM_OF_SAMPLE_JSON_MEMBERS * 2) ); j += 2 ) {
                if( jsoneq( (const char *)instrument_info_buffer, &tokens[j], SAMPLE_VEL_MIN_TOKEN_STR ) ) {
                    current_voice->velocity_min = str2int( (char *)(instrument_info_buffer + tokens[j + 1].start), ( tokens[j + 1].end - tokens[j + 1].start ) );
                    //xil_printf("KEY[%d]: velocity_min = %d\n\r", midi_note, instrument_info->key_information[midi_note].key_voice_information[0].velocity_min);
                } else if( jsoneq( (const char *)instrument_info_buffer, &tokens[j], SAMPLE_VEL_MAX_TOKEN_STR ) ) {
                    current_voice->velocity_max = str2int( (char *)(instrument_info_buffer + tokens[j + 1].start), ( tokens[j + 1].end - tokens[j + 1].start ) );
                    //xil_printf("KEY[%d]: velocity_max = %d\n\r", midi_note, instrument_info->key_information[midi_note].key_voice_information[0].velocity_max);
                } else if( jsoneq( (const char *)instrument_info_buffer, &tokens[j], SAMPLE_PATH_TOKEN_STR ) ) {
                    current_voice->sample_present = 1;
                    json_snprintf( (const char *)instrument_info_buffer, &tokens[j + 1], current_voice->sample_path );
                    xil_printf("KEY[%d]: sample_path = %s\n\r", midi_note, current_voice->sample_path);
                }
            }
        }
    }

}


// This function will decode the JSON file containing the
// instrument information and will populate the instrument data structures
uint32_t decode_instrument_information( uint8_t *instrument_info_buffer, INSTRUMENT_INFORMATION_t *instrument_info ) {
    jsmn_parser parser;
    jsmntok_t tokens[1000];
    int parser_result;
    uint32_t number_of_samples;
    uint32_t sample_start_token_index;

    // Step 1 - Initialize the parser
    jsmn_init(&parser);


    // Step 2 - Parse the buffer
    // js - pointer to JSON string
    // tokens - an array of tokens available
    // 1000 - number of tokens available
    parser_result = jsmn_parse(&parser, instrument_info_buffer, strlen(instrument_info_buffer), tokens, 1000);

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
        if ( jsoneq( instrument_info_buffer, &tokens[i], INSTRUMENT_NAME_TOKEN_STR ) ) {
            json_snprintf(instrument_info_buffer, &tokens[i + 1], instrument_info->instrument_name );
            xil_printf("Instrument Name: %s", instrument_info->instrument_name );
            xil_printf("\n\r");
            break;
        }
    }

    // Step 4.2 - Extract the sample paths
    for ( int i = 0; i < parser_result ; i++ ) {
        if ( jsoneq( instrument_info_buffer, &tokens[i], INSTRUMENT_SAMPLES_TOKEN_STR ) ) {
            number_of_samples        = (uint32_t) tokens[i + 1].size;
            sample_start_token_index = i + 2;
            xil_printf("Number of samples: %d\n\r", number_of_samples );
            extract_sample_paths( sample_start_token_index, number_of_samples, tokens, instrument_info_buffer, instrument_info );
            break;
        }
    }

}

// This function will extract the information based on the canonical wave format
uint32_t get_riff_information( uint8_t *sample_buffer, size_t sample_size, SAMPLE_FORMAT_t *riff_information ) {

    WAVE_FORMAT_t     wave_format_data;
    WAVE_BASE_CHUNK_t current_chunk;
    uint8_t          *sample_buffer_idx = NULL;

    // Step 1 - Check that the inputs are valid
    if( sample_buffer == NULL ) {
        xil_printf("[ERROR] - Error while extracting the RIFF information. Sample buffer = NULL\n\r");
        return 1;
    }

    if( sample_size <= (sizeof( WAVE_FORMAT_t ) + sizeof( WAVE_BASE_CHUNK_t ) ) ) {
        xil_printf("[ERROR] - Error while extracting the RIFF information. Sample buffer size is too small. Sample size = %d\n\r", sample_size);
        return 1;
    }

    if( riff_information == NULL ) {
        xil_printf("[ERROR] - Error while extracting the RIFF information. Pointer to the riff information = NULL\n\r");
        return 1;
    }

    // Step 2 - Copy the base information
    memcpy( &wave_format_data, sample_buffer, sizeof( WAVE_FORMAT_t ) );

    // Step 3 - Check that this is a RIFF file with proper format
    if( wave_format_data.RiffDescriptor.BaseChunk.ChunkID != RIFF_ASCII_TOKEN ) {
        xil_printf("[ERROR] - Error while parsing the RIFF information. Buffer is not RIFF.\n\r");
        return 2;
    }

    if( wave_format_data.RiffDescriptor.Format != FORMAT_ASCII_TOKEN ) {
        xil_printf("[ERROR] - Error while parsing the RIFF information. Buffer format is not WAVE.\n\r");
        return 2;       
    }

    if( wave_format_data.FormatDescriptor.BaseChunk.ChunkID != FMT_ASCII_TOKEN ) {
        xil_printf("[ERROR] - Error while parsing the RIFF information. Subc Chunk 1 is not \"fmt \".\n\r");
        return 2;       
    }


    // Step 4 - Extract the base information
    riff_information->audio_format       = wave_format_data.FormatDescriptor.AudioFormat;
    riff_information->number_of_channels = wave_format_data.FormatDescriptor.NumChannels;
    riff_information->sample_rate        = wave_format_data.FormatDescriptor.SampleRate;
    riff_information->byte_rate          = wave_format_data.FormatDescriptor.ByteRate;
    riff_information->block_align        = wave_format_data.FormatDescriptor.BlockAlign;
    riff_information->bits_per_sample    = wave_format_data.FormatDescriptor.BitsPerSample;
    riff_information->audio_data_size    = 0;    // Initialize to 0
    riff_information->data_start_ptr     = NULL; // Initialize to 0   

    // Step 5 - Find the "DATA" chunk and get the pointer

    // Current index is where the Format chunk finished
    sample_buffer_idx = sample_buffer + wave_format_data.FormatDescriptor.BaseChunk.ChunkSize + sizeof( RIFF_DESCRIPTOR_CHUNK_t ) + sizeof( WAVE_BASE_CHUNK_t );
    memcpy( &current_chunk, sample_buffer_idx, sizeof( WAVE_BASE_CHUNK_t ) );

    // Check the entire file for the "DATA" ID token
    while( sample_buffer_idx <= ( sample_buffer + sample_size ) ){

        // If the token is found, copy the pointers and information
        if( current_chunk.ChunkID == DATA_ASCII_TOKEN ) {
            riff_information->audio_data_size = current_chunk.ChunkSize;
            riff_information->data_start_ptr  = sample_buffer_idx + sizeof( WAVE_BASE_CHUNK_t );
            break;
        } 
        // If the token is not found, go to the next chunk
        else {
            sample_buffer_idx += current_chunk.ChunkSize + sizeof( WAVE_BASE_CHUNK_t );
            if( sample_buffer_idx <= ( sample_buffer + sample_size ) ){
                memcpy( &current_chunk, sample_buffer_idx, sizeof( WAVE_BASE_CHUNK_t ) );
            }
        }
    }

    if( riff_information->data_start_ptr == NULL ) {
        xil_printf("[ERROR] - Couldn't find the DATA chunk!\n\r");
        return 3;
    } else if ( riff_information->audio_data_size == 0 ) {
        xil_printf("[ERROR] - Audio Data Size = 0!\n\r");
        return 3;
    }

    return 0;

}

// This function realigns the 16-bit audio data so that it can be properly accessed
// through DMA without complex HW implementations
uint32_t realign_audio_data( KEY_VOICE_INFORMATION_t *voice_information ) {

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

// This function populates the data structure that is going to be read via DMA
// by the PL to get the sample information
uint32_t load_sample_information( INSTRUMENT_INFORMATION_t *instrument_information ) {
    int key        = 0;
    int vel_range  = 0;
    uint32_t error = 0;
    KEY_INFORMATION_t       *current_key   = NULL;
    KEY_VOICE_INFORMATION_t *current_voice = NULL;


    for (key = 0; key < MAX_NUM_OF_KEYS; key++) {

        if ( instrument_information->key_information[key] == NULL ) continue;

        current_key = instrument_information->key_information[key];

        for (vel_range = 0; vel_range < 1; vel_range++) {

            if ( current_key->key_voice_information[vel_range] == NULL ) continue;

            current_voice = current_key->key_voice_information[vel_range];

            if ( instrument_information->key_information[key]->key_voice_information[vel_range]->sample_present != 0 ) {
                error = get_riff_information(
                                                current_voice->sample_buffer,
                                                current_voice->sample_size,
                                                &current_voice->sample_format
                                            );
                current_voice->current_status = 0;
                current_voice->current_slot   = 0;
                if ( error != 0 ) {
                    return error;
                }

                error = realign_audio_data( current_voice );

            }
        }
    }

    return error;
}
