#ifndef SAMPLER_H
#define SAMPLER_H

#define SAMPLER_BASE_ADDR XPAR_AUDIO_SAMPLER_INST_AXI_LITE_SLAVE_BASEADDR

int SamplerRegWr(int addr, int value, int check);
int SamplerRegRd(int addr);

#endif