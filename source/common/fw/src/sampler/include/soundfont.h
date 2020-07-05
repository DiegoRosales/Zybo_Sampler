//////////////////////////////////////////////////////
// SoundFormat utilities
// Spec: https://www.synthfont.com/sfspec24.pdf
//////////////////////////////////////////////////////

#ifndef __SOUNDFORMAT_H__
#define __SOUNDFORMAT_H__

#include "riff_utils.h"

/////////////////////////////////////////
// RIFF ChunkID Tokens
/////////////////////////////////////////

// List Chunk Tokens
#define SFBK_ASCII_TOKEN   0x6b626673 // ASCII String == "sfbk"
#define INFO_ASCII_TOKEN   0x4F464E49 // ASCII String == "INFO"
#define SDTA_ASCII_TOKEN   0x61746473 // ASCII String == "sdta"
#define PDTA_ASCII_TOKEN   0x61746470 // ASCII String == "pdta"

// Sub List Chunk Tokens
// INFO
#define IFIL_ASCII_TOKEN 0x6C696669 // ASCII String == "ifil"
#define ISNG_ASCII_TOKEN 0x676E7369 // ASCII String == "isng"
#define INAM_ASCII_TOKEN 0x4D414E49 // ASCII String == "INAM"
#define IROM_ASCII_TOKEN 0x6D6F7269 // ASCII String == "irom"
#define IVER_ASCII_TOKEN 0x72657669 // ASCII String == "iver"
#define ICRD_ASCII_TOKEN 0x44524349 // ASCII String == "ICRD"
#define IENG_ASCII_TOKEN 0x474E4549 // ASCII String == "IENG"
#define IPRD_ASCII_TOKEN 0x44525049 // ASCII String == "IPRD"
#define ICOP_ASCII_TOKEN 0x504F4349 // ASCII String == "ICOP"
#define ICMT_ASCII_TOKEN 0x544D4349 // ASCII String == "ICMT"
#define ISFT_ASCII_TOKEN 0x54465349 // ASCII String == "ISFT"

// SDTA
#define SMPL_ASCII_TOKEN 0x6C706D73 // ASCII String == "smpl"
#define SM24_ASCII_TOKEN 0x34326D73 // ASCII String == "sm24"

// PDTA
#define PHDR_ASCII_TOKEN 0x72646870 // ASCII String == "phdr"
#define PBAG_ASCII_TOKEN 0x67616270 // ASCII String == "pbag"
#define PMOD_ASCII_TOKEN 0x646F6D70 // ASCII String == "pmod"
#define PGEN_ASCII_TOKEN 0x6E656770 // ASCII String == "pgen"
#define INST_ASCII_TOKEN 0x74736E69 // ASCII String == "inst"
#define IBAG_ASCII_TOKEN 0x67616269 // ASCII String == "ibag"
#define IMOD_ASCII_TOKEN 0x646F6D69 // ASCII String == "imod"
#define IGEN_ASCII_TOKEN 0x6E656769 // ASCII String == "igen"
#define SHDR_ASCII_TOKEN 0x72646873 // ASCII String == "shdr"

/////////////////////////////////////////
// Misc. Constants from the SoundFont spec
/////////////////////////////////////////
// PHDR
#define SF_PHDR_DATA_LEN      38 // Each data segment is 38 bytes long
#define SF_PHDR_PRST_NAME_LEN 20 // The preset name is 20 characters long
// SHDR
#define SF_SHDR_DATA_LEN      46 // Each data segment is 46 bytes long
#define SF_SHDR_PRST_NAME_LEN 20 // The preset name is 20 characters long

/////////////////////////////////////////
// SoundFont Data types
/////////////////////////////////////////
typedef char     SF_ASCII_t;     // Char
typedef uint8_t  SF_BYTE_t;      // 8-bit unsigned
typedef int8_t   SF_CHAR_t;      // 8-bit signed
typedef int16_t  SF_SHORT_t;     // 16-bit signed
typedef uint16_t SF_WORD_t;      // 16-bit unsigned
typedef uint32_t SF_DWORD_t;     // 32-bit unsigned
typedef uint16_t SFGenerator_t;  // Two bytes in length
typedef uint16_t SFModulator_t;  // Two bytes in length
typedef uint16_t SFTransform_t;  // Two bytes in length
typedef uint16_t SFSampleLink_t; // Two bytes in length


