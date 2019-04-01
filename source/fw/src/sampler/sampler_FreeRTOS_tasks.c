// C includes
#include <string.h>

// FreeRTOS Includes
#include "FreeRTOS.h"
#include "task.h"
#include "semphr.h"
#include "queue.h"

// FreeRTOS+FAT includes
#include "ff_stdio.h"
#include "ff_ramdisk.h"
#include "ff_sddisk.h"

// Sampler Includes
#include "sampler_FreeRTOS_tasks.h"
#include "sampler.h"

static INSTRUMENT_INFORMATION_t *instrument_information = NULL;
static uint8_t                   instrument_info_buffer[MAX_INST_FILE_SIZE];

void create_sampler_tasks ( void ) {

    // Initializes the instrument information data structure
    //instrument_information = init_instrument_information(88, 1);
    
    /* Create the task, storing the handle. */
    xTaskCreate(
                    notification_test_task,              /* Function that implements the task. */
                    "notification_test_task",            /* Text name for the task. */
                    0x2000,                            /* Stack size in words, not bytes. */
                    ( void * ) instrument_information, /* Parameter passed into the task. */
                    tskIDLE_PRIORITY,                  /* Priority at which the task is created. */
                    NULL );                            /* Used to pass out the created task's handle. */

    /* Create the task, storing the handle. */
    xTaskCreate(
                    load_instrument_task,                   /* Function that implements the task. */
                    LOAD_INSTRUMENT_TASK_NAME,         /* Text name for the task. */
                    0x2000,                            /* Stack size in words, not bytes. */
                    ( void * ) instrument_information, /* Parameter passed into the task. */
                    tskIDLE_PRIORITY,                  /* Priority at which the task is created. */
                    NULL );                            /* Used to pass out the created task's handle. */                    
}

void notification_test_task( void *pvParameters ) {
    BaseType_t        notification_received;
    const TickType_t  xBlockTime = 500;
    uint32_t          ulNotifiedValue;
    file_path_t       *path;
    uint32_t          return_value = 1;

    for( ;; )
    {
        // Bits in this RTOS task's notification value are set by the notifying
        // tasks and interrupts to indicate which events have occurred. */
        notification_received = xTaskNotifyWait( 0x00,             /* Don't clear any notification bits on entry. */
                                   0xffffffff,       /* Reset the notification value to 0 on exit. */
                                   &ulNotifiedValue, /* Notified value pass out in ulNotifiedValue. */
                                   portMAX_DELAY );  /* Block indefinitely. */

        if ( notification_received == pdTRUE ) {

            xil_printf("I have been notified!! Notification Value = %d\n\r", ulNotifiedValue);

            if( ! xQueueReceive((QueueHandle_t) ulNotifiedValue, path, 1000) ) {
                xil_printf("Error receiving the Queue!\n\r");
            }
            else {
                return_value = 0;
                xil_printf("%s\n\r", path->file_path);
                xQueueSend(path->return_handle, &return_value, 1000);
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
 


void load_instrument_task( void *pvParameters ) {
    BaseType_t        notification_received;
    const TickType_t  xBlockTime = 500;
    uint32_t          ulNotifiedValue;
    file_path_t       *path;
    uint32_t          return_value = 1;

    size_t file_size;
    size_t xByte;
    int    iChar;
    FF_FILE *pxFile = NULL;

    for( ;; )
    {
        get_notification: 
        // Bits in this RTOS task's notification value are set by the notifying
        // tasks and interrupts to indicate which events have occurred. */
        notification_received = xTaskNotifyWait( 0x00,             /* Don't clear any notification bits on entry. */
                                   0xffffffff,       /* Reset the notification value to 0 on exit. */
                                   &ulNotifiedValue, /* Notified value pass out in ulNotifiedValue. */
                                   portMAX_DELAY );  /* Block indefinitely. */

        if ( notification_received == pdTRUE ) {

            xil_printf("Starting instrument loader...\n\n\r");

            if( ! xQueueReceive((QueueHandle_t) ulNotifiedValue, path, 1000) ) {
                xil_printf("Error receiving the Queue!\n\r");
            }
            else {
                return_value = 0;
                xil_printf("Loading instrument \"%s\"\n\r", path->file_path);

                // Step 1 - Open the json file containing the instrument information
                xil_printf("Step 1 - Open the JSON File\n\r");
                pxFile = ff_fopen( &path->file_path, "r" );

                // Throw an error if the file cannot be opened
                if ( pxFile == NULL ) {
                    xil_printf("[ERROR] - File %s could not be opened!\n\r", path->file_path);
                    return_value = 1;
                    xQueueSend(path->return_handle, &return_value, 1000);
                    goto get_notification;                    
                }

                // Get the size of the file
                file_size = ff_filelength( pxFile );

                // If the file is too big, give an error
                if ( file_size > MAX_INST_FILE_SIZE ) {
                    xil_printf( "[ERROR] - Instrument information file is too large. File = %d bytes | max supported = %d bytes", file_size, MAX_INST_FILE_SIZE );
                    xil_printf( cliNEW_LINE );
                    return_value = 1;
                    xQueueSend(path->return_handle, &return_value, 1000);
                    goto get_notification;
                }

                xil_printf("Step 1 - Done! - File Size = %d\n\r", file_size);

                // Step 2 - Load the JSON file into memory
                xil_printf("Step 2 - Load the JSON file into memory\n\r");
                memset( instrument_info_buffer, 0x00, MAX_INST_FILE_SIZE );
                /* Read the next chunk of data from the file. */
                for( xByte = 0; xByte < MAX_INST_FILE_SIZE; xByte++ )
                {
                    iChar = ff_fgetc( pxFile ); // Get byte

                    if( iChar == -1 )
                    {
                        /* No more characters to return. */
                        ff_fclose( pxFile );
                        pxFile = NULL;
                        break;
                    }
                    else
                    {
                        instrument_info_buffer[ xByte ] = ( uint8_t ) iChar;
                    }
                }

                xil_printf("Step 2 - Done!\n\r");

                // Step 3 - Initialize the instrument information
                xil_printf("Step 3 - Initializing the instrument information\n\r");
                if ( instrument_information == NULL ){
                    instrument_information = init_instrument_information(88, 1);

                    // Check if the initialization succeeded
                    if ( instrument_information == NULL ){
                        xil_printf("[ERROR] - Instrument information could not be initialized!!\n\r");
                        return_value = 1;
                        xQueueSend(path->return_handle, &return_value, 1000);
                        goto get_notification;
                    }
                } else {
                    xil_printf("[INFO] - Instrument information was already initialized at 0x%x\n\r", instrument_information);
                }

                xil_printf("Step 3 - Done!\n\r");


                xQueueSend(path->return_handle, &return_value, 1000);
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
