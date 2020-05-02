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

// This function will extract the information based on the canonical wave format
uint32_t ulDecodeRIFFInformation( uint8_t *sample_buffer, size_t sample_size, SAMPLE_FORMAT_t *riff_information ) {

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
