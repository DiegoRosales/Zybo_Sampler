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

// FreeRTOS Includes
#include "FreeRTOS.h"
#include "task.h"
#include "FreeRTOS_CLI.h"

// Zybo UART Driver for FreeRTOS+CLI
#include "zybo_uart_driver.h"

// CLI Applications
#include "codec_CLI_apps.h"

// Other
#include "codec_utils.h"
#include "nco.h"

#define NUM_OF_SINE_SAMPLES 0x100000

nco_t sine_nco;
static volatile audio_data_t output_stream_audio_data[ NUM_OF_SINE_SAMPLES ];

void main_rtos_program() {

    sampler_init();

    vUARTCommandConsoleStart( mainUART_COMMAND_CONSOLE_STACK_SIZE, mainUART_COMMAND_CONSOLE_TASK_PRIORITY );

    register_codec_cli_commands();

    vTaskStartScheduler();


    while(1);
}




/////////////////////////////////
// System Initialization Task  //
/////////////////////////////////
void sampler_init( void ) {
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
    xil_printf("Audio Data Address Start = 0x%x", sine_nco.audio_data);
    xil_printf("Done!\n\r");    

//    ////////
//    // GPIO Configuration
//    ////////
//    xil_printf("Initializing the GPIO...\n\r");
//    // Initialize the GPIO IP
//    XGpio_Initialize(&gpio, 0);
//    // Enable the GPIO Interrupts
//    enable_gpio_interrupts();
//    XGpio_InterruptClear(&gpio, 0xffffffff);
//    XGpio_InterruptEnable(&gpio, 0xffffffff);
//    XGpio_InterruptGlobalEnable(&gpio);
//
//    ////////
//    // DMA Configuration
//    ////////
//    xil_printf("Initializing the DMA Engine...\n\r");
    xil_printf("Done!\n\r");
    xil_printf("==========================\n\r");
    for(int i=0; i<100000; i++); // Small delay
}
