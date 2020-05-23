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
#include "soundfont.h"
#include "riff_utils.h"

// Static functions
static void prv_vPrintPHDR( SF_DESCRIPTOR_t * sf_descriptor );
static void prv_vPrintSHDR( SF_DESCRIPTOR_t * sf_descriptor );
static void prv_vSF2DecodeINFO( uint8_t * info_chunk_buffer, size_t info_chunk_buffer_len, SF_DESCRIPTOR_t * sf_descriptor );
static void prv_vSF2DecodeSDTA( uint8_t * sdta_chunk_buffer, size_t sdta_chunk_buffer_len, SF_DESCRIPTOR_t * sf_descriptor  );
static void prv_vSF2DecodePDTA( uint8_t * pdta_chunk_buffer, size_t pdta_chunk_buffer_len, SF_DESCRIPTOR_t * sf_descriptor  );
// Find the audio data of a WAVE chunk
static void prv_vFindWAVEData( uint8_t * buffer, uint8_t * buffer_end, SAMPLE_FORMAT_t *sample_information ) {

    RIFF_BASE_CHUNK_t * current_chunk;
    uint8_t           * current_buffer_idx = buffer;

    // Initialize
    sample_information->data_start_ptr  = NULL; // Initialize to 0
    sample_information->audio_data_size = 0;    // Initialize to 0

    // Step 1 - Get the Chunk size
    current_chunk = cmdGET_RIFF_BASE_CHUNK(buffer);

    // Check the entire file for the "DATA" ID token
    while( current_buffer_idx <= buffer_end ){

        // If the token is found, copy the pointers and information
        if( current_chunk->ChunkID == DATA_ASCII_TOKEN ) {
            sample_information->audio_data_size = current_chunk->ChunkSize;
            sample_information->data_start_ptr  = current_buffer_idx + sizeof( RIFF_BASE_CHUNK_t );
            break;
        }
        // If the token is not found, go to the next chunk
        else {
            current_buffer_idx += current_chunk->ChunkSize + sizeof( RIFF_BASE_CHUNK_t );
            if( current_buffer_idx <= buffer_end ){
                current_chunk = cmdGET_RIFF_BASE_CHUNK(current_buffer_idx);
            }
        }
    }
}

// This function will extract the information based on the canonical wave format
void vDecodeWAVEInformation( uint8_t *riff_buffer, size_t riff_buffer_size, SAMPLE_FORMAT_t *sample_information ) {

    WAVE_FORMAT_t             wave_format_data;
    RIFF_DESCRIPTOR_CHUNK_t * main_riff_chunk;
    uint8_t                 * riff_buffer_idx = NULL;

    // Step 1 - Check that the inputs are valid
    if( riff_buffer == NULL ) {
        RIFF_PRINTF_ERROR("Error while extracting the RIFF information. Sample buffer = NULL");
        return;
    }

    if( riff_buffer_size <= (sizeof( WAVE_FORMAT_t ) + sizeof( RIFF_BASE_CHUNK_t ) ) ) {
        RIFF_PRINTF_ERROR("Error while extracting the RIFF information. Sample buffer size is too small. Sample size = %d", riff_buffer_size);
        return;
    }

    if( sample_information == NULL ) {
        RIFF_PRINTF_ERROR("Error while extracting the RIFF information. Pointer to the riff information = NULL");
        return;
    }

    sample_information->data_start_ptr  = NULL; // Initialize to 0
    sample_information->audio_data_size = 0;    // Initialize to 0

    // Step 1 - Read the first chunk. Must contain "RIFF"
    main_riff_chunk = cmdGET_RIFF_DESCRIPTOR_CHUNK(riff_buffer);

    // Step 2 - Check that this is a RIFF file with proper format
    if( main_riff_chunk->BaseChunk.ChunkID != RIFF_ASCII_TOKEN ) {
        RIFF_PRINTF_ERROR("Error while parsing the RIFF information. Buffer is not RIFF.");
        return;
    }

    //Step 3 - Copy the base information
    if( main_riff_chunk->FormType == WAVE_ASCII_TOKEN ) { // If it is a WAVE file
        memcpy( &wave_format_data, riff_buffer, sizeof( WAVE_FORMAT_t ) );

        if( wave_format_data.FormatDescriptor.BaseChunk.ChunkID != FMT_ASCII_TOKEN ) {
            RIFF_PRINTF_ERROR("Error while parsing the RIFF information. Subc Chunk 1 is not \"fmt \".");
            return;
        }

        // Step 3.1 - Extract the base information
        sample_information->sample_file_format = SAMPLE_FORMAT_WAVE;
        sample_information->sample_file_buffer = riff_buffer;
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
            RIFF_PRINTF_ERROR("Couldn't find the DATA chunk!");
            return;
        } else if ( sample_information->audio_data_size == 0 ) {
            RIFF_PRINTF_ERROR("Audio Data Size = 0!");
            return;
        }

    } else {
        RIFF_PRINTF_ERROR("Error while parsing the RIFF information. Buffer format is not WAVE.");
        return;
    }
}

