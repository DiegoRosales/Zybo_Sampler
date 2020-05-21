#ifndef _SAMPLER_DMA_CONTROLLER_REG_UTILS_H_
#define _SAMPLER_DMA_CONTROLLER_REG_UTILS_H_

uint32_t ulSamplerRegWr(uint32_t addr, uint32_t value, uint32_t check);
uint32_t ulSamplerRegRd(uint32_t addr);
uint32_t ulGetDMAEngineHWVersion(void);

#endif