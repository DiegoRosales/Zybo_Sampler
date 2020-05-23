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

///////////////////////////////////////
// Defines
///////////////////////////////////////
#ifndef PRINT_SF2_INFO_TASK_NAME
    #define TASK_NAME "print_sf2_info"
#else
    #define TASK_NAME PRINT_SF2_INFO_TASK_NAME
#endif

///////////////////////////////////////
// Static Functions
///////////////////////////////////////
static void prv_vPrintSF2InfoTask( void *pvParameters );


///////////////////////////////////////
// Misc. Variables
///////////////////////////////////////
extern PATCH_DESCRIPTOR_t *patch_descriptor;


///////////////////////////////////////
// Function to register the command
///////////////////////////////////////
void vRegisterPrintSF2InfoTask( ) {

    // Create the task
    xTaskCreate(
                    prv_vPrintSF2InfoTask,             /* Function that implements the task. */
                    TASK_NAME,                         /* Text name for the task. */
                    0x2000,                            /* Stack size in words, not bytes. */
                    ( void * ) patch_descriptor,       /* Parameter passed into the task. */
                    tskIDLE_PRIORITY,                  /* Priority at which the task is created. */
                    NULL );                            /* Used to pass out the created task's handle. */

}

///////////////////////////////////////
// Actual Task Implementation
///////////////////////////////////////

// This task loads an SF2 patch and prints its information
static void prv_vPrintSF2InfoTask( void *pvParameters ) {
    BaseType_t          notification_received;
    const TickType_t    xBlockTime = 500;
    uint32_t            ulNotifiedValue;
    file_path_handler_t *path_handler = malloc( sizeof( file_path_t ) );
    uint32_t            return_value = 1;

    for( ;; )
    {
        // Bits in this RTOS task's notification value are set by the notifying
        // tasks and interrupts to indicate which events have occurred. */
        notification_received = xTaskNotifyWait( 0x00,             /* Don't clear any notification bits on entry. */
                                   0xffffffff,       /* Reset the notification value to 0 on exit. */
                                   &ulNotifiedValue, /* Notified value pass out in ulNotifiedValue. */
                                   portMAX_DELAY );  /* Block indefinitely. */

        if ( notification_received == pdTRUE ) {

            SAMPLER_PRINTF("Printing SF2 Info...\n\n\r");

            if( ! xQueueReceive((QueueHandle_t) ulNotifiedValue, path_handler, xBlockTime) ) {
                SAMPLER_PRINTF("Error receiving the Queue!\n\r");
            }
            else {
                return_value = 0;
                SAMPLER_PRINTF("Loading SF2 \"%s\"\n\r", path_handler->file_path);

                // Load the samples
                vPrintSF2FileInfo( path_handler->file_path );

                xQueueSend(path_handler->return_handle, &return_value, 1000);
            }

        }

    }

    /* Tasks must not attempt to return from their implementing
    function or otherwise exit.  In newer FreeRTOS port
    attempting to do so will result in an configASSERT() being
    called if it is defined.  If it is necessary for a task to
    exit then have the task call vTaskDelete( NULL ) to ensure
    its exit is clean. */
    vTaskDelete( NULL );
}
