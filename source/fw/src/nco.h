#ifndef NCO_H
#define NCO_H

#define FRACTION_SIZE 23 // Bits
#define SIZE_OF_SINE_LUT 512

#include "xparameters.h" 
#include "dma_utils.h"



void nvo_init(nco_t * nco);
float nco_normalize_frequency(uint32_t frequency, uint32_t sample_frequency);
uint32_t nco_phase_init(float frequency_norm);

#endif