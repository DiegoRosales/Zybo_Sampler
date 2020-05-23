
// C includes
#include <string.h>

// Xilinx includes
#include "xil_cache.h"
#include "xil_printf.h"

// FreeRTOS Includes
#include "FreeRTOS.h"
#include "task.h"
#include "semphr.h"
#include "queue.h"
#include "FreeRTOS_CLI.h"

// FreeRTOS+FAT includes
#include "ff_stdio.h"
#include "ff_ramdisk.h"
#include "ff_sddisk.h"

// Sampler Includes
#include "sampler_CLI_apps.h"
#include "sampler_FreeRTOS_tasks.h"
#include "sampler_dma_voice_pb.h"
#include "sampler_engine.h"
#include "nco.h"

// CLI Apps
#include "SamplerCMDRegisterFunctions.h"

// This function registers all the CLI applications
void vRegisterSamplerCLICommands( void ) {
    // Register commands
    vRegisterPlayKeyCMD();
    vRegisterLoadSineWaveCMD();
    vRegisterPlaybackSineWaveCMD();
    vRegisterPrintSF2InfoCMD();
    vRegisterStartMIDIListenerCMD();
    vRegisterStopAllPlaybackCMD();
    vRegisterMIDIKeyPlayASCIICMD();
    vRegisterMIDIKeyPlayCMD();
    vRegisterLoadSF2CMD();
    vRegisterLoadInstrumentCMD();
}




