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
#ifndef STOP_ALL_TASK_NAME
    #define TASK_NAME "stop_all"
#else
    #define TASK_NAME STOP_ALL_TASK_NAME
#endif

///////////////////////////////////////
// Static Functions
///////////////////////////////////////
static void prv_vStopAllPlaybackTask( void *pvParameters );


///////////////////////////////////////
// Misc. Variables
///////////////////////////////////////
extern PATCH_DESCRIPTOR_t *patch_descriptor;


///////////////////////////////////////
// Function to register the command
///////////////////////////////////////
void vRegisterStopAllPlaybackTask( ) {

    // Create the task
    xTaskCreate(
                    prv_vStopAllPlaybackTask,          /* Function that implements the task. */
                    TASK_NAME,                         /* Text name for the task. */
                    0x2000,                            /* Stack size in words, not bytes. */
                    ( void * ) patch_descriptor,       /* Parameter passed into the task. */
                    tskIDLE_PRIORITY,                  /* Priority at which the task is created. */
                    NULL );                            /* Used to pass out the created task's handle. */
}

///////////////////////////////////////
// Actual Task Implementation
///////////////////////////////////////

// This task stops all playback
static void prv_vStopAllPlaybackTask( void *pvParameters ) {
    BaseType_t        notification_received;
    uint32_t          ulNotifiedValue;
    uint32_t          error = 0;

    for ( ;; ) {

        // We receive the Queue handler pointer in the notification value
        notification_received = xTaskNotifyWait( 0x00,  /* Don't clear any notification bits on entry. */
                                0xffffffff,             /* Reset the notification value to 0 on exit. */
                                &ulNotifiedValue,       /* Notified value pass out in ulNotifiedValue. */
                                portMAX_DELAY );        /* Block indefinitely. */

        if ( notification_received == pdTRUE ) {
            error = 0;

            SAMPLER_PRINTF("Stopping everything...\n\n\r");

            // Start the playback
            error = ulStopAllPlayback( patch_descriptor );

            if( error ) {
                SAMPLER_PRINTF_ERROR("Failed stopping everything");
            }

        }
    }
}
