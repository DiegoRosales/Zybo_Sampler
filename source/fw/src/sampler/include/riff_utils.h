#ifndef __RIFF_UTILS_H__
#define __RIFF_UTILS_H__

#include "sampler_cfg.h"

uint32_t ulDecodeRIFFInformation( uint8_t *sample_buffer, size_t sample_size, SAMPLE_FORMAT_t *riff_information );

#endif