//////////////////////////////////////////////////////////////////////////////////////////////////
// Misc structures
//////////////////////////////////////////////////////////////////////////////////////////////////
typedef struct{
  SF_BYTE_t byLo;
  SF_BYTE_t byHi;
} rangesType;

typedef union{
  rangesType ranges;
  SF_SHORT_t   shAmount;
  SF_WORD_t    wAmount;
} genAmountType;

//////////////////////////////////////////////////////////////////////////////////////////////////
// Enumerators
//////////////////////////////////////////////////////////////////////////////////////////////////
typedef enum {
  startAddrsOffset             = 0,
  endAddrsOffset               = 1,
  startloopAddrsOffset         = 2,
  endloopAddrsOffset           = 3,
  startAddrsCoarseOffset       = 4,
  modLfoToPitch                = 5,
  vibLfoToPitch                = 6,
  modEnvToPitch                = 7,
  initialFilterFc              = 8,
  initialFilterQ               = 9,
  modLfoToFilterFc             = 10,
  modEnvToFilterFc             = 11,
  endAddrsCoarseOffset         = 12,
  modLfoToVolume               = 13,
  chorusEffectsSend            = 15,
  reverbEffectsSend            = 16,
  pan                          = 17,
  delayModLFO                  = 21,
  freqModLFO                   = 22,
  delayVibLFO                  = 23,
  freqVibLFO                   = 24,
  delayModEnv                  = 25,
  attackModEnv                 = 26,
  holdModEnv                   = 27,
  decayModEnv                  = 28,
  sustainModEnv                = 29,
  releaseModEnv                = 30,
  keynumToModEnvHold           = 31,
  keynumToModEnvDecay          = 32,
  delayVolEnv                  = 33,
  attackVolEnv                 = 34,
  holdVolEnv                   = 35,
  decayVolEnv                  = 36,
  sustainVolEnv                = 37,
  releaseVolEnv                = 38,
  keynumToVolEnvHold           = 39,
  keynumToVolEnvDecay          = 40,
  keyRange                     = 43,
  velRange                     = 44,
  startloopAddrsCoarseOffset   = 45,
  keynum                       = 46,
  velocity                     = 47,
  initialAttenuation           = 48,
  endloopAddrsCoarseOffset     = 50,
  coarseTune                   = 51,
  fineTune                     = 52,
  sampleModes                  = 54,
  scaleTuning                  = 56,
  exclusiveClass               = 57,
  overridingRootKey            = 58
} SFGenerator_enum;

typedef enum {
  noController          = 0,
  noteOnVelocity        = 2,
  noteOnKeyNumber       = 3,
  polyPressure          = 10,
  channelPressure       = 13,
  pitchWheel            = 14,
  pitchWheelSensitivity = 16,
  link                  = 127
} SFModulator_enum;

typedef enum {
  linear        = 0,
  absoluteValue = 2
} SFTransform_enum;

typedef enum {
  monoSample      = 1,
  rightSample     = 2,
  leftSample      = 4,
  linkedSample    = 8,
  RomMonoSample   = 0x8001,
  RomRightSample  = 0x8002,
  RomLeftSample   = 0x8004,
  RomLinkedSample = 0x8008
} SFSampleLink_enum;

