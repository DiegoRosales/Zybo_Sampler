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

// Sampler Includes
#include "sampler_FreeRTOS_tasks.h"
#include "sampler_cfg.h"
#include "patch_loader.h"
#include "sampler_engine.h"

///////////////////////////////////////
// Defines
///////////////////////////////////////
#ifndef RUN_MIDI_CMD_TASK_NAME
    #define TASK_NAME "run_midi_cmd"
#else
    #define TASK_NAME RUN_MIDI_CMD_TASK_NAME
#endif

///////////////////////////////////////
// Static Functions
///////////////////////////////////////
static void prv_vRunMIDICommandTask( void *pvParameters );


///////////////////////////////////////
// Misc. Variables
///////////////////////////////////////
extern PATCH_DESCRIPTOR_t *patch_descriptor;


///////////////////////////////////////
// Function to register the command
///////////////////////////////////////
void vRegisterRunMIDICommandTask( ) {

    // Create the task
    xTaskCreate(
                    prv_vRunMIDICommandTask,           /* Function that implements the task. */
                    TASK_NAME,                         /* Text name for the task. */
                    0x2000,                            /* Stack size in words, not bytes. */
                    ( void * ) patch_descriptor,       /* Parameter passed into the task. */
                    configMAX_PRIORITIES,              /* Priority at which the task is created. */
                    NULL );                            /* Used to pass out the created task's handle. */
}

///////////////////////////////////////
// Actual Task Implementation
///////////////////////////////////////

static void prv_vRunMIDICommandTask( void *pvParameters ) {
    BaseType_t        notification_received;
    uint32_t          ulNotifiedValue;

    // MIDI Variables
    uint32_t full_command = 0;
    uint8_t  cmd          = 0;
    uint8_t  byte1        = 0;
    uint8_t  byte2        = 0;

    for( ;; )
    {
        get_midi_cmd_notification:
        // Bits in this RTOS task's notification value are set by the notifying
        // tasks and interrupts to indicate which events have occurred. */
        notification_received = xTaskNotifyWait( 0x00,             /* Don't clear any notification bits on entry. */
                                   0xffffffff,       /* Reset the notification value to 0 on exit. */
                                   &ulNotifiedValue, /* Notified value pass out in ulNotifiedValue. */
                                   portMAX_DELAY );  /* Block indefinitely. */

        if ( notification_received == pdFALSE ) goto get_midi_cmd_notification;

        if ( ulNotifiedValue == 0 ) goto get_midi_cmd_notification;

        full_command = ( uint32_t ) ulNotifiedValue;
        cmd   =   full_command         & 0xff;
        byte1 = ( full_command >> 8  ) & 0xff;
        byte2 = ( full_command >> 16 ) & 0xff;

        // Check which command is
        switch ( cmd & 0xF0 )
        {
            // Note OFF
            case 0x80:
                ulPlayInstrumentKey( byte1, 0, patch_descriptor );
                break;

            // Note ON
            case 0x90:
                ulPlayInstrumentKey( byte1, byte2, patch_descriptor );
                break;

            default:
                break;
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
