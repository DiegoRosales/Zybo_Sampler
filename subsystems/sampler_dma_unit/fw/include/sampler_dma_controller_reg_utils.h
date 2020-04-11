#ifndef _SAMPLER_DMA_CONTROLLER_REG_UTILS_H_
#define _SAMPLER_DMA_CONTROLLER_REG_UTILS_H_

uint32_t SamplerRegWr(uint32_t addr, uint32_t value, uint32_t check);
uint32_t SamplerRegRd(uint32_t addr);

#endif