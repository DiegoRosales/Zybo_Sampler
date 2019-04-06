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
//	{"Cx",   24}, // Starts From C1
//	{"Cx_S", 25},
//	{"Dx",   26},
//	{"Dx_S", 27},
//	{"Ex",   28},
//	{"Fx",   29},
//	{"Fx_S", 30},
//	{"Gx",   31},
//	{"Gx_S", 32}
};

static uint32_t        sampler_voices[MAX_VOICES];
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
	char *token_str[256];
	memset( token_str, 0x00, 256 );

	if ( ( tok->type == JSMN_STRING ) && ( token_len <= 256 ) ) {
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

// This function will return the number
// of the voice slot available to start the playback
uint32_t get_available_voice_slot( void ) {
	for ( int i = 0 ; i < MAX_VOICES ; i++ ) {
		if ( sampler_voices[ i ] == 0 ) {
			sampler_voices[ i ] = 1;
			return i; // Return the slot number
		}
	}
	return 0xffffffff; // Return bad data
}

uint32_t get_sampler_version( void ) {
	return SAMPLER_CONTROL_REGISTER_ACCESS->SAMPLER_VER_REG.value;
}

// This function will trigger the playback of a voice based on the voice information
uint32_t start_voice_playback( uint32_t sample_addr, uint32_t sample_size ) {
	uint32_t voice_slot = 0;

	// Step 1 - Get a voice slot
	voice_slot = get_available_voice_slot();

	// Step 2 - Load the voice information data structure
	sampler_voices_information[voice_slot].voice_start_addr = sample_addr;
	sampler_voices_information[voice_slot].voice_size       = sample_size;
	//Xil_DCacheFlushRange(&sampler_voices_information[voice_slot].voice_start_addr, 64);
	Xil_DCacheFlush();

	// Step 3 - Write the voice information address to the register with the slot number
	SAMPLER_DMA_REGISTER_ACCESS->sampler_dma[voice_slot].dma_addr.value = &sampler_voices_information[voice_slot];
	
	// Step 4 - Start the DMA
	SAMPLER_DMA_REGISTER_ACCESS->sampler_dma[voice_slot].dma_control.value = 0;
	SAMPLER_DMA_REGISTER_ACCESS->sampler_dma[voice_slot].dma_control.value = 1;
	SAMPLER_DMA_REGISTER_ACCESS->sampler_dma[voice_slot].dma_control.value = 0;

	return voice_slot;
}

// This function will stop the playback of the voice
uint32_t stop_voice_playback( uint32_t voice_slot ) {
	// Stop the DMA
	SAMPLER_DMA_REGISTER_ACCESS->sampler_dma[voice_slot].dma_control.field.start = 0;
	SAMPLER_DMA_REGISTER_ACCESS->sampler_dma[voice_slot].dma_control.field.stop  = 1;

	// Release the voice slot
	sampler_voices [ voice_slot ] = 0;
	return 0;
}


// This function will initialize the data structure of an instrument
INSTRUMENT_INFORMATION_t* init_instrument_information( uint8_t number_of_keys, uint8_t number_of_velocity_ranges ) {
	uint32_t total_size_of_keys            = (uint32_t) number_of_keys * sizeof( KEY_INFORMATION_t );
	uint32_t total_size_of_velocity_ranges = (uint32_t) number_of_velocity_ranges * sizeof( KEY_VOICE_INFORMATION_t );
	uint32_t total_information_size        = sizeof(INSTRUMENT_INFORMATION_t); //(total_size_of_keys * total_size_of_velocity_ranges) + sizeof(INSTRUMENT_INFORMATION_t);

	INSTRUMENT_INFORMATION_t* instrument_info = malloc( total_information_size );
	if ( instrument_info == NULL ) {
		xil_printf("[ERROR] - Memory allocation for the instrument info failed. Requested size = %d bytes\n\r", total_information_size);
		return NULL;
	} else {
		xil_printf("[INFO] - Memory allocation for the instrument info succeeded. Memory location: 0x%x\n\r", instrument_info );
		int key       = 0;
		int vel_range = 0;

		// Initialize the structure
		memset( &instrument_info->instrument_name, "\00" , MAX_CHAR_IN_TOKEN_STR );

		for (key = 0; key < MAX_NUM_OF_KEYS; key++) {

			// If the key number exceeds the maximum requested, assign the address to 0
			if ( key >= number_of_keys ) {
				instrument_info->key_information[key] = NULL;
			} else {
				// Allocate a memory section for the key information
				instrument_info->key_information[key] = malloc( sizeof( KEY_INFORMATION_t ) );

				// If the memory allocation failed, throw an error
				if ( instrument_info->key_information[key] == NULL ) {
					xil_printf("[ERROR] - Memory allocation for the instrument info KEY[%d] failed. Requested size = %d bytes\n\r", key, sizeof( KEY_INFORMATION_t ));
					return NULL;	
				}

				// Allocate memory for each one of the velocity ranges
				for (vel_range = 0; vel_range < MAX_NUM_OF_VELOCITY; vel_range++) {

					// If the velocity range exceeds the one requested, assign the address to 0
					if ( vel_range >= number_of_velocity_ranges ) {
						instrument_info->key_information[key]->key_voice_information[vel_range] = NULL;
					} else {
						// Allocate a memory section for the sample information related to the velocity range
						instrument_info->key_information[key]->key_voice_information[vel_range] = malloc( sizeof( KEY_VOICE_INFORMATION_t ) );

						// If the memory allocation failed, throw an error
						if ( instrument_info->key_information[key]->key_voice_information[vel_range] == NULL ) {
							xil_printf("[ERROR] - Memory allocation for the instrument info KEY[%d][%d] failed. Requested size = %d bytes\n\r", key, vel_range, sizeof( KEY_VOICE_INFORMATION_t ));
							return NULL;	
						}

						// Initialize the data structure
						instrument_info->key_information[key]->key_voice_information[vel_range]->sample_present = 0;
						instrument_info->key_information[key]->key_voice_information[vel_range]->velocity_min   = 0;
						instrument_info->key_information[key]->key_voice_information[vel_range]->velocity_max   = 0;
						instrument_info->key_information[key]->key_voice_information[vel_range]->sample_addr    = 0;
						instrument_info->key_information[key]->key_voice_information[vel_range]->sample_size    = 0;
						memset( &instrument_info->key_information[key]->key_voice_information[vel_range]->sample_path, "\00", MAX_CHAR_IN_TOKEN_STR );
					}
				}
			}
		}

		xil_printf("[INFO] - Data Structure Initialized. Maximum number of keys = %d | Maximum number of velocity ranges = %d\n\r", number_of_keys, number_of_velocity_ranges );
	}
	//memset( instrument_info, '\0', total_information_size );

	return instrument_info;
}

uint8_t get_midi_note_number( jsmntok_t *tok, uint8_t *instrument_info_buffer ) {
	uint8_t midi_note = 0;

	uint8_t *note_letter_addr = instrument_info_buffer + tok->start;
	uint8_t *note_number_addr = note_letter_addr + 1;
	uint8_t *sharp_flag_addr  = note_letter_addr + 3;

	uint8_t note_letter = *note_letter_addr;
	uint8_t note_number = *note_number_addr;
	uint8_t sharp_flag  = *sharp_flag_addr;

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

// This function will extract the sample paths from the information file
uint32_t extract_sample_paths( uint32_t sample_start_token_index, uint32_t number_of_samples, jsmntok_t *tokens, uint8_t *instrument_info_buffer, INSTRUMENT_INFORMATION_t *instrument_info ) {
	uint8_t midi_note;
	uint8_t *sample_path_addr;
	uint32_t note_name_index;
	uint32_t key_info_index;

	//for( int i = sample_start_token_index; i < (number_of_samples * NUM_OF_SAMPLE_JSON_MEMBERS * 2); i = i + (NUM_OF_SAMPLE_JSON_MEMBERS * 2) + 1 ) {
	for( int i = 0; i < number_of_samples ; i++) {
		note_name_index = sample_start_token_index + (i * (NUM_OF_SAMPLE_JSON_MEMBERS + 1) * 2);
		key_info_index  = note_name_index + 2;
		// Get the MIDI note
		midi_note = get_midi_note_number(&tokens[note_name_index], instrument_info_buffer);

		if ( midi_note < 88 ) {
			sample_path_addr = &instrument_info->key_information[midi_note]->key_voice_information[0]->sample_path;
			// Get the rest of the information
			for( int j = key_info_index; j < ( key_info_index + (NUM_OF_SAMPLE_JSON_MEMBERS * 2) ); j += 2 ) {
				if( jsoneq( (const char *)instrument_info_buffer, &tokens[j], SAMPLE_VEL_MIN_TOKEN_STR ) ) {
					instrument_info->key_information[midi_note]->key_voice_information[0]->velocity_min = str2int( (char *)(instrument_info_buffer + tokens[j + 1].start), ( tokens[j + 1].end - tokens[j + 1].start ) );
					//xil_printf("KEY[%d]: velocity_min = %d\n\r", midi_note, instrument_info->key_information[midi_note].key_voice_information[0].velocity_min);
				} else if( jsoneq( (const char *)instrument_info_buffer, &tokens[j], SAMPLE_VEL_MAX_TOKEN_STR ) ) {
					instrument_info->key_information[midi_note]->key_voice_information[0]->velocity_max = str2int( (char *)(instrument_info_buffer + tokens[j + 1].start), ( tokens[j + 1].end - tokens[j + 1].start ) );
					//xil_printf("KEY[%d]: velocity_max = %d\n\r", midi_note, instrument_info->key_information[midi_note].key_voice_information[0].velocity_max);
				} else if( jsoneq( (const char *)instrument_info_buffer, &tokens[j], SAMPLE_PATH_TOKEN_STR ) ) {
					instrument_info->key_information[midi_note]->key_voice_information[0]->sample_present = 1;
					json_snprintf( (const char *)instrument_info_buffer, &tokens[j + 1], (char *)sample_path_addr );
					xil_printf("KEY[%d]: sample_path = %s\n\r", midi_note, instrument_info->key_information[midi_note]->key_voice_information[0]->sample_path);
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