//////////////////////////////////////////////////////////////////////////////////////////////////
// General Overview
//////////////////////////////////////////////////////////////////////////////////////////////////
// SF2 RIFF File Format Level 0
//<SFBK-form> -> RIFF (‘sfbk’ ; RIFF form header
//                      {
//                        <INFO-list> ; Supplemental Information
//                        <sdta-list> ; The Sample Binary Data
//                        <pdta-list> ; The Preset, Instrument, and Sample Header data
//                      }
//                    )
//////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////
// Details
//////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////
//<INFO-list> -> LIST (‘INFO’
//                      {
//                        <ifil-ck> ; Refers to the version of the Sound Font RIFF file
//                        <isng-ck> ; Refers to the target Sound Engine
//                        <INAM-ck> ; Refers to the Sound Font Bank Name
//                        [<irom-ck>] ; Refers to the Sound ROM Name
//                        [<iver-ck>] ; Refers to the Sound ROM Version
//                        [<ICRD-ck>] ; Refers to the Date of Creation of the Bank
//                        [<IENG-ck>] ; Sound Designers and Engineers for the Bank
//                        [<IPRD-ck>] ; Product for which the Bank was intended
//                        [<ICOP-ck>] ; Contains any Copyright message
//                        [<ICMT-ck>] ; Contains any Comments on the Bank
//                        [<ISFT-ck>] ; The SoundFont tools used to create and alter the bank
//                      }
//                    )
//////////////////////////////////////////////////////////////////////////////////////////////////
// The ifil sub-chunk is a mandatory sub-chunk identifying the SoundFont specification version level to which the file
// complies. It is always four bytes in length, and contains data according to the structure:
typedef struct {
  SF_WORD_t           wMajor;
  SF_WORD_t           wMinor;
} __attribute__((packed)) SF_IFIL_CHUNK_DATA_t;

typedef struct {
  RIFF_BASE_CHUNK_t BaseChunk;
  SF_IFIL_CHUNK_DATA_t SF_IFIL_CHUNK_DATA;
} __attribute__((packed)) SF_IFIL_CHUNK_t;

// The isng sub-chunk is a mandatory sub-chunk identifying the wavetable sound engine for which the file was optimized. It
// contains an ASCII string of 256 or fewer bytes including one or two terminators of value zero, so as to make the total byte
// count even. The default isng field is the eight bytes representing “EMU8000” as seven ASCII characters followed by a zero
// byte.
typedef struct {
  SF_ASCII_t isng[256];
} __attribute__((packed)) SF_ISNG_CHUNK_DATA_t;

typedef struct {
  RIFF_BASE_CHUNK_t BaseChunk;
  SF_ISNG_CHUNK_DATA_t SF_ISNG_CHUNK_DATA;
} __attribute__((packed)) SF_ISNG_CHUNK_t;

// The INAM sub-chunk is a mandatory sub-chunk providing the name of the SoundFont compatible bank. It contains an
// ASCII string of 256 or fewer bytes including one or two terminators of value zero, so as to make the total byte count even.
// A typical INAM sub-chunk would be the fourteen bytes representing “General MIDI” as twelve ASCII characters followed
// by two zero bytes.
typedef struct {
  SF_ASCII_t          INAM[256];
} __attribute__((packed)) SF_INAM_CHUNK_DATA_t;

typedef struct {
  RIFF_BASE_CHUNK_t BaseChunk;
  SF_INAM_CHUNK_DATA_t SF_INAM_CHUNK_DATA;
} __attribute__((packed)) SF_INAM_CHUNK_t;

// The irom sub-chunk is an optional sub-chunk identifying a particular wavetable sound data ROM to which any ROM
// samples refer. It contains an ASCII string of 256 or fewer bytes including one or two terminators of value zero, so as to
// make the total byte count even. A typical irom field would be the six bytes representing “1MGM” as four ASCII characters
// followed by two zero bytes.
typedef struct {
  SF_ASCII_t          irom[256];
} __attribute__((packed)) SF_IROM_CHUNK_DATA_t;

typedef struct {
  RIFF_BASE_CHUNK_t BaseChunk;
  SF_IROM_CHUNK_DATA_t SF_IROM_CHUNK_DATA;
} __attribute__((packed)) SF_IROM_CHUNK_t;

// The iver sub-chunk is an optional sub-chunk identifying the particular wavetable sound data ROM revision to which any
// ROM samples refer. It is always four bytes in length, and contains data according to the structure:
typedef struct {
  SF_WORD_t           wMajor;
  SF_WORD_t           wMinor;
} __attribute__((packed)) SF_IVER_CHUNK_DATA_t;

