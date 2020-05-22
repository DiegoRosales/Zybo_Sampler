
#ifndef CODEC_UTILS_H
#define CODEC_UTILS_H

#define BUSY_BIT 2


uint32_t ulCodecRd(uint32_t addr, uint32_t display, uint32_t debug);
uint32_t ulCodecWr(uint32_t addr, uint32_t data, uint32_t check, uint32_t display, uint32_t debug);
void vBusyBitIsClear(uint32_t debug);
void vControllerReset(uint32_t debug);
void vClearStatusBits(uint32_t debug);
void vWaitUntilDataIsAvailable(uint32_t debug);
void vCodecInit(uint32_t debug);
void vCodecReset(uint32_t debug);
uint32_t ulSetOutputVolume(uint32_t volume);
uint32_t ulSetInputVolume(uint32_t volume);

#endif
