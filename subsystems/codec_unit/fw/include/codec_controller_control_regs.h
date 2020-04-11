//////////////////////////////////////////////////
// CODEC Controller Register Definition
//////////////////////////////////////////////////

#ifndef _CODEC_CONTROLLER_REGS_H_
#define _CODEC_CONTROLLER_REGS_H_

#define CODEC_CONTROLLER_REGISTERS_BAR         XPAR_SAMPLER_CODEC_CONTROLLER_AXI4_LITE_INTERFACE_BASEADDR
#define CODEC_I2C_CTRL_REG_ADDR                0x00
#define CODEC_I2C_ADDR_REG_ADDR                0x01
#define CODEC_I2C_WR_DATA_REG_ADDR             0x02
#define CODEC_I2C_RD_DATA_REG_ADDR             0x03
#define MISC_DATA_0_REG_ADDR                   0x04
#define MISC_DATA_1_REG_ADDR                   0x05
#define MISC_DATA_2_REG_ADDR                   0x06
#define DOWNSTREAM_AXIS_WR_DATA_COUNT_REG_ADDR 0x08
#define UPSTREAM_AXIS_RD_DATA_COUNT_REG_ADDR   0x09
#define DOWNSTREAM_AXIS_RD_DATA_COUNT_REG_ADDR 0x0a
#define UPSTREAM_AXIS_WR_DATA_COUNT_REG_ADDR   0x0b

#define CODEC_CONTROL_REGISTER_ACCESS ((volatile CONTROLLER_REGISTERS_t *)(CODEC_CONTROLLER_REGISTERS_BAR))

/////////////////////////////////
// CODEC I2C Control Register
/////////////////////////////////
typedef union {
    // Individual Fields
    struct {
        uint32_t codec_i2c_data_wr_reg : 1 ; // Bit 0
        uint32_t codec_i2c_data_rd_reg : 1 ; // Bit 1
        uint32_t controller_busy_reg   : 1 ; // Bit 2
        uint32_t codec_init_done_reg   : 1 ; // Bit 3
        uint32_t data_in_valid_reg     : 1 ; // Bit 4
        uint32_t missed_ack_reg        : 1 ; // Bit 5
        uint32_t RSVD                  : 25; // Bits 6-30
        uint32_t controller_reset_reg  : 1 ; // Bit 31
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
    CODEC_I2C_CTRL_REG_t    CODEC_I2C_CTRL_REG;                     // Address 0
    CODEC_I2C_ADDR_REG_t    CODEC_I2C_ADDR_REG;                     // Address 1
    CODEC_I2C_WR_DATA_REG_t CODEC_I2C_WR_DATA_REG;                  // Address 2
    CODEC_I2C_RD_DATA_REG_t CODEC_I2C_RD_DATA_REG;                  // Address 3
    uint32_t                MISC_DATA_0_REG;                        // Address 4
    uint32_t                MISC_DATA_1_REG;                        // Address 5
    uint32_t                MISC_DATA_2_REG;                        // Address 6  
    uint32_t                RESERVED;                               // Address 7
    uint32_t                DOWNSTREAM_AXIS_WR_DATA_COUNT_REG;      // Address 8
    uint32_t                UPSTREAM_AXIS_RD_DATA_COUNT_REG;        // Address 9
    uint32_t                DOWNSTREAM_AXIS_RD_DATA_COUNT_REG;      // Address a
    uint32_t                UPSTREAM_AXIS_WR_DATA_COUNT_REG;        // Address b
} CONTROLLER_REGISTERS_t;

#endif