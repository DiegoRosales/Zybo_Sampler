//////////////////////////////////////
// RIFF Utilities
//////////////////
// Utilities to manipulate RIFF samples in memory
//////////////////////////////////////

// C includes
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

// Xilinx Includes
#include "xil_io.h"

// Sampler includes
#include "sampler_cfg.h"
#include "riff_utils.h"

// Read the first RIFF chunk
static void prv_vReadRIFFChunck( uint8_t * buffer, RIFF_DESCRIPTOR_CHUNK_t * chunk ) {
    memcpy( chunk, buffer, sizeof( RIFF_DESCRIPTOR_CHUNK_t ) );
}


// Find the audio data of a WAVE chunk
static void prv_vFindWAVEData( uint8_t * buffer, uint8_t * buffer_end, SAMPLE_FORMAT_t *sample_information ) {

    RIFF_BASE_CHUNK_t  current_chunk;
    uint8_t          * current_buffer_idx = buffer;

    // Step 1 - Get the Chunk size
    memcpy( &current_chunk, current_buffer_idx, sizeof( RIFF_BASE_CHUNK_t ) );

    // Check the entire file for the "DATA" ID token
    while( current_buffer_idx <= buffer_end ){

        // If the token is found, copy the pointers and information
        if( current_chunk.ChunkID == DATA_ASCII_TOKEN ) {
            sample_information->audio_data_size = current_chunk.ChunkSize;
            sample_information->data_start_ptr  = current_buffer_idx + sizeof( RIFF_BASE_CHUNK_t );
            break;
        }
        // If the token is not found, go to the next chunk
        else {
            current_buffer_idx += current_chunk.ChunkSize + sizeof( RIFF_BASE_CHUNK_t );
            if( current_buffer_idx <= buffer_end ){
                memcpy( &current_chunk, current_buffer_idx, sizeof( RIFF_BASE_CHUNK_t ) );
            }
        }
    }
}

// This function will extract the information based on the canonical wave format
void vDecodeRIFFInformation( uint8_t *riff_buffer, size_t riff_buffer_size, SAMPLE_FORMAT_t *sample_information ) {

    WAVE_FORMAT_t             wave_format_data;
    RIFF_DESCRIPTOR_CHUNK_t   main_riff_chunk;
    uint8_t                 * riff_buffer_idx = NULL;

    // Step 1 - Check that the inputs are valid
    if( riff_buffer == NULL ) {
        xil_printf("[ERROR] - Error while extracting the RIFF information. Sample buffer = NULL\n\r");
        return;
    }

    if( riff_buffer_size <= (sizeof( WAVE_FORMAT_t ) + sizeof( RIFF_BASE_CHUNK_t ) ) ) {
        xil_printf("[ERROR] - Error while extracting the RIFF information. Sample buffer size is too small. Sample size = %d\n\r", riff_buffer_size);
        return;
    }

    if( sample_information == NULL ) {
        xil_printf("[ERROR] - Error while extracting the RIFF information. Pointer to the riff information = NULL\n\r");
        return;
    }

    sample_information->data_start_ptr  = NULL; // Initialize to 0
    sample_information->audio_data_size = 0;    // Initialize to 0

    // Step 1 - Read the first chunk. Must contain "RIFF"
    prv_vReadRIFFChunck( riff_buffer, &main_riff_chunk );

    // Step 2 - Check that this is a RIFF file with proper format
    if( main_riff_chunk.BaseChunk.ChunkID != RIFF_ASCII_TOKEN ) {
        xil_printf("[ERROR] - Error while parsing the RIFF information. Buffer is not RIFF.\n\r");
        return;
    }

    //Step 3 - Copy the base information
    if( main_riff_chunk.FormType == WAVE_ASCII_TOKEN ) { // If it is a WAVE file
        memcpy( &wave_format_data, riff_buffer, sizeof( WAVE_FORMAT_t ) );

        if( wave_format_data.FormatDescriptor.BaseChunk.ChunkID != FMT_ASCII_TOKEN ) {
            xil_printf("[ERROR] - Error while parsing the RIFF information. Subc Chunk 1 is not \"fmt \".\n\r");
            return;
        }

        // Step 3.1 - Extract the base information
        sample_information->audio_format       = wave_format_data.FormatDescriptor.AudioFormat;
        sample_information->number_of_channels = wave_format_data.FormatDescriptor.NumChannels;
        sample_information->sample_rate        = wave_format_data.FormatDescriptor.SampleRate;
        sample_information->byte_rate          = wave_format_data.FormatDescriptor.ByteRate;
        sample_information->block_align        = wave_format_data.FormatDescriptor.BlockAlign;
        sample_information->bits_per_sample    = wave_format_data.FormatDescriptor.BitsPerSample;

        // Step 3.2 - Find the "DATA" chunk and get the pointer
        // Current index is where the Format chunk finished
        riff_buffer_idx = riff_buffer + wave_format_data.FormatDescriptor.BaseChunk.ChunkSize + sizeof( RIFF_DESCRIPTOR_CHUNK_t ) + sizeof( RIFF_BASE_CHUNK_t );
        prv_vFindWAVEData( riff_buffer_idx, (riff_buffer + riff_buffer_size),  sample_information);

        if( sample_information->data_start_ptr == NULL ) {
            xil_printf("[ERROR] - Couldn't find the DATA chunk!\n\r");
            return;
        } else if ( sample_information->audio_data_size == 0 ) {
            xil_printf("[ERROR] - Audio Data Size = 0!\n\r");
            return;
        }

    } else {
        xil_printf("[ERROR] - Error while parsing the RIFF information. Buffer format is not WAVE.\n\r");
        return;
    }
}
