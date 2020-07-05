// main.c
///////////////////////////////////////////////
// This is the main file that will be called //
// at the start                              //
///////////////////////////////////////////////

//////////////////////////////////////////
#define configUNIQUE_INTERRUPT_PRIORITIES 32
//////////////////////////////////////////

/////////////////////////////////////////
// Xilinx Includes
/////////////////////////////////////////

#include "xil_printf.h"
#include "xparameters.h" 
#include "xgpio.h"
#include "portmacro.h"

/////////////////////////////////////////
// FreeRTOS Includes
/////////////////////////////////////////

// FreeRTOS Base
#include "FreeRTOS.h"
#include "task.h"

// FreeRTOS+CLI Includes
#include "FreeRTOS_CLI.h"
#include "zybo_uart_driver.h"                  // Zybo UART Driver for FreeRTOS+CLI

// FreeRTOS+FAT includes
#include "ff_stdio.h"
#include "ff_ramdisk.h"
#include "ff_sddisk.h"
#include "fat_CLI_apps.h"

/////////////////////////////////////////
// PL Peripheral Includes
/////////////////////////////////////////
// Register maps
#include "codec_controller_control_regs.h"
#include "sampler_dma_controller_regs.h"

// CLI Applications
#include "codec_controller_CLI_apps.h"         // CLI Applications
#include "sampler_dma_controller_CLI_apps.h"   // CLI Applications

// Peripheral utilities
#include "codec_controller_utils.h"
#include "sampler_dma_voice_pb.h"

/////////////////////////////////////////
// Sampler Includes
/////////////////////////////////////////
// FreeRTOS Tasks
#include "sampler_FreeRTOS_tasks.h"

// FreeRTOS CLI Commands
#include "sampler_CLI_apps.h"

// Other
#include "nco.h"
#include "sampler_engine.h"

//////////////////////////////////////////
#define NUM_OF_SINE_SAMPLES               0x100000
#define DEBUG
//////////////////////////////////////////

// Static Functions
static void prv_vSystemInit( void );
static void prv_StartMainRTOSProgram( void );
static void prv_RegisterFreeRTOSTasks( void );
static void prv_RegisterFreeRTOSCLIApps( void );
// Global Variables
static audio_data_t output_stream_audio_data[ NUM_OF_SINE_SAMPLES ];
FF_Disk_t *pxSDDisk;
nco_t      sine_nco;

// Main application
int main() {
    // Start the RTOS program
    prv_StartMainRTOSProgram();
}

// Register all user tasks
void prv_RegisterFreeRTOSTasks() {
    // Sampler Engine
    vRegisterSamplerEngineTasks();
}

// Register all user CLI applications
void prv_RegisterFreeRTOSCLIApps() {
    vRegisterCODECCLICommands();
    vRegisterFATCLICommands();
    vRegisterSamplerCLICommands();
    vRegisterSamplerDMAControllerCLICommands();
}

// Launch FreeRTOS
void prv_StartMainRTOSProgram() {

    // Initialize the PL registers
    prv_vSystemInit();

    // Register all user tasks
    prv_RegisterFreeRTOSTasks();
    
    // Register all CLI applications
    prv_RegisterFreeRTOSCLIApps();

    // Start the UART Console
    vUARTCommandConsoleStart( mainUART_COMMAND_CONSOLE_STACK_SIZE, mainUART_COMMAND_CONSOLE_TASK_PRIORITY );

    // Initialize the SD card
    pxSDDisk = FF_SDDiskInit( mainSD_CARD_DISK_NAME );

    // Start FreeRTOS
    vTaskStartScheduler();

    while(1);
}

/////////////////////////////////
// System Initialization Task  //
/////////////////////////////////
void prv_vSystemInit( void ) {
    xil_printf("==========================\n\r");
    xil_printf("Initializing the system...\n\r");
    ////////
    // CODEC Configuration
    ////////
    xil_printf("Initializing the CODEC registers...\n\r");
    vCodecInit(0);
    xil_printf("Done!\n\r");

    xil_printf("Initializing the Sine NCO memory...\n\r");
    sine_nco.target_memory_size = NUM_OF_SINE_SAMPLES;
    sine_nco.audio_data = output_stream_audio_data;
    xil_printf("Audio Data Address Start = 0x%x\n\r", sine_nco.audio_data);
    xil_printf("Done!\n\r");    

    vSamplerDMAInit();

    xil_printf("Done!\n\r");
    xil_printf("==========================\n\r");

}