// Print SF2 Information
void vPrintSF2Info( uint8_t* sf2_buffer, size_t sf2_buffer_len ) {

    RIFF_DESCRIPTOR_CHUNK_t      * riff_descriptor_chunk = NULL;
    RIFF_BASE_CHUNK_t            * curr_chunk            = NULL;
    RIFF_LIST_DESCRIPTOR_CHUNK_t * curr_list_chunk       = NULL;
    uint8_t                      * current_buffer_ptr    = NULL;
    uint8_t                      * current_sub_chunk_ptr = NULL;
    size_t                         current_sub_chunk_len = 0;
    SF_DESCRIPTOR_t                sf_descriptor;

    riff_descriptor_chunk = cmdGET_RIFF_DESCRIPTOR_CHUNK(sf2_buffer);

    if( riff_descriptor_chunk->BaseChunk.ChunkID != RIFF_ASCII_TOKEN ) {
        RIFF_PRINTF_ERROR("Error while parsing the RIFF information. Buffer is not RIFF.");
        return;
    }

    if( riff_descriptor_chunk->FormType != SFBK_ASCII_TOKEN ) {
        RIFF_PRINTF_ERROR("Error while parsing the SF2 information. Buffer is not SF2");
        return;
    } else {
        RIFF_PRINTF_INFO("Buffer is SF2!");
    }

    // Go to the first section
    current_buffer_ptr = sf2_buffer + sizeof(RIFF_DESCRIPTOR_CHUNK_t);

    // Go through all the chunks
    do {
        // Get the chunk descriptor (should be LIST)
        curr_chunk = cmdGET_RIFF_BASE_CHUNK(current_buffer_ptr);

        if (curr_chunk->ChunkID == LIST_ASCII_TOKEN) {
            RIFF_PRINTF_DEBUG("Current SF2 chunk is LIST at address 0x%x", current_buffer_ptr);

            curr_list_chunk = cmdGET_RIFF_LIST_DESCRIPTOR_CHUNK(current_buffer_ptr);

            // Sub-chunk should be sdta || pdta || INFO
            switch (curr_list_chunk->ListType)
            {
                case SDTA_ASCII_TOKEN:
                    RIFF_PRINTF_DEBUG("Current LIST sub-chunk is sdta at address 0x%x", current_buffer_ptr);
                    current_sub_chunk_ptr = current_buffer_ptr + sizeof(RIFF_LIST_DESCRIPTOR_CHUNK_t);
                    current_sub_chunk_len = curr_list_chunk->BaseChunk.ChunkSize - sizeof(RIFF_BASE_CHUNK_t);
                    prv_vSF2DecodeSDTA(current_sub_chunk_ptr, current_sub_chunk_len, &sf_descriptor);
                    break;

                case PDTA_ASCII_TOKEN:
                    RIFF_PRINTF_DEBUG("Current LIST sub-chunk is pdta at address 0x%x", current_buffer_ptr);
                    current_sub_chunk_ptr = current_buffer_ptr + sizeof(RIFF_LIST_DESCRIPTOR_CHUNK_t);
                    current_sub_chunk_len = curr_list_chunk->BaseChunk.ChunkSize - sizeof(RIFF_BASE_CHUNK_t);
                    prv_vSF2DecodePDTA(current_sub_chunk_ptr, current_sub_chunk_len, &sf_descriptor);
                    break;

                case INFO_ASCII_TOKEN:
                    RIFF_PRINTF_DEBUG("Current LIST sub-chunk is INFO at address 0x%x", current_buffer_ptr);
                    current_sub_chunk_ptr = current_buffer_ptr + sizeof(RIFF_LIST_DESCRIPTOR_CHUNK_t);
                    current_sub_chunk_len = curr_list_chunk->BaseChunk.ChunkSize - sizeof(RIFF_BASE_CHUNK_t);
                    prv_vSF2DecodeINFO(current_sub_chunk_ptr, current_sub_chunk_len, &sf_descriptor);
                    break;
                
                default:
                    RIFF_PRINTF_ERROR("I don't know what type of LIST sub-chunk this is! ChunkID = %x, Address = 0x%x", curr_chunk->ChunkID, current_buffer_ptr);
                    break;
            }

        } else {
            RIFF_PRINTF_ERROR("I don't know what type of SF2 chunk this is! ChunkID = %x, Address = 0x%x", curr_chunk->ChunkID, current_buffer_ptr);
            break;
        }

        // Go to the next chunk
        current_buffer_ptr += curr_chunk->ChunkSize + sizeof(RIFF_BASE_CHUNK_t);
    } while ( current_buffer_ptr < (sf2_buffer + sf2_buffer_len) );

    RIFF_PRINTF_INFO("SF2 Decoding done!");

    // Print presets
    if ( sf_descriptor.sf_pdata_list_descriptor.PHDR_CHUNK == NULL ) {
        RIFF_PRINTF_ERROR("SF2 Doesn't have a preset header!");
        return;
    }

    prv_vPrintPHDR( &sf_descriptor );

    // Print samples
    if ( sf_descriptor.sf_pdata_list_descriptor.SHDR_CHUNK == NULL ) {
        RIFF_PRINTF_ERROR("SF2 Doesn't have a sample header!");
        return;
    }

    prv_vPrintSHDR( &sf_descriptor );

}

// Print the PHDR of all the presets
void prv_vPrintPHDR( SF_DESCRIPTOR_t * sf_descriptor ) {
    size_t                   phdr_len        = 0;
    uint32_t                 num_of_presets  = 0;
    SF_PHDR_CHUNK_DATA_t   * curr_phdr_chunk = NULL;

    // Get the length
    phdr_len       = sf_descriptor->sf_pdata_list_descriptor.PHDR_CHUNK->BaseChunk.ChunkSize;
    num_of_presets = (phdr_len/SF_PHDR_DATA_LEN) - 1; // The last preset doesn't count

    // First header
    curr_phdr_chunk = &sf_descriptor->sf_pdata_list_descriptor.PHDR_CHUNK->SF_PHDR_CHUNK_DATA;

    RIFF_PRINTF_INFO("------------ DECODING %d PRESETS ------------", num_of_presets);
    for( int i = 0; i < num_of_presets; i = i + 1 ) {
        RIFF_PRINTF_INFO("Preset [%03d] --------------- %.20s", i, curr_phdr_chunk->achPresetName);
        RIFF_PRINTF_INFO("  MIDI Preset Number = 0x%x ", curr_phdr_chunk->wPreset);
        RIFF_PRINTF_INFO("  MIDI Bank Number   = 0x%x ", curr_phdr_chunk->wBank);
        RIFF_PRINTF_INFO("  Preset Bag Index   = 0x%x ", curr_phdr_chunk->wPresetBagNdx);
        RIFF_PRINTF_INFO("  Library            = 0x%x ", curr_phdr_chunk->dwLibrary);
        RIFF_PRINTF_INFO("  Genre              = 0x%x ", curr_phdr_chunk->dwGenre);
        RIFF_PRINTF_INFO("  Morphology         = 0x%x ", curr_phdr_chunk->dwMorphology);
        curr_phdr_chunk += 1;
    }
}

