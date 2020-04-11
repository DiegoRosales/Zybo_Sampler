///////////////////////////////////////
// This file contains the structures
// of the CODEC internal registers
// These are taken from the datasheet
///////////////////////////////////////

#ifndef _SSM2603_CODEC_REGISTERS_H_
#define _SSM2603_CODEC_REGISTERS_H_

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

// Default value for 0dB
#define DB_OUT_DEFAULT_0 0x79
#define DB_TO_INT_OUT(DB) ((uint8_t)(DB_OUT_DEFAULT_0 + DB))

//////////////////////////////////////////////////
// LEFT-CHANNEL ADC INPUT VOLUME, ADDRESS 0x00
//////////////////////////////////////////////////
typedef union {
    // Individual Fields
    struct {
        uint32_t  LINVOL   : 6 ; // Bits 0 - 5
        uint32_t  RSVD     : 1 ; // Bit 6
        uint32_t  LINMUTE  : 1 ; // Bit 7
        uint32_t  LRINBOTH : 1 ; // Bit 8
    } field;
    // Complete Value
    uint32_t value;
} LEFT_CHAN_ADC_IN_VOL_t;

//////////////////////////////////////////////////
// RIGHT-CHANNEL ADC INPUT VOLUME, ADDRESS 0x01
//////////////////////////////////////////////////
typedef union {
    // Individual Fields
    struct {
        uint32_t  RINVOL   : 6 ; // Bits 0 - 5
        uint32_t  RSVD     : 1 ; // Bit 6
        uint32_t  RINMUTE  : 1 ; // Bit 7
        uint32_t  RLINBOTH : 1 ; // Bit 8
    } field;
    // Complete Value
    uint32_t value;
} RIGHT_CHAN_ADC_IN_VOL_t;

//////////////////////////////////////////////////
// LEFT-CHANNEL DAC VOLUME, ADDRESS 0x02
//////////////////////////////////////////////////
typedef union {
    // Individual Fields
    struct {
        uint32_t  LHPVOL   : 7 ; // Bits 0 - 6
        uint32_t  RSVD     : 1 ; // Bit 7
        uint32_t  LRHPBOTH : 1 ; // Bit 8
    } field;
    // Complete Value
    uint32_t value;
} LEFT_CHAN_DAC_VOL_t;

//////////////////////////////////////////////////
// RIGHT-CHANNEL DAC VOLUME, ADDRESS 0x03
//////////////////////////////////////////////////
typedef union {
    // Individual Fields
    struct {
        uint32_t  RHPVOL   : 7 ; // Bits 0 - 6
        uint32_t  RSVD     : 1 ; // Bit 7
        uint32_t  RLHPBOTH : 1 ; // Bit 8
    } field;
    // Complete Value
    uint32_t value;
} RIGHT_CHAN_DAC_VOL_t;

//////////////////////////////////////////////////
// Analog audio path, ADDRESS 0x04
//////////////////////////////////////////////////
typedef union {
    // Individual Fields
    struct {
        uint32_t MICBOOST     : 1 ; // Bit 0
        uint32_t MUTEMIC      : 1 ; // Bit 1
        uint32_t INSEL        : 1 ; // Bit 2
        uint32_t Bypass       : 1 ; // Bit 3
        uint32_t DACSEL       : 1 ; // Bit 4
        uint32_t SIDETONE_EN  : 1 ; // Bit 5
        uint32_t SIDETONE_ATT : 2 ; // Bits 6-7
    } field;
    // Complete Value
    uint32_t value;
} ANALOG_AUDIO_PATH_t;


//////////////////////////////////////////////////
// Digital audio path, ADDRESS 0x05
//////////////////////////////////////////////////
typedef union {
    // Individual Fields
    struct {
        uint32_t ADCHPF : 1 ; // Bit 0
        uint32_t DEEMPH : 2 ; // Bit 1-2
        uint32_t DACMU  : 1 ; // Bit 3
        uint32_t HPOR   : 1 ; // Bit 4
    } field;
    // Complete Value
    uint32_t value;
} DIGITAL_AUDIO_PATH_t;


//////////////////////////////////////////////////
// Power management, ADDRESS 0x06
//////////////////////////////////////////////////
typedef union {
    // Individual Fields
    struct {
        uint32_t LINEIN : 1 ; // Bit 0
        uint32_t MIC    : 1 ; // Bit 1
        uint32_t ADC    : 1 ; // Bit 3
        uint32_t DAC    : 1 ; // Bit 4
        uint32_t Out    : 1 ; // Bit 5
        uint32_t OSC    : 1 ; // Bit 6
        uint32_t CLKOUT : 1 ; // Bit 7
        uint32_t PWROFF : 1 ; // Bit 8        
    } field;
    // Complete Value
    uint32_t value;
} POWER_MANAGEMENT_t;

