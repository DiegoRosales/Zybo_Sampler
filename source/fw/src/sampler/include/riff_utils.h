#ifndef __RIFF_UTILS_H__
#define __RIFF_UTILS_H__

#include "sampler_cfg.h"

void vDecodeRIFFInformation( uint8_t *riff_buffer, size_t riff_buffer_size, SAMPLE_FORMAT_t *sample_information );

#endif
