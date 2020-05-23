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
#ifndef KEY_PLAYBACK_TASK_NAME
    #define TASK_NAME "key_playback"
#else
    #define TASK_NAME KEY_PLAYBACK_TASK_NAME
#endif

///////////////////////////////////////
// Static Functions
///////////////////////////////////////
static void prv_vKeyPlaybackTask( void *pvParameters );


///////////////////////////////////////
// Misc. Variables
///////////////////////////////////////
extern PATCH_DESCRIPTOR_t *patch_descriptor;


///////////////////////////////////////
// Function to register the command
///////////////////////////////////////
void vRegisterKeyPlaybackTask( ) {

    // Create the task
    xTaskCreate(
                    prv_vKeyPlaybackTask,              /* Function that implements the task. */
                    TASK_NAME,                         /* Text name for the task. */
                    0x2000,                            /* Stack size in words, not bytes. */
                    ( void * ) patch_descriptor,       /* Parameter passed into the task. */
                    tskIDLE_PRIORITY,                  /* Priority at which the task is created. */
                    NULL );                            /* Used to pass out the created task's handle. */
}

///////////////////////////////////////
// Actual Task Implementation
///////////////////////////////////////

// This task receives the notification to start playing a key
// The notification must also pass the value of a Queue Handler
// Once the notification is recieved, the task will receive the key parameters
// using the provided Queue handler
static void prv_vKeyPlaybackTask( void *pvParameters ) {
    BaseType_t        notification_received;
    const TickType_t  xBlockTime = 500;
    uint32_t          ulNotifiedValue;
    key_parameters_t *key_parameters = malloc( sizeof( key_parameters_t ) );
    uint32_t          error = 0;

    for ( ;; ) {

        get_playback_notification:
        // We receive the Queue handler pointer in the notification value
        notification_received = xTaskNotifyWait( 0x00,  /* Don't clear any notification bits on entry. */
                                0xffffffff,             /* Reset the notification value to 0 on exit. */
                                &ulNotifiedValue,       /* Notified value pass out in ulNotifiedValue. */
                                portMAX_DELAY );        /* Block indefinitely. */

        if ( notification_received == pdTRUE ) {
            error = 0;

            SAMPLER_PRINTF("Starting key playback...\n\n\r");

            // Receive the key parameters from the CLI command
            if( ! xQueueReceive((QueueHandle_t) ulNotifiedValue, key_parameters, xBlockTime) ) {
                SAMPLER_PRINTF_ERROR("Error receiving the Queue!");
                goto get_playback_notification;
            }

            if( key_parameters == NULL ){
                SAMPLER_PRINTF_ERROR("The key parameters are NULL!");
                goto get_playback_notification;
            }

            // Start the playback
            error = ulPlayInstrumentKey( key_parameters->key, key_parameters->velocity, patch_descriptor );

            if( error ) {
                SAMPLER_PRINTF_ERROR("Failed playing the key");
            }

        }
    }
}
