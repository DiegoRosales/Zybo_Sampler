///////////////////////////////////////////////
// This is the main file that will be called //
// at the start                              //
///////////////////////////////////////////////

#include "main_rtos_program.h"

// Xilinx Includes
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
// Sampler Includes
/////////////////////////////////////////
// Register maps
#include "codec_controller_control_regs.h"
#include "sampler_dma_controller_regs.h"

// CLI Applications
#include "codec_controller_CLI_apps.h"         // CLI Applications
#include "sampler_dma_controller_CLI_apps.h"   // CLI Applications

// FreeRTOS Tasks
#include "sampler_FreeRTOS_tasks.h"

// Other
#include "codec_controller_utils.h"
#include "nco.h"
#include "sampler.h"

#define NUM_OF_SINE_SAMPLES 0x100000

nco_t sine_nco;
static volatile audio_data_t output_stream_audio_data[ NUM_OF_SINE_SAMPLES ];
FF_Disk_t *pxSDDisk;
//INSTRUMENT_INFORMATION_t *instrument_information = NULL;

void main_rtos_program() {

    system_init();

    create_sampler_tasks();
    
    vUARTCommandConsoleStart( mainUART_COMMAND_CONSOLE_STACK_SIZE, mainUART_COMMAND_CONSOLE_TASK_PRIORITY );

    register_codec_cli_commands();
    register_fat_cli_commands();
    register_sampler_cli_commands();
    register_sampler_dma_ctrl_cli_commands();

    pxSDDisk = FF_SDDiskInit( mainSD_CARD_DISK_NAME );

    vTaskStartScheduler();


    while(1);
}




/////////////////////////////////
// System Initialization Task  //
/////////////////////////////////
void system_init( void ) {
    xil_printf("==========================\n\r");
    xil_printf("Initializing the system...\n\r");
    ////////
    // CODEC Configuration
    ////////
    xil_printf("Initializing the CODEC registers...\n\r");
    CodecInit(0);
    xil_printf("Done!\n\r");

    xil_printf("Initializing the Sine NCO memory...\n\r");
    sine_nco.target_memory_size = NUM_OF_SINE_SAMPLES;
    sine_nco.audio_data = &output_stream_audio_data;
    xil_printf("Audio Data Address Start = 0x%x\n\r", sine_nco.audio_data);
    xil_printf("Done!\n\r");    

    sampler_init();

    xil_printf("Done!\n\r");
    xil_printf("==========================\n\r");

}


