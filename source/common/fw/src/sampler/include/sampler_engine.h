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

uint32_t ulStopAllPlayback( PATCH_DESCRIPTOR_t *instrument_information );
uint32_t ulPlayInstrumentKey( uint8_t key, uint8_t velocity, PATCH_DESCRIPTOR_t *instrument_information );
uint8_t  usGetMIDINoteNumber( const char *note_name );

#endif
