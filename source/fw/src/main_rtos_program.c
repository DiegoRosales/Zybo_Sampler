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
    xil_printf("Initializing the system...\n\r");
    ////////
    // CODEC Configuration
    ////////
    CodecInit(0);

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

    for(int i=0; i<100; i++); // Small delay
}
