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
	{"Cx",   24}, // Starts From C1
	{"Cx_S", 25},
	{"Dx",   26},
	{"Dx_S", 27},
	{"Ex",   28},
	{"Fx",   29},
	{"Fx_S", 30},
	{"Gx",   31},
	{"Gx_S", 32}
};

static uint32_t        sampler_voices[MAX_VOICES];
static SAMPLER_VOICE_t sampler_voices_information[MAX_VOICES];


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

	if ( ( tok->type == JSMN_STRING ) && ( token_len <= 256 ) ) {
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
	uint32_t total_information_size = (total_size_of_keys * total_size_of_velocity_ranges) + sizeof(INSTRUMENT_INFORMATION_t);

	INSTRUMENT_INFORMATION_t* instrument_info = malloc( total_information_size );
	if ( instrument_info == NULL ) {
		xil_printf("[ERROR] - Memory allocation for the instrument info failed. Requested size = %d bytes", total_information_size);
		return NULL;
	}
	memset( instrument_info, '\0', total_information_size );

	return instrument_info;
}

// This function will decode the JSON file containing the
// instrument information and will populate the instrument data structures
uint32_t decode_instrument_information( uint8_t *instrument_info_buffer, INSTRUMENT_INFORMATION_t *instrument_info ) {
	jsmn_parser parser;
	jsmntok_t tokens[1000];
	int parser_result;

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
			xil_printf("Instrument Name: %s", instrument_info->instrument_name);
			xil_printf("\n\r");
			break;
		}
	}

}
