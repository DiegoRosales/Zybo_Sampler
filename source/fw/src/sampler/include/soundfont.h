//////////////////////////////////////////////////////
// SoundFormat utilities
// Spec: https://www.synthfont.com/sfspec24.pdf
//////////////////////////////////////////////////////

#ifndef __SOUNDFORMAT_H__
#define __SOUNDFORMAT_H__

#include "riff_utils.h"
 
#define SF_ASCII     char     // Char
#define SF_BYTE      uint8_t  // 8-bit unsigned
#define SF_CHAR      int8_t   // 8-bit signed
#define SF_SHORT     int16_t  // 16-bit signed
#define SF_WORD      uint16_t // 16-bit unsigned
#define SF_DWORD     uint32_t // 32-bit unsigned
#define SFGenerator  uint16_t // Two bytes in length
#define SFModulator  uint16_t // Two bytes in length
#define SFTransform  uint16_t // Two bytes in length
#define SFSampleLink uint16_t // Two bytes in length


//////////////////////////////////////////////////////////////////////////////////////////////////
// Misc structures
//////////////////////////////////////////////////////////////////////////////////////////////////
typedef struct{
  SF_BYTE byLo;
  SF_BYTE byHi;
} rangesType;

typedef union{
  rangesType ranges;
  SF_SHORT   shAmount;
  SF_WORD    wAmount;
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
  RIFF_BASE_CHUNK_t BaseChunk;
  SF_WORD           wMajor;
  SF_WORD           wMinor;
} SF_IFIL_CHUNK_t;

// The isng sub-chunk is a mandatory sub-chunk identifying the wavetable sound engine for which the file was optimized. It
// contains an ASCII string of 256 or fewer bytes including one or two terminators of value zero, so as to make the total byte
// count even. The default isng field is the eight bytes representing “EMU8000” as seven ASCII characters followed by a zero
// byte.
typedef struct {
  RIFF_BASE_CHUNK_t BaseChunk;
  SF_ASCII          isng[256];
} SF_ISNG_CHUNK_t;

// The INAM sub-chunk is a mandatory sub-chunk providing the name of the SoundFont compatible bank. It contains an
// ASCII string of 256 or fewer bytes including one or two terminators of value zero, so as to make the total byte count even.
// A typical INAM sub-chunk would be the fourteen bytes representing “General MIDI” as twelve ASCII characters followed
// by two zero bytes.
typedef struct {
  RIFF_BASE_CHUNK_t BaseChunk;
  SF_ASCII          INAM[256];
} SF_INAM_CHUNK_t;

// The irom sub-chunk is an optional sub-chunk identifying a particular wavetable sound data ROM to which any ROM
// samples refer. It contains an ASCII string of 256 or fewer bytes including one or two terminators of value zero, so as to
// make the total byte count even. A typical irom field would be the six bytes representing “1MGM” as four ASCII characters
// followed by two zero bytes.
typedef struct {
  RIFF_BASE_CHUNK_t BaseChunk;
  SF_ASCII          irom[256];
} SF_IROM_CHUNK_t;

// The iver sub-chunk is an optional sub-chunk identifying the particular wavetable sound data ROM revision to which any
// ROM samples refer. It is always four bytes in length, and contains data according to the structure:
typedef struct {
  RIFF_BASE_CHUNK_t BaseChunk;
  SF_WORD           wMajor;
  SF_WORD           wMinor;
} SF_IVER_CHUNK_t;

// The ICRD sub-chunk is an optional sub-chunk identifying the creation date of the SoundFont compatible bank. It contains
// an ASCII string of 256 or fewer bytes including one or two terminators of value zero, so as to make the total byte count
// even. A typical ICRD field would be the twelve bytes representing “May 1, 1995” as eleven ASCII characters followed by
// a zero byte.
typedef struct {
  RIFF_BASE_CHUNK_t BaseChunk;
  SF_ASCII          ICRD[256];
} SF_ICRD_CHUNK_t;

