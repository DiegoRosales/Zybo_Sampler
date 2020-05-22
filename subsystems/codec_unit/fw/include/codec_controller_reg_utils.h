
#ifndef _CODEC_CONTROLLER_REG_UTILS_H_
#define _CODEC_CONTROLLER_REG_UTILS_H_



// Control Register Bits
#define WR_DATA_BIT          1
#define RD_DATA_BIT          2
#define CONTROLLER_RESET_BIT 31


uint32_t ulCodecCtrlRegWr(uint32_t addr, uint32_t value, uint32_t check, uint32_t display);
uint32_t ulCodecCtrlRegRd(uint32_t addr, uint32_t display);

#endif