typedef struct {
  RIFF_BASE_CHUNK_t BaseChunk;
  SF_IVER_CHUNK_DATA_t SF_IVER_CHUNK_DATA;
} __attribute__((packed)) SF_IVER_CHUNK_t;

// The ICRD sub-chunk is an optional sub-chunk identifying the creation date of the SoundFont compatible bank. It contains
// an ASCII string of 256 or fewer bytes including one or two terminators of value zero, so as to make the total byte count
// even. A typical ICRD field would be the twelve bytes representing “May 1, 1995” as eleven ASCII characters followed by
// a zero byte.
typedef struct {
  SF_ASCII_t          ICRD[256];
} __attribute__((packed)) SF_ICRD_CHUNK_DATA_t;

typedef struct {
  RIFF_BASE_CHUNK_t BaseChunk;
  SF_ICRD_CHUNK_DATA_t SF_ICRD_CHUNK_DATA;
} __attribute__((packed)) SF_ICRD_CHUNK_t;

// The IENG sub-chunk is an optional sub-chunk identifying the names of any sound designers or engineers responsible for
// the SoundFont compatible bank. It contains an ASCII string of 256 or fewer bytes including one or two terminators of
// value zero, so as to make the total byte count even. A typical IENG field would be the twelve bytes representing “Tim
// Swartz” as ten ASCII characters followed by two zero bytes
typedef struct {
  SF_ASCII_t          IENG[256];
} __attribute__((packed)) SF_IENG_CHUNK_DATA_t;

typedef struct {
  RIFF_BASE_CHUNK_t BaseChunk;
  SF_IENG_CHUNK_DATA_t SF_IENG_CHUNK_DATA;
} __attribute__((packed)) SF_IENG_CHUNK_t;

// The IPRD sub-chunk is an optional sub-chunk identifying any specific product for which the SoundFont compatible bank is
// intended. It contains an ASCII string of 256 or fewer bytes including one or two terminators of value zero, so as to make
// the total byte count even. A typical IPRD field would be the eight bytes representing “SBAWE32” as seven ASCII
// characters followed by a zero byte.
typedef struct {
  SF_ASCII_t          IPRD[256];
} __attribute__((packed)) SF_IPRD_CHUNK_DATA_t;

typedef struct {
  RIFF_BASE_CHUNK_t BaseChunk;
  SF_IPRD_CHUNK_DATA_t SF_IPRD_CHUNK_DATA;
} __attribute__((packed)) SF_IPRD_CHUNK_t;

// The ICOP sub-chunk is an optional sub-chunk containing any copyright assertion string associated with the SoundFont
// compatible bank. It contains an ASCII string of 256 or fewer bytes including one or two terminators of value zero, so as to
// make the total byte count even. A typical ICOP field would be the 40 bytes representing “Copyright (c) 1995 E-mu
// Systems, Inc.” as 38 ASCII characters followed by two zero bytes.
typedef struct {
  SF_ASCII_t          ICOP[256];
} __attribute__((packed)) SF_ICOP_CHUNK_DATA_t;

typedef struct {
  RIFF_BASE_CHUNK_t BaseChunk;
  SF_ICOP_CHUNK_DATA_t SF_ICOP_CHUNK_DATA;
} __attribute__((packed)) SF_ICOP_CHUNK_t;

// The ICMT sub-chunk is an optional sub-chunk containing any comments associated with the SoundFont compatible bank.
// It contains an ASCII string of 65,536 or fewer bytes including one or two terminators of value zero, so as to make the total
// byte count even. A typical ICMT field would be the 40 bytes representing “This space unintentionally left blank.” as 38
// ASCII characters followed by two zero bytes.
typedef struct {
  SF_ASCII_t          ICMT[65536];
} __attribute__((packed)) SF_ICMT_CHUNK_DATA_t;

typedef struct {
  RIFF_BASE_CHUNK_t BaseChunk;
  SF_ICMT_CHUNK_DATA_t SF_ICMT_CHUNK_DATA;
} __attribute__((packed)) SF_ICMT_CHUNK_t;