//////////////////////////////////////////////////
// Digital audio I/F, ADDRESS 0x07
//////////////////////////////////////////////////
typedef union {
    // Individual Fields
    struct {
        uint32_t Format  : 2 ; // Bits 0-1
        uint32_t WL      : 2 ; // Bits 2-3
        uint32_t LRP     : 1 ; // Bit 4
        uint32_t LRSWAP  : 1 ; // Bit 5
        uint32_t MS      : 1 ; // Bit 6
        uint32_t BCLKINV : 1 ; // Bit 7
    } field;
    // Complete Value
    uint32_t value;
} DIGITAL_AUDIO_IF_t;

//////////////////////////////////////////////////
// Sampling rate, ADDRESS 0x08
//////////////////////////////////////////////////
typedef union {
    // Individual Fields
    struct {
        uint32_t USB      : 1 ; // Bit 0
        uint32_t BOSR     : 1 ; // Bit 1
        uint32_t SR       : 4 ; // Bits 2-5
        uint32_t CLKDIV2  : 1 ; // Bit 6
        uint32_t CLKODIV2 : 1 ; // Bit 7
    } field;
    // Complete Value
    uint32_t value;
} SAMPLING_RATE_t;


//////////////////////////////////////////////////
// Active, ADDRESS 0x09
//////////////////////////////////////////////////
typedef union {
    // Individual Fields
    struct {
        uint32_t Active : 1 ; // Bit 0
    } field;
    // Complete Value
    uint32_t value;
} ACTIVE_t;


//////////////////////////////////////////////////
// Software reset, ADDRESS 0x0F
//////////////////////////////////////////////////
typedef union {
    // Individual Fields
    struct {
        uint32_t Reset : 8 ; // Bit 0-7
    } field;
    // Complete Value
    uint32_t value;
} SOFTWARE_RESET_t;


//////////////////////////////////////////////////
// ALC Control 1, ADDRESS 0x10
//////////////////////////////////////////////////
typedef union {
    // Individual Fields
    struct {
        uint32_t ALCL    : 4 ; // Bits 0-3
        uint32_t MAXGAIN : 3 ; // Bits 4-6
        uint32_t ALCSEL  : 2 ; // Bits 7-8
    } field;
    // Complete Value
    uint32_t value;
} ALC_CONTROL_1_t;

//////////////////////////////////////////////////
// ALC Control 2, ADDRESS 0x11
//////////////////////////////////////////////////
typedef union {
    // Individual Fields
    struct {
        uint32_t ATK : 4 ; // Bits 0-3
        uint32_t DCY : 4 ; // Bits 4-7
    } field;
    // Complete Value
    uint32_t value;
} ALC_CONTROL_2_t;


//////////////////////////////////////////////////
// Noise Gate, ADDRESS 0x12
//////////////////////////////////////////////////
typedef union {
    // Individual Fields
    struct {
        uint32_t NGAT : 1 ; // Bit 0
        uint32_t NGG  : 2 ; // Bits 1-2
        uint32_t NGTH : 5 ; // Bits 3-7
    } field;
    // Complete Value
    uint32_t value;
} NOISE_GATE_t;

typedef struct {
    LEFT_CHAN_ADC_IN_VOL_t  LEFT_CHAN_ADC_IN_VOL ;
    RIGHT_CHAN_ADC_IN_VOL_t RIGHT_CHAN_ADC_IN_VOL;
    LEFT_CHAN_DAC_VOL_t     LEFT_CHAN_DAC_VOL    ;
    RIGHT_CHAN_DAC_VOL_t    RIGHT_CHAN_DAC_VOL   ;
    ANALOG_AUDIO_PATH_t     ANALOG_AUDIO_PATH    ;
    DIGITAL_AUDIO_PATH_t    DIGITAL_AUDIO_PATH   ;
    POWER_MANAGEMENT_t      POWER_MANAGEMENT     ;
    DIGITAL_AUDIO_IF_t      DIGITAL_AUDIO_IF     ;
    SAMPLING_RATE_t         SAMPLING_RATE        ;
    ACTIVE_t                ACTIVE               ;
    SOFTWARE_RESET_t        SOFTWARE_RESET       ;
    ALC_CONTROL_1_t         ALC_CONTROL_1        ;
    ALC_CONTROL_2_t         ALC_CONTROL_2        ;
    NOISE_GATE_t            NOISE_GATE           ;
} CODEC_REGISTERS_t;
#endif