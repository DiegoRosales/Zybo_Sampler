#ifndef SAMPLER_H
#define SAMPLER_H

#include "sampler_cfg.h"

#define ENABLE_FREERTOS_MALLOC 1

#ifdef ENABLE_FREERTOS_MALLOC
    #if( ENABLE_FREERTOS_MALLOC == 1)
        #include "FreeRTOS.h"
        #define sampler_malloc pvPortMalloc
        #define sampler_free   vPortFree
    #else
        #define sampler_malloc malloc
        #define sampler_free   free
    #endif
#endif

uint8_t us_get_midi_note_number( const char *note_name );

uint32_t ul_stop_all( PATCH_DESCRIPTOR_t *instrument_information );
uint32_t ul_play_instrument_key( uint8_t key, uint8_t velocity, PATCH_DESCRIPTOR_t *instrument_information );

#endif
