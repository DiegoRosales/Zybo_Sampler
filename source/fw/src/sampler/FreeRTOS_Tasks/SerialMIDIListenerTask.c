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
#ifndef SERIAL_MIDI_LISTENER_TASK_TASK_NAME
    #define TASK_NAME "serial_midi_listener_task"
#else
    #define TASK_NAME SERIAL_MIDI_LISTENER_TASK_TASK_NAME
#endif

///////////////////////////////////////
// Static Functions
///////////////////////////////////////
static void prv_vSerialMIDIListenerTask( void *pvParameters );


///////////////////////////////////////
// Misc. Variables
///////////////////////////////////////
extern PATCH_DESCRIPTOR_t *patch_descriptor;


///////////////////////////////////////
// Function to register the command
///////////////////////////////////////
void vRegisterSerialMIDIListenerTask( ) {

    // Create the task
    xTaskCreate(
                    prv_vSerialMIDIListenerTask,       /* Function that implements the task. */
                    TASK_NAME,                         /* Text name for the task. */
                    0x2000,                            /* Stack size in words, not bytes. */
                    ( void * ) patch_descriptor,       /* Parameter passed into the task. */
                    configMAX_PRIORITIES,              /* Priority at which the task is created. */
                    NULL );                            /* Used to pass out the created task's handle. */
}

///////////////////////////////////////
// Actual Task Implementation
///////////////////////////////////////

static void prv_vSerialMIDIListenerTask( void *pvParameters ) {
    BaseType_t        notification_received;
    uint32_t          ulNotifiedValue;
    uint32_t          return_value;
    QueueHandle_t     return_queue_handler;

    // Task Variables
    BaseType_t        midi_listener_stop;
    signed char       cRxedChar;
    uint32_t          index;

    // MIDI Variables
    uint8_t  bytes_rcvd[3];

    for( ;; )
    {
        wait_for_notification:
        // Bits in this RTOS task's notification value are set by the notifying
        // tasks and interrupts to indicate which events have occurred. */
        notification_received = xTaskNotifyWait( 0x00,             /* Don't clear any notification bits on entry. */
                                   0xffffffff,       /* Reset the notification value to 0 on exit. */
                                   &ulNotifiedValue, /* Notified value pass out in ulNotifiedValue. */
                                   portMAX_DELAY );  /* Block indefinitely. */

        if ( notification_received == pdFALSE ) goto wait_for_notification;

        // Initialize everything
        return_queue_handler = (QueueHandle_t) ulNotifiedValue;
        midi_listener_stop   = pdFALSE;
        index                = 0;
        return_value         = 1;

        memset( &bytes_rcvd, 0x00, 3 );
        while( midi_listener_stop == pdFALSE ) {
            // TODO: Find a way to get the xPort instead of hardcoding it
            while( xSerialGetChar( ( xComPortHandle ) 0, &cRxedChar, portMAX_DELAY ) != pdPASS );

            bytes_rcvd[index] = (uint8_t) cRxedChar;
            index++;

            if( index == 3 ){
                // Check which command is
                switch ( bytes_rcvd[0] & 0xF0 )
                {
                    // Note OFF
                    case 0x80:
                        ulPlayInstrumentKey( bytes_rcvd[1], 0, patch_descriptor );
                        break;

                    // Note ON
                    case 0x90:
                        ulPlayInstrumentKey( bytes_rcvd[1], bytes_rcvd[2], patch_descriptor );
                        break;

                    case 0xb0:
                        midi_listener_stop = pdTRUE;
                        break;

                    default:
                        break;
                }

                index = 0;
            }

        }

        xQueueSend(return_queue_handler, &return_value, 1000);

    }

    /* Tasks must not attempt to return from their implementing
    function or otherwise exit.  In newer FreeRTOS port
    attempting to do so will result in an configASSERT() being
    called if it is defined.  If it is necessary for a task to
    exit then have the task call vTaskDelete( NULL ) to ensure
    its exit is clean. */

    vTaskDelete( NULL );
}
