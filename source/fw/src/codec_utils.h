
#ifndef CODEC_UTILS_H
#define CODEC_UTILS_H

//send data over UART
#include "xil_printf.h"
#include "reg_utils.h"

// CODEC Registers
#define LEFT_CHANN_INPUT_VOL_REG_ADDR   0x00
#define RIGHT_CHANN_INPUT_VOL_REG_ADDR  0x01
#define LEFT_CHANN_OUTPUT_VOL_REG_ADDR  0x02
#define RIGHT_CHANN_OUTPUT_VOL_REG_ADDR 0x03
#define ANALOG_AUDIO_PATH_REG_ADDR      0x04
#define DIGITAL_AUDIO_PATH_REG_ADDR     0x05
#define POWER_MGMT_REG_ADDR             0x06
#define DIGITAL_AUDIO_IF_REG_ADDR       0x07
#define SAMPLING_RATE_REG_ADDR          0x08
#define ACTIVE_REG_ADDR                 0x09
#define SW_RESET_REG_ADDR               0x0f
#define ALC_CTRL_1_REG_ADDR             0x10
#define ALC_CTRL_2_REG_ADDR             0x11
#define NOISE_GATE_REG_ADDR             0x12

int CodecRd(int addr, int display, int debug);
int CodecWr(int addr, int data, int check, int display, int debug);
void BusyBitIsClear(int debug);

#endif