// Print the SHDR (Sample Header) of all the samples
void prv_vPrintSHDR( SF_DESCRIPTOR_t * sf_descriptor ) {
    size_t                   shdr_len        = 0;
    uint32_t                 num_of_samples  = 0;
    SF_SHDR_CHUNK_DATA_t   * curr_shdr_chunk = NULL;

    // Get the length
    shdr_len       = sf_descriptor->sf_pdata_list_descriptor.SHDR_CHUNK->BaseChunk.ChunkSize;
    num_of_samples = (shdr_len/SF_SHDR_DATA_LEN) - 1; // The last sample doesn't count

    // First header
    curr_shdr_chunk = &sf_descriptor->sf_pdata_list_descriptor.SHDR_CHUNK->SF_SHDR_CHUNK_DATA;

    RIFF_PRINTF_INFO("------------ DECODING %d SAMPLES ------------", num_of_samples);
    for( int i = 0; i < num_of_samples; i = i + 1 ) {
        RIFF_PRINTF_INFO("Sample [%03d] --------------- %.20s", i, curr_shdr_chunk->achSampleName);
        RIFF_PRINTF_INFO("  Sample Rate      = %d Hz", curr_shdr_chunk->dwSampleRate);
        RIFF_PRINTF_INFO("  Original Pitch   = %d",   curr_shdr_chunk->byOriginalPitch);
        RIFF_PRINTF_INFO("  Pitch Correction = %d",   curr_shdr_chunk->chPitchCorrection);
        RIFF_PRINTF_INFO("  Start            = 0x%x", curr_shdr_chunk->dwStart);
        RIFF_PRINTF_INFO("  End              = 0x%x", curr_shdr_chunk->dwEnd);
        RIFF_PRINTF_INFO("  Start Loop       = 0x%x", curr_shdr_chunk->dwStartloop);
        RIFF_PRINTF_INFO("  End Loop         = 0x%x", curr_shdr_chunk->dwEndloop);
        RIFF_PRINTF_INFO("  Sample Link      = 0x%x", curr_shdr_chunk->wSampleLink);
        RIFF_PRINTF_INFO("  Sample Type      = 0x%x", curr_shdr_chunk->sfSampleType);
        curr_shdr_chunk += 1;
    }
}

