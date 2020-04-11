
#ifndef _CODEC_CONTROLLER_REG_UTILS_H_
#define _CODEC_CONTROLLER_REG_UTILS_H_



// Control Register Bits
#define WR_DATA_BIT          1
#define RD_DATA_BIT          2
#define CONTROLLER_RESET_BIT 31


int CodecCtrlRegWr(int addr, int value, int check, int display);
int CodecCtrlRegRd(int addr, int display);

#endif