// The IENG sub-chunk is an optional sub-chunk identifying the names of any sound designers or engineers responsible for
// the SoundFont compatible bank. It contains an ASCII string of 256 or fewer bytes including one or two terminators of
// value zero, so as to make the total byte count even. A typical IENG field would be the twelve bytes representing “Tim
// Swartz” as ten ASCII characters followed by two zero bytes
typedef struct {
  RIFF_BASE_CHUNK_t BaseChunk;
  SF_ASCII          IENG[256];
} SF_IENG_CHUNK_t;

// The IPRD sub-chunk is an optional sub-chunk identifying any specific product for which the SoundFont compatible bank is
// intended. It contains an ASCII string of 256 or fewer bytes including one or two terminators of value zero, so as to make
// the total byte count even. A typical IPRD field would be the eight bytes representing “SBAWE32” as seven ASCII
// characters followed by a zero byte.
typedef struct {
  RIFF_BASE_CHUNK_t BaseChunk;
  SF_ASCII          IPRD[256];
} SF_IPRD_CHUNK_t;

// The ICOP sub-chunk is an optional sub-chunk containing any copyright assertion string associated with the SoundFont
// compatible bank. It contains an ASCII string of 256 or fewer bytes including one or two terminators of value zero, so as to
// make the total byte count even. A typical ICOP field would be the 40 bytes representing “Copyright (c) 1995 E-mu
// Systems, Inc.” as 38 ASCII characters followed by two zero bytes.
typedef struct {
  RIFF_BASE_CHUNK_t BaseChunk;
  SF_ASCII          ICOP[256];
} SF_ICOP_CHUNK_t;

// The ICMT sub-chunk is an optional sub-chunk containing any comments associated with the SoundFont compatible bank.
// It contains an ASCII string of 65,536 or fewer bytes including one or two terminators of value zero, so as to make the total
// byte count even. A typical ICMT field would be the 40 bytes representing “This space unintentionally left blank.” as 38
// ASCII characters followed by two zero bytes.
typedef struct {
  RIFF_BASE_CHUNK_t BaseChunk;
  SF_ASCII          ICMT[65536];
} SF_ICMT_CHUNK_t;

// The ISFT sub-chunk is an optional sub-chunk identifying the SoundFont compatible tools used to create and most recently
// modify the SoundFont compatible bank. It contains an ASCII string of 256 or fewer bytes including one or two terminators
// of value zero, so as to make the total byte count even. A typical ISFT field would be the thirty bytes representing “Preditor
// 2.00a:Preditor 2.00a” as twenty-nine ASCII characters followed by a zero byte.
typedef struct {
  RIFF_BASE_CHUNK_t BaseChunk;
  SF_ASCII          ISFT[256];
} SF_ISFT_CHUNK_t;

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
  SF_SHORT          smpl;
} SF_SMPL_CHUNK_t;

// The sm24 sub-chunk, if present, contains the least significant byte counterparts to each sample data point contained in the
// smpl chunk. Note this means for every two bytes in the [smpl] sub-chunk there is a 1-byte counterpart in [sm24] sub-chunk.
typedef struct {
  RIFF_BASE_CHUNK_t BaseChunk;
  SF_BYTE           sm24;
} SF_SM24_CHUNK_t;

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
typedef struct{
  RIFF_BASE_CHUNK_t BaseChunk;
  SF_CHAR           achPresetName[20];
  SF_WORD           wPreset;
  SF_WORD           wBank;
  SF_WORD           wPresetBagNdx;
  SF_DWORD          dwLibrary;
  SF_DWORD          dwGenre;
  SF_DWORD          dwMorphology;
} SF_PHDR_CHUNK_t;

// The PBAG sub-chunk is a required sub-chunk listing all preset zones within the SoundFont compatible file. It is always a
// multiple of four bytes in length, and contains one record for each preset zone plus one record for a terminal zone according
// to the structure:
typedef struct{
  RIFF_BASE_CHUNK_t BaseChunk;
  SF_WORD           wGenNdx;
  SF_WORD           wModNdx;
} SF_PBAG_CHUNK_t;

// The PMOD sub-chunk is a required sub-chunk listing all preset zone modulators within the SoundFont compatible file. It is
// always a multiple of ten bytes in length, and contains zero or more modulators plus a terminal record according to the
// structure:
typedef struct{
  RIFF_BASE_CHUNK_t BaseChunk;
  SFModulator       sfModSrcOper;
  SFGenerator       sfModDestOper;
  SF_SHORT          modAmount;
  SFModulator       sfModAmtSrcOper;
  SFTransform       sfModTransOper;
} SF_PMOD_CHUNK_t;

// The PGEN chunk is a required chunk containing a list of preset zone generators for each preset zone within the SoundFont
// compatible file. It is always a multiple of four bytes in length, and contains one or more generators for each preset zone
// (except a global zone containing only modulators) plus a terminal record according to the structure:
typedef struct{
  RIFF_BASE_CHUNK_t BaseChunk;
  SFGenerator       sfGenOper;
  genAmountType     genAmount;
} SF_PGEN_CHUNK_t;

// The inst sub-chunk is a required sub-chunk listing all instruments within the SoundFont compatible file. It is always a
// multiple of twenty-two bytes in length, and contains a minimum of two records, one record for each instrument and one for
// a terminal record according to the structure:
typedef struct{
  RIFF_BASE_CHUNK_t BaseChunk;
  SF_CHAR           achInstName[20];
  SF_WORD           wInstBagNdx;
} SF_INST_CHUNK_t;

// The IBAG sub-chunk is a required sub-chunk listing all instrument zones within the SoundFont compatible file. It is always
// a multiple of four bytes in length, and contains one record for each instrument zone plus one record for a terminal zone
// according to the structure:
typedef struct{
  RIFF_BASE_CHUNK_t BaseChunk;
  SF_WORD           wInstGenNdx;
  SF_WORD           wInstModNdx;
} SF_IBAG_CHUNK_t;

// The IMOD sub-chunk is a required sub-chunk listing all instrument zone modulators within the SoundFont compatible file.
// It is always a multiple of ten bytes in length, and contains zero or more modulators plus a terminal record according to the
// structure:
typedef struct{
  RIFF_BASE_CHUNK_t BaseChunk;
  SFModulator       sfModSrcOper;
  SFGenerator       sfModDestOper;
  SF_SHORT          modAmount;
  SFModulator       sfModAmtSrcOper;
  SFTransform       sfModTransOper;
} SF_IMOD_CHUNK_t;

// The IGEN chunk is a required chunk containing a list of zone generators for each instrument zone within the SoundFont
// compatible file. It is always a multiple of four bytes in length, and contains one or more generators for each zone (except
// for a global zone containing only modulators) plus a terminal record according to the structure:
typedef struct{
  RIFF_BASE_CHUNK_t BaseChunk;
  SFGenerator       sfGenOper;
  genAmountType     genAmount;
} SF_IGEN_CHUNK_t;

// The SHDR chunk is a required sub-chunk listing all samples within the smpl sub-chunk and any referenced ROM samples.
// It is always a multiple of forty-six bytes in length, and contains one record for each sample plus a terminal record according
// to the structure:
typedef struct{
  RIFF_BASE_CHUNK_t BaseChunk;
  SF_CHAR           achSampleName[20];
  SF_DWORD          dwStart;
  SF_DWORD          dwEnd;
  SF_DWORD          dwStartloop;
  SF_DWORD          dwEndloop;
  SF_DWORD          dwSampleRate;
  SF_BYTE           byOriginalPitch;
  SF_CHAR           chPitchCorrection;
  SF_WORD           wSampleLink;
  SFSampleLink      sfSampleType;
} SF_SHDR_CHUNK_t;

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
#endif