//////////////////////////////////////////////////////////////////////////////////////////////////
// Decode SF2 INFO Chunk
//////////////////////////////////////////////////////////////////////////////////////////////////
//<INFO-list> -> LIST (‘INFO’
//                      {
//                        <ifil-ck> ; Refers to the version of the Sound Font RIFF file
//                        <isng-ck> ; Refers to the target Sound Engine
//                        <INAM-ck> ; Refers to the Sound Font Bank Name
//                        [<irom-ck>] ; Refers to the Sound ROM Name
//                        [<iver-ck>] ; Refers to the Sound ROM Version
//                        [<ICRD-ck>] ; Refers to the Date of Creation of the Bank
//                        [<IENG-ck>] ; Sound Designers and Engineers for the Bank
//                        [<IPRD-ck>] ; Product for which the Bank was intended
//                        [<ICOP-ck>] ; Contains any Copyright message
//                        [<ICMT-ck>] ; Contains any Comments on the Bank
//                        [<ISFT-ck>] ; The SoundFont tools used to create and alter the bank
//                      }
//                    )
//////////////////////////////////////////////////////////////////////////////////////////////////
void prv_vSF2DecodeINFO( uint8_t * info_chunk_buffer, size_t info_chunk_buffer_len, SF_DESCRIPTOR_t * sf_descriptor ) {

    // Sanity check
    if ( sf_descriptor == NULL ) {
        RIFF_PRINTF_ERROR("Error decoding SF2 Info - sf_descriptor == NULL");
        return;
    }

    SF_INFO_LIST_DESCRIPTOR_t * sf_info_descriptor = &sf_descriptor->sf_info_list_descriptor;
    uint8_t                   * curr_buffer_pointer;
    RIFF_BASE_CHUNK_t         * curr_chunk;

    // Initialize
    sf_info_descriptor->IFIL_CHUNK = NULL;
    sf_info_descriptor->ISNG_CHUNK = NULL;
    sf_info_descriptor->INAM_CHUNK = NULL;
    sf_info_descriptor->IROM_CHUNK = NULL;
    sf_info_descriptor->IVER_CHUNK = NULL;
    sf_info_descriptor->ICRD_CHUNK = NULL;
    sf_info_descriptor->IENG_CHUNK = NULL;
    sf_info_descriptor->IPRD_CHUNK = NULL;
    sf_info_descriptor->ICOP_CHUNK = NULL;
    sf_info_descriptor->ICMT_CHUNK = NULL;
    sf_info_descriptor->ISFT_CHUNK = NULL;

    curr_buffer_pointer = info_chunk_buffer;

    do {
       curr_chunk = cmdGET_RIFF_BASE_CHUNK(curr_buffer_pointer);

       switch (curr_chunk->ChunkID) {
        // IFIL
        case IFIL_ASCII_TOKEN:
            RIFF_PRINTF_DEBUG("INFO sub-chunk is IFIL at address 0x%x", curr_buffer_pointer);
            sf_info_descriptor->IFIL_CHUNK = (SF_IFIL_CHUNK_t *) curr_buffer_pointer;
            break;

        // ISNG
        case ISNG_ASCII_TOKEN:
            RIFF_PRINTF_DEBUG("INFO sub-chunk is ISNG at address 0x%x", curr_buffer_pointer);
            sf_info_descriptor->ISNG_CHUNK = (SF_ISNG_CHUNK_t *) curr_buffer_pointer;
            break;

        // INAM
        case INAM_ASCII_TOKEN:
            RIFF_PRINTF_DEBUG("INFO sub-chunk is INAM at address 0x%x", curr_buffer_pointer);
            sf_info_descriptor->INAM_CHUNK = (SF_INAM_CHUNK_t *) curr_buffer_pointer;
            break;

        // IROM
        case IROM_ASCII_TOKEN:
            RIFF_PRINTF_DEBUG("INFO sub-chunk is IROM at address 0x%x", curr_buffer_pointer);
            sf_info_descriptor->IROM_CHUNK = (SF_IROM_CHUNK_t *) curr_buffer_pointer;
            break;

        // IVER
        case IVER_ASCII_TOKEN:
            RIFF_PRINTF_DEBUG("INFO sub-chunk is IVER at address 0x%x", curr_buffer_pointer);
            sf_info_descriptor->IVER_CHUNK = (SF_IVER_CHUNK_t *) curr_buffer_pointer;
            break;

        // ICRD
        case ICRD_ASCII_TOKEN:
            RIFF_PRINTF_DEBUG("INFO sub-chunk is ICRD at address 0x%x", curr_buffer_pointer);
            sf_info_descriptor->ICRD_CHUNK = (SF_ICRD_CHUNK_t *) curr_buffer_pointer;
            break;

        // IENG
        case IENG_ASCII_TOKEN:
            RIFF_PRINTF_DEBUG("INFO sub-chunk is IENG at address 0x%x", curr_buffer_pointer);
            sf_info_descriptor->IENG_CHUNK = (SF_IENG_CHUNK_t *) curr_buffer_pointer;
            break;

        // IPRD
        case IPRD_ASCII_TOKEN:
            RIFF_PRINTF_DEBUG("INFO sub-chunk is IPRD at address 0x%x", curr_buffer_pointer);
            sf_info_descriptor->IPRD_CHUNK = (SF_IPRD_CHUNK_t *) curr_buffer_pointer;
            break;

        // ICOP
        case ICOP_ASCII_TOKEN:
            RIFF_PRINTF_DEBUG("INFO sub-chunk is ICOP at address 0x%x", curr_buffer_pointer);
            sf_info_descriptor->ICOP_CHUNK = (SF_ICOP_CHUNK_t *) curr_buffer_pointer;
            break;

        // ICMT
        case ICMT_ASCII_TOKEN:
            RIFF_PRINTF_DEBUG("INFO sub-chunk is ICMT at address 0x%x", curr_buffer_pointer);
            sf_info_descriptor->ICMT_CHUNK = (SF_ICMT_CHUNK_t *) curr_buffer_pointer;
            break;

        // ISFT
        case ISFT_ASCII_TOKEN:
            RIFF_PRINTF_DEBUG("INFO sub-chunk is ISFT at address 0x%x", curr_buffer_pointer);
            sf_info_descriptor->ISFT_CHUNK = (SF_ISFT_CHUNK_t *) curr_buffer_pointer;
            break;
        // Unknown
        default:
            RIFF_PRINTF_WARNING("Unknown chunk inside INFO sub-chunk! ChunkID = %x, Address = 0x%x", curr_chunk->ChunkID, curr_buffer_pointer);
            break;
        }

        // Go to the next chunk
        curr_buffer_pointer += sizeof(RIFF_BASE_CHUNK_t) + curr_chunk->ChunkSize;

    } while ( curr_buffer_pointer < (info_chunk_buffer + info_chunk_buffer_len) );

}