// The ISFT sub-chunk is an optional sub-chunk identifying the SoundFont compatible tools used to create and most recently
// modify the SoundFont compatible bank. It contains an ASCII string of 256 or fewer bytes including one or two terminators
// of value zero, so as to make the total byte count even. A typical ISFT field would be the thirty bytes representing “Preditor
// 2.00a:Preditor 2.00a” as twenty-nine ASCII characters followed by a zero byte.
typedef struct {
  SF_ASCII_t          ISFT[256];
} __attribute__((packed)) SF_ISFT_CHUNK_DATA_t;

typedef struct {
  RIFF_BASE_CHUNK_t BaseChunk;
  SF_ISFT_CHUNK_DATA_t SF_ISFT_CHUNK_DATA;
} __attribute__((packed)) SF_ISFT_CHUNK_t;

// All Combined
typedef struct {
  SF_IFIL_CHUNK_t * IFIL_CHUNK;
  SF_ISNG_CHUNK_t * ISNG_CHUNK;
  SF_INAM_CHUNK_t * INAM_CHUNK;
  SF_IROM_CHUNK_t * IROM_CHUNK;
  SF_IVER_CHUNK_t * IVER_CHUNK;
  SF_ICRD_CHUNK_t * ICRD_CHUNK;
  SF_IENG_CHUNK_t * IENG_CHUNK;
  SF_IPRD_CHUNK_t * IPRD_CHUNK;
  SF_ICOP_CHUNK_t * ICOP_CHUNK;
  SF_ICMT_CHUNK_t * ICMT_CHUNK;
  SF_ISFT_CHUNK_t * ISFT_CHUNK;
} SF_INFO_LIST_DESCRIPTOR_t;

//////////////////////////////////////////////////////////////////////////////////////////////////
//<sdta-ck> -> LIST (‘sdta’
//                    {
//                      [<smpl-ck>] ; The Digital Audio Samples for the upper 16 bits
//                    }
//                    {
//                      [<sm24-ck>] ; The Digital Audio Samples for the lower 8 bits
//                    }
//                  )
//////////////////////////////////////////////////////////////////////////////////////////////////
// The smpl sub-chunk, if present, contains one or more “samples” of digital audio information in the form of linearly coded
// sixteen bit, signed, little endian (least significant byte first) words. Each sample is followed by a minimum of forty-six zero
// valued sample data points. These zero valued data points are necessary to guarantee that any reasonable upward pitch shift
// using any reasonable interpolator can loop on zero data at the end of the sound
typedef struct {
  RIFF_BASE_CHUNK_t BaseChunk;
  SF_SHORT_t        smpl;
} __attribute__((packed)) SF_SMPL_CHUNK_t;

// The sm24 sub-chunk, if present, contains the least significant byte counterparts to each sample data point contained in the
// smpl chunk. Note this means for every two bytes in the [smpl] sub-chunk there is a 1-byte counterpart in [sm24] sub-chunk.
typedef struct {
  RIFF_BASE_CHUNK_t BaseChunk;
  SF_BYTE_t         sm24;
} __attribute__((packed)) SF_SM24_CHUNK_t;

// All Combined
typedef struct {
  SF_SMPL_CHUNK_t * SMPL_CHUNK;
  SF_SM24_CHUNK_t * SM24_CHUNK;
} SF_SDATA_LIST_DESCRIPTOR_t;

//////////////////////////////////////////////////////////////////////////////////////////////////
//<pdta-ck> -> LIST (‘pdta’
//                    {
//                      <phdr-ck> ; The Preset Headers
//                      <pbag-ck> ; The Preset Index list
//                      <pmod-ck> ; The Preset Modulator list
//                      <pgen-ck> ; The Preset Generator list
//                      <inst-ck> ; The Instrument Names and Indices
//                      <ibag-ck> ; The Instrument Index list
//                      <imod-ck> ; The Instrument Modulator list
//                      <igen-ck> ; The Instrument Generator list
//                      <shdr-ck> ; The Sample Headers
//                    }
//                  )
//////////////////////////////////////////////////////////////////////////////////////////////////

