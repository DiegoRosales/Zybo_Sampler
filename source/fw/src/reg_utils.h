
#ifndef REG_UTILS_H
#define REG_UTILS_H

//send data over UART
#include "xil_printf.h"

//information about AXI peripherals
#include "xparameters.h"
#include "xil_io.h"

// Controller Registers
#define REGISTERS_BAR              0x43c00000
#define CODEC_I2C_CTRL_REG_ADDR    0x00
#define CODEC_I2C_ADDR_REG_ADDR    0x01
#define CODEC_I2C_WR_DATA_REG_ADDR 0x02
#define CODEC_I2C_RD_DATA_REG_ADDR 0x03
#define MISC_DATA_0_REG_ADDR       0x04
#define MISC_DATA_1_REG_ADDR       0x05
#define MISC_DATA_2_REG_ADDR       0x06

// Control Register Bits
#define WR_DATA_BIT          1
#define RD_DATA_BIT          2
#define CONTROLLER_RESET_BIT 31


int RegWr(int addr, int value, int check, int display);
int RegRd(int addr, int display);

#endif