//////////////////////////////////////////////////////////////////////////////////////////////////
// Decode SF2 sdta Chunk
//////////////////////////////////////////////////////////////////////////////////////////////////
//<sdta-ck> -> LIST (‘sdta’
//                    {
//                      [<smpl-ck>] ; The Digital Audio Samples for the upper 16 bits
//                    }
//                    {
//                      [<sm24-ck>] ; The Digital Audio Samples for the lower 8 bits
//                    }
//                  )
//////////////////////////////////////////////////////////////////////////////////////////////////
void prv_vSF2DecodeSDTA( uint8_t * sdta_chunk_buffer, size_t sdta_chunk_buffer_len, SF_DESCRIPTOR_t * sf_descriptor  ) {

    // Sanity check
    if ( sf_descriptor == NULL ) {
        RIFF_PRINTF_ERROR("Error decoding SF2 SDTA - sf_descriptor == NULL");
        return;
    }

    SF_SDATA_LIST_DESCRIPTOR_t * sf_sdta_descriptor = &sf_descriptor->sf_sdata_list_descriptor;
    uint8_t                    * curr_buffer_pointer;
    RIFF_BASE_CHUNK_t          * curr_chunk;

    sf_sdta_descriptor->SM24_CHUNK = NULL;
    sf_sdta_descriptor->SMPL_CHUNK = NULL;

    curr_buffer_pointer = sdta_chunk_buffer;

    do {
       curr_chunk = cmdGET_RIFF_BASE_CHUNK(curr_buffer_pointer);

       switch (curr_chunk->ChunkID) {
        // SM24
        case SM24_ASCII_TOKEN:
            RIFF_PRINTF_DEBUG("SDTA sub-chunk is SM24 at address 0x%x", curr_buffer_pointer);
            sf_sdta_descriptor->SM24_CHUNK = (SF_SM24_CHUNK_t *) curr_buffer_pointer;
            break;

        // SMPL
        case SMPL_ASCII_TOKEN:
            RIFF_PRINTF_DEBUG("SDTA sub-chunk is SMPL at address 0x%x", curr_buffer_pointer);
            sf_sdta_descriptor->SMPL_CHUNK = (SF_SMPL_CHUNK_t *) curr_buffer_pointer;
            break;

        // Unknown
        default:
            RIFF_PRINTF_WARNING("Unknown chunk inside SDTA sub-chunk! ChunkID = %x, Address = 0x%x", curr_chunk->ChunkID, curr_buffer_pointer);
            break;
       }

        // Go to the next chunk
        curr_buffer_pointer += sizeof(RIFF_BASE_CHUNK_t) + curr_chunk->ChunkSize;

    } while ( curr_buffer_pointer < (sdta_chunk_buffer + sdta_chunk_buffer_len) );

}