// The PHDR sub-chunk is a required sub-chunk listing all presets within the SoundFont compatible file. It is always a
// multiple of thirty-eight bytes in length, and contains a minimum of two records, one record for each preset and one for a
// terminal record according to the structure:
typedef struct {
  SF_CHAR_t           achPresetName[SF_PHDR_PRST_NAME_LEN];
  SF_WORD_t           wPreset;
  SF_WORD_t           wBank;
  SF_WORD_t           wPresetBagNdx;
  SF_DWORD_t          dwLibrary;
  SF_DWORD_t          dwGenre;
  SF_DWORD_t          dwMorphology;
} __attribute__((packed)) SF_PHDR_CHUNK_DATA_t;

typedef struct{
  RIFF_BASE_CHUNK_t    BaseChunk;
  SF_PHDR_CHUNK_DATA_t SF_PHDR_CHUNK_DATA;
} __attribute__((packed)) SF_PHDR_CHUNK_t;


// The PBAG sub-chunk is a required sub-chunk listing all preset zones within the SoundFont compatible file. It is always a
// multiple of four bytes in length, and contains one record for each preset zone plus one record for a terminal zone according
// to the structure:
typedef struct {
  SF_WORD_t           wGenNdx;
  SF_WORD_t           wModNdx;
} __attribute__((packed)) SF_PBAG_CHUNK_DATA_t;

typedef struct{
  RIFF_BASE_CHUNK_t    BaseChunk;
  SF_PBAG_CHUNK_DATA_t SF_PBAG_CHUNK_DATA;
} __attribute__((packed)) SF_PBAG_CHUNK_t;


// The PMOD sub-chunk is a required sub-chunk listing all preset zone modulators within the SoundFont compatible file. It is
// always a multiple of ten bytes in length, and contains zero or more modulators plus a terminal record according to the
// structure:
typedef struct {
  SFModulator_t     sfModSrcOper;
  SFGenerator_t     sfModDestOper;
  SF_SHORT_t        modAmount;
  SFModulator_t     sfModAmtSrcOper;
  SFTransform_t     sfModTransOper;
} __attribute__((packed)) SF_PMOD_CHUNK_DATA_t;

typedef struct{
  RIFF_BASE_CHUNK_t    BaseChunk;
  SF_PMOD_CHUNK_DATA_t SF_PMOD_CHUNK_DATA;
} __attribute__((packed)) SF_PMOD_CHUNK_t;


// The PGEN chunk is a required chunk containing a list of preset zone generators for each preset zone within the SoundFont
// compatible file. It is always a multiple of four bytes in length, and contains one or more generators for each preset zone
// (except a global zone containing only modulators) plus a terminal record according to the structure:
typedef struct {
  SFGenerator_t     sfGenOper;
  genAmountType     genAmount;
} __attribute__((packed)) SF_PGEN_CHUNK_DATA_t;

typedef struct{
  RIFF_BASE_CHUNK_t    BaseChunk;
  SF_PGEN_CHUNK_DATA_t SF_PGEN_CHUNK_DATA;
} __attribute__((packed)) SF_PGEN_CHUNK_t;


// The inst sub-chunk is a required sub-chunk listing all instruments within the SoundFont compatible file. It is always a
// multiple of twenty-two bytes in length, and contains a minimum of two records, one record for each instrument and one for
// a terminal record according to the structure:
typedef struct {
  SF_CHAR_t         achInstName[20];
  SF_WORD_t         wInstBagNdx;
} __attribute__((packed)) SF_INST_CHUNK_DATA_t;

typedef struct{
  RIFF_BASE_CHUNK_t    BaseChunk;
  SF_INST_CHUNK_DATA_t SF_INST_CHUNK_DATA;
} __attribute__((packed)) SF_INST_CHUNK_t;


// The IBAG sub-chunk is a required sub-chunk listing all instrument zones within the SoundFont compatible file. It is always
// a multiple of four bytes in length, and contains one record for each instrument zone plus one record for a terminal zone
// according to the structure:
typedef struct {
  SF_WORD_t         wInstGenNdx;
  SF_WORD_t         wInstModNdx;
} __attribute__((packed)) SF_IBAG_CHUNK_DATA_t;

