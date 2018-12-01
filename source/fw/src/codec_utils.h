
#ifndef CODEC_UTILS_H
#define CODEC_UTILS_H

//send data over UART
#include "xil_printf.h"
#include "reg_utils.h"
#include "SSM2603_codec_registers.h"

// Control Registers
#define BUSY_BIT 2


int CodecRd(int addr, int display, int debug);
int CodecWr(int addr, int data, int check, int display, int debug);
void BusyBitIsClear(int debug);
void ControllerReset(int debug);
void ClearStatusBits(int debug);
void WaitUntilDataIsAvailable(int debug);
void CodecInit(int debug);
void CodecReset(int debug);
int SetOutputVolume(uint8_t volume);
#endif
