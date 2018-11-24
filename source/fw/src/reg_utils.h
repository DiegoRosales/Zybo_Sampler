
#ifndef REG_UTILS_H
#define REG_UTILS_H

//send data over UART
#include "xil_printf.h"

//information about AXI peripherals
#include "xparameters.h"
#include "xil_io.h"

// Controller Registers
#define REGISTERS_BAR              XPAR_AUDIO_SAMPLER_INST_BASEADDR
#define CODEC_I2C_CTRL_REG_ADDR    0x00
#define CODEC_I2C_ADDR_REG_ADDR    0x01
#define CODEC_I2C_WR_DATA_REG_ADDR 0x02
#define CODEC_I2C_RD_DATA_REG_ADDR 0x03
#define MISC_DATA_0_REG_ADDR       0x04
#define MISC_DATA_1_REG_ADDR       0x05
#define MISC_DATA_2_REG_ADDR       0x06

#define CONTROL_REGISTER_ACCESS ((volatile CONTROLLER_REGISTERS_t *)(REGISTERS_BAR))

/////////////////////////////////
// CODEC I2C Control Register
/////////////////////////////////
typedef union {
    // Individual Fields
    struct {
        uint8_t  codec_i2c_data_wr_reg : 1 ; // Bit 0
        uint8_t  codec_i2c_data_rd_reg : 1 ; // Bit 1
        uint8_t  controller_busy_reg   : 1 ; // Bit 2
        uint8_t  codec_init_done_reg   : 1 ; // Bit 3
        uint8_t  data_in_valid_reg     : 1 ; // Bit 4
        uint8_t  missed_ack_reg        : 1 ; // Bit 5
        uint32_t RSVD                  : 25; // Bits 6-30
        uint8_t  controller_reset_reg  : 1 ; // Bit 31
    } field;
    // Complete Value
    uint32_t value;
} CODEC_I2C_CTRL_REG_t;

/////////////////////////////////
// CODEC I2C Address Register
/////////////////////////////////
typedef union {
    // Individual Fields
    struct {
        uint32_t codec_i2c_addr_reg;
    } field;
    // Complete Value
    uint32_t value;
} CODEC_I2C_ADDR_REG_t;

/////////////////////////////////
// CODEC I2C Data Write Register
/////////////////////////////////
typedef union {
    // Individual Fields
    struct {
        uint32_t codec_i2c_wr_data_reg;
    } field;
    // Complete Value
    uint32_t value;
} CODEC_I2C_WR_DATA_REG_t;

/////////////////////////////////
// CODEC I2C Data Read Register
/////////////////////////////////
typedef union {
    // Individual Fields
    struct {
        uint32_t codec_i2c_rd_data_reg;
    } field;
    // Complete Value
    uint32_t value;
} CODEC_I2C_RD_DATA_REG_t;

////////////////////////////////////////////////////////
// Compilation of all controller registers
////////////////////////////////////////////////////////
typedef struct {
    CODEC_I2C_CTRL_REG_t    CODEC_I2C_CTRL_REG;     // Address 0
    CODEC_I2C_ADDR_REG_t    CODEC_I2C_ADDR_REG;     // Address 1
    CODEC_I2C_WR_DATA_REG_t CODEC_I2C_WR_DATA_REG;  // Address 2
    CODEC_I2C_RD_DATA_REG_t CODEC_I2C_RD_DATA_REG;  // Address 3
} CONTROLLER_REGISTERS_t;

// Control Register Bits
#define WR_DATA_BIT          1
#define RD_DATA_BIT          2
#define CONTROLLER_RESET_BIT 31


int RegWr(int addr, int value, int check, int display);
int RegRd(int addr, int display);

#endif