typedef struct{
  RIFF_BASE_CHUNK_t BaseChunk;
} __attribute__((packed)) SF_IBAG_CHUNK_t;   

// The IMOD sub-chunk is a required sub-chunk listing all instrument zone modulators within the SoundFont compatible file.
// It is always a multiple of ten bytes in length, and contains zero or more modulators plus a terminal record according to the
// structure:
typedef struct {
  SFModulator_t     sfModSrcOper;
  SFGenerator_t     sfModDestOper;
  SF_SHORT_t        modAmount;
  SFModulator_t     sfModAmtSrcOper;
  SFTransform_t     sfModTransOper;
} __attribute__((packed)) SF_IMOD_CHUNK_DATA_t;

typedef struct{
  RIFF_BASE_CHUNK_t    BaseChunk;
  SF_IMOD_CHUNK_DATA_t SF_IMOD_CHUNK_DATA;
} __attribute__((packed)) SF_IMOD_CHUNK_t;


// The IGEN chunk is a required chunk containing a list of zone generators for each instrument zone within the SoundFont
// compatible file. It is always a multiple of four bytes in length, and contains one or more generators for each zone (except
// for a global zone containing only modulators) plus a terminal record according to the structure:
typedef struct {
  SFGenerator_t     sfGenOper;
  genAmountType     genAmount;
} __attribute__((packed)) SF_IGEN_CHUNK_DATA_t;

typedef struct{
  RIFF_BASE_CHUNK_t    BaseChunk;
  SF_IGEN_CHUNK_DATA_t SF_IGEN_CHUNK_DATA;
} __attribute__((packed)) SF_IGEN_CHUNK_t;


// The SHDR chunk is a required sub-chunk listing all samples within the smpl sub-chunk and any referenced ROM samples.
// It is always a multiple of forty-six bytes in length, and contains one record for each sample plus a terminal record according
// to the structure:
typedef struct {
  SF_CHAR_t         achSampleName[SF_SHDR_PRST_NAME_LEN];
  SF_DWORD_t        dwStart;
  SF_DWORD_t        dwEnd;
  SF_DWORD_t        dwStartloop;
  SF_DWORD_t        dwEndloop;
  SF_DWORD_t        dwSampleRate;
  SF_BYTE_t         byOriginalPitch;
  SF_CHAR_t         chPitchCorrection;
  SF_WORD_t         wSampleLink;
  SFSampleLink_t    sfSampleType;
} __attribute__((packed)) SF_SHDR_CHUNK_DATA_t;

typedef struct{
  RIFF_BASE_CHUNK_t    BaseChunk;
  SF_SHDR_CHUNK_DATA_t SF_SHDR_CHUNK_DATA;
} __attribute__((packed)) SF_SHDR_CHUNK_t;


// All combined
typedef struct {
  SF_PHDR_CHUNK_t * PHDR_CHUNK;
  SF_PBAG_CHUNK_t * PBAG_CHUNK;
  SF_PMOD_CHUNK_t * PMOD_CHUNK;
  SF_PGEN_CHUNK_t * PGEN_CHUNK;
  SF_INST_CHUNK_t * INST_CHUNK;
  SF_IBAG_CHUNK_t * IBAG_CHUNK;
  SF_IMOD_CHUNK_t * IMOD_CHUNK;
  SF_IGEN_CHUNK_t * IGEN_CHUNK;
  SF_SHDR_CHUNK_t * SHDR_CHUNK;
} SF_PDATA_LIST_DESCRIPTOR_t;

/////////////////////////////////////////////////////////////////////
// All descriptors combined
/////////////////////////////////////////////////////////////////////

typedef struct {
  SF_INFO_LIST_DESCRIPTOR_t  sf_info_list_descriptor;
  SF_SDATA_LIST_DESCRIPTOR_t sf_sdata_list_descriptor;
  SF_PDATA_LIST_DESCRIPTOR_t sf_pdata_list_descriptor;
} SF_DESCRIPTOR_t;


#endif