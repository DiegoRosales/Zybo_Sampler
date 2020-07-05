//////////////////////////////////////////
// FreeRTOS Tasks for the sampler engine
//////////////////////////////////////////

// C includes
#include <string.h>

// Xilinx Includes
#include "xil_printf.h"
#include "xparameters.h"
#include "xgpio.h"

// FreeRTOS Includes
#include "FreeRTOS.h"
#include "task.h"
#include "semphr.h"
#include "queue.h"

// FreeRTOS+FAT includes
#include "ff_stdio.h"
#include "ff_ramdisk.h"
#include "ff_sddisk.h"
#include "fat_CLI_apps.h"

// Serial includes
#include "serial_driver.h"

// Sampler Includes
#include "sampler_FreeRTOS_tasks.h"
#include "sampler_cfg.h"
#include "patch_loader.h"
#include "sampler_engine.h"

PATCH_DESCRIPTOR_t *patch_descriptor = NULL;

// Tasks (each implemented on its own file)
extern void vRegisterKeyPlaybackTask();
extern void vRegisterStopAllPlaybackTask();
extern void vRegisterLoadInstrumentTask();
extern void vRegisterLoadSF2Task();
extern void vRegisterPrintSF2InfoTask();
extern void vRegisterRunMIDICommandTask();
extern void vRegisterSerialMIDIListenerTask();

// Register task definitions
void vRegisterSamplerEngineTasks ( void ) {
    vRegisterKeyPlaybackTask();
    vRegisterStopAllPlaybackTask();
    vRegisterLoadInstrumentTask();
    vRegisterLoadSF2Task();
    vRegisterPrintSF2InfoTask();
    vRegisterRunMIDICommandTask();
    vRegisterSerialMIDIListenerTask();
}
