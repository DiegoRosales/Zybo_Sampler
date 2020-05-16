// C includes
#include <string.h>

/////////////////////////////////////////
// Xilinx Includes
/////////////////////////////////////////

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
#include "serial.h"

// Sampler Includes
#include "sampler_FreeRTOS_tasks.h"
#include "sampler_cfg.h"
#include "patch_loader.h"
#include "sampler_engine.h"

static PATCH_DESCRIPTOR_t *patch_descriptor = NULL;

// Task definitions
static void prv_vKeyPlaybackTask( void *pvParameters );
static void prv_vStopAllPlaybackTask( void *pvParameters );
static void prv_vLoadInstrumentTask( void *pvParameters );
static void prv_vLoadSF3Task( void *pvParameters );
static void prv_vRunMIDICommandTask( void *pvParameters );
static void prv_vSerialMIDIListenerTask( void *pvParameters );

void create_sampler_tasks ( void ) {

    /* Create the task, storing the handle. */
    xTaskCreate(
                    prv_vLoadInstrumentTask,           /* Function that implements the task. */
                    LOAD_INSTRUMENT_TASK_NAME,         /* Text name for the task. */
                    0x2000,                            /* Stack size in words, not bytes. */
                    ( void * ) patch_descriptor,       /* Parameter passed into the task. */
                    tskIDLE_PRIORITY,                  /* Priority at which the task is created. */
                    NULL );                            /* Used to pass out the created task's handle. */

    xTaskCreate(
                    prv_vLoadSF3Task,                  /* Function that implements the task. */
                    LOAD_SF3_TASK_NAME,                /* Text name for the task. */
                    0x2000,                            /* Stack size in words, not bytes. */
                    ( void * ) patch_descriptor,       /* Parameter passed into the task. */
                    tskIDLE_PRIORITY,                  /* Priority at which the task is created. */
                    NULL );                            /* Used to pass out the created task's handle. */

    xTaskCreate(
                    prv_vKeyPlaybackTask,              /* Function that implements the task. */
                    KEY_PLAYBACK_TASK_NAME,            /* Text name for the task. */
                    0x2000,                            /* Stack size in words, not bytes. */
                    ( void * ) patch_descriptor,       /* Parameter passed into the task. */
                    tskIDLE_PRIORITY,                  /* Priority at which the task is created. */
                    NULL );                            /* Used to pass out the created task's handle. */

    xTaskCreate(
                    prv_vStopAllPlaybackTask,          /* Function that implements the task. */
                    STOP_ALL_TASK_NAME,                /* Text name for the task. */
                    0x2000,                            /* Stack size in words, not bytes. */
                    ( void * ) patch_descriptor,       /* Parameter passed into the task. */
                    tskIDLE_PRIORITY,                  /* Priority at which the task is created. */
                    NULL );                            /* Used to pass out the created task's handle. */

    xTaskCreate(
                    prv_vRunMIDICommandTask,           /* Function that implements the task. */
                    RUN_MIDI_CMD_TASK_NAME,            /* Text name for the task. */
                    0x2000,                            /* Stack size in words, not bytes. */
                    ( void * ) patch_descriptor,       /* Parameter passed into the task. */
                    configMAX_PRIORITIES,              /* Priority at which the task is created. */
                    NULL );                            /* Used to pass out the created task's handle. */

    xTaskCreate(
                    prv_vSerialMIDIListenerTask,       /* Function that implements the task. */
                    SERIAL_MIDI_LISTENER_TASK_NAME,    /* Text name for the task. */
                    0x2000,                            /* Stack size in words, not bytes. */
                    ( void * ) patch_descriptor,       /* Parameter passed into the task. */
                    configMAX_PRIORITIES,              /* Priority at which the task is created. */
                    NULL );                            /* Used to pass out the created task's handle. */
}


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

// This task loads the instrument using a .json file
// The .json file contains all the information regarding
// Key, velocity ranges, and associated sample
static void prv_vLoadInstrumentTask( void *pvParameters ) {
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

            SAMPLER_PRINTF("Starting instrument loader...\n\n\r");

            if( ! xQueueReceive((QueueHandle_t) ulNotifiedValue, path_handler, xBlockTime) ) {
                SAMPLER_PRINTF("Error receiving the Queue!\n\r");
            }
            else {
                return_value = 0;
                SAMPLER_PRINTF("Loading instrument \"%s\"\n\r", path_handler->file_path);

                // Load the samples
                patch_descriptor = ulLoadPatchFromJSON( path_handler->file_dir, path_handler->file_path );

                if (patch_descriptor == NULL) {
                    SAMPLER_PRINTF_ERROR("Patch Loader returned patch_descriptor == NULL (0x%x)", patch_descriptor );
                    return_value = 1;
                }

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

// This task loads the instrument using a .json file
// The .json file contains all the information regarding
// Key, velocity ranges, and associated sample
static void prv_vLoadSF3Task( void *pvParameters ) {
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

            SAMPLER_PRINTF("Starting SF3 loader...\n\n\r");

            if( ! xQueueReceive((QueueHandle_t) ulNotifiedValue, path_handler, xBlockTime) ) {
                SAMPLER_PRINTF("Error receiving the Queue!\n\r");
            }
            else {
                return_value = 0;
                SAMPLER_PRINTF("Loading SF3 \"%s\"\n\r", path_handler->file_path);

                // Load the samples
                patch_descriptor = ulLoadPatchFromSF3( path_handler->file_path );

                if (patch_descriptor == NULL) {
                    SAMPLER_PRINTF_ERROR("Patch Loader returned patch_descriptor == NULL (0x%x)", patch_descriptor );
                    return_value = 1;
                }

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