//////////////////////////////////////////////////////////////////////////////////////////////////
// Decode SF2 pdta Chunk
//////////////////////////////////////////////////////////////////////////////////////////////////
//<pdta-ck> -> LIST (‘pdta’
//                    {
//                      <phdr-ck> ; The Preset Headers
//                      <pbag-ck> ; The Preset Index list
//                      <pmod-ck> ; The Preset Modulator list
//                      <pgen-ck> ; The Preset Generator list
//                      <inst-ck> ; The Instrument Names and Indices
//                      <ibag-ck> ; The Instrument Index list
//                      <imod-ck> ; The Instrument Modulator list
//                      <igen-ck> ; The Instrument Generator list
//                      <shdr-ck> ; The Sample Headers
//                    }
//                  )
//////////////////////////////////////////////////////////////////////////////////////////////////
void prv_vSF2DecodePDTA( uint8_t * pdta_chunk_buffer, size_t pdta_chunk_buffer_len, SF_DESCRIPTOR_t * sf_descriptor  ) {
    // Sanity check
    if ( sf_descriptor == NULL ) {
        RIFF_PRINTF_ERROR("Error decoding SF2 PDTA - sf_descriptor == NULL");
        return;
    }

    SF_PDATA_LIST_DESCRIPTOR_t * sf_pdta_descriptor = &sf_descriptor->sf_pdata_list_descriptor;
    uint8_t                    * curr_buffer_pointer;
    RIFF_BASE_CHUNK_t          * curr_chunk;

    sf_pdta_descriptor->PHDR_CHUNK = NULL;
    sf_pdta_descriptor->PBAG_CHUNK = NULL;
    sf_pdta_descriptor->PMOD_CHUNK = NULL;
    sf_pdta_descriptor->PGEN_CHUNK = NULL;
    sf_pdta_descriptor->INST_CHUNK = NULL;
    sf_pdta_descriptor->IBAG_CHUNK = NULL;
    sf_pdta_descriptor->IMOD_CHUNK = NULL;
    sf_pdta_descriptor->IGEN_CHUNK = NULL;
    sf_pdta_descriptor->SHDR_CHUNK = NULL;

    curr_buffer_pointer = pdta_chunk_buffer;

    do {
       curr_chunk = cmdGET_RIFF_BASE_CHUNK(curr_buffer_pointer);

       switch (curr_chunk->ChunkID) {
        // PHDR
        case PHDR_ASCII_TOKEN:
            RIFF_PRINTF_DEBUG("PDTA sub-chunk is PHDR at address 0x%x", curr_buffer_pointer);
            sf_pdta_descriptor->PHDR_CHUNK = (SF_PHDR_CHUNK_t *) curr_buffer_pointer;
            break;

        // PBAG
        case PBAG_ASCII_TOKEN:
            RIFF_PRINTF_DEBUG("PDTA sub-chunk is PBAG at address 0x%x", curr_buffer_pointer);
            sf_pdta_descriptor->PBAG_CHUNK = (SF_PBAG_CHUNK_t *) curr_buffer_pointer;
            break;

        // PMOD
        case PMOD_ASCII_TOKEN:
            RIFF_PRINTF_DEBUG("PDTA sub-chunk is PMOD at address 0x%x", curr_buffer_pointer);
            sf_pdta_descriptor->PMOD_CHUNK = (SF_PMOD_CHUNK_t *) curr_buffer_pointer;
            break;

        // PGEN
        case PGEN_ASCII_TOKEN:
            RIFF_PRINTF_DEBUG("PDTA sub-chunk is PGEN at address 0x%x", curr_buffer_pointer);
            sf_pdta_descriptor->PGEN_CHUNK = (SF_PGEN_CHUNK_t *) curr_buffer_pointer;
            break;

        // INST
        case INST_ASCII_TOKEN:
            RIFF_PRINTF_DEBUG("PDTA sub-chunk is INST at address 0x%x", curr_buffer_pointer);
            sf_pdta_descriptor->INST_CHUNK = (SF_INST_CHUNK_t *) curr_buffer_pointer;
            break;

        // IBAG
        case IBAG_ASCII_TOKEN:
            RIFF_PRINTF_DEBUG("PDTA sub-chunk is IBAG at address 0x%x", curr_buffer_pointer);
            sf_pdta_descriptor->IBAG_CHUNK = (SF_IBAG_CHUNK_t *) curr_buffer_pointer;
            break;

        // IMOD
        case IMOD_ASCII_TOKEN:
            RIFF_PRINTF_DEBUG("PDTA sub-chunk is IMOD at address 0x%x", curr_buffer_pointer);
            sf_pdta_descriptor->IMOD_CHUNK = (SF_IMOD_CHUNK_t *) curr_buffer_pointer;
            break;

        // IGEN
        case IGEN_ASCII_TOKEN:
            RIFF_PRINTF_DEBUG("PDTA sub-chunk is IGEN at address 0x%x", curr_buffer_pointer);
            sf_pdta_descriptor->IGEN_CHUNK = (SF_IGEN_CHUNK_t *) curr_buffer_pointer;
            break;

        // SHDR
        case SHDR_ASCII_TOKEN:
            RIFF_PRINTF_DEBUG("PDTA sub-chunk is SHDR at address 0x%x", curr_buffer_pointer);
            sf_pdta_descriptor->SHDR_CHUNK = (SF_SHDR_CHUNK_t *) curr_buffer_pointer;
            break;

        // Unknown
        default:
            RIFF_PRINTF_WARNING("Unknown chunk inside SDTA sub-chunk! ChunkID = %x, Address = 0xx", curr_chunk->ChunkID, curr_buffer_pointer);
            break;
       }

        // Go to the next chunk
        curr_buffer_pointer += sizeof(RIFF_BASE_CHUNK_t) + curr_chunk->ChunkSize;

    } while ( curr_buffer_pointer < (pdta_chunk_buffer + pdta_chunk_buffer_len) );
}
