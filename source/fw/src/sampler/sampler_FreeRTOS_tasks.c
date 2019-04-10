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


void file_to_buffer( FF_FILE *pxFile, uint8_t *buffer, uint32_t buffer_len ) {
    size_t xByte;
    int    iChar;


    xil_printf("[INFO] - Loading the file into memory\n\r");
    memset( buffer, 0x00, buffer_len );
    /* Read the next chunk of data from the file. */
//    for( xByte = 0; xByte < buffer_len; xByte++ )
//    {
//        iChar = ff_fgetc( pxFile ); // Get byte
//
//        if( iChar == -1 )
//        {
//            /* No more characters to return. */
//            ff_fclose( pxFile );
//            pxFile = NULL;
//            break;
//        }
//        else
//        {
//            buffer[ xByte ] = ( uint8_t ) iChar;
//        }
//    }
    ff_fread( buffer, buffer_len, 1, pxFile );
    Xil_DCacheFlushRange( buffer, buffer_len );
    xil_printf("[INFO] - File succesfully loaded into memory. Loaded %d bytes. Address = 0x%x\n\r", buffer_len, buffer);
}

// This functions loads a file into memory. You need to provide the full file path
uint32_t load_file_to_memory( char *file_name, uint8_t *buffer, uint32_t buffer_len ) {
    FF_FILE *pxFile = NULL;
    size_t file_size;

    // Step 0 - Check the inputs
    if ( buffer == NULL ) {
        xil_printf("[ERROR] - Pointer to the buffer is NULL! Enable do_malloc option to allocate a new pointer.\n\r");
        return 0;
    }

    // Step 1 - Open the file
    xil_printf("[INFO] - Opening the file: \"%s\"\n\r", file_name);
    pxFile = ff_fopen( file_name, "r" );

    // Throw an error if the file cannot be opened
    if ( pxFile == NULL ) {
        xil_printf("[ERROR] - File %s could not be opened!\n\r", file_name);
        return 0;
    }

    // Get the size of the file
    file_size = ff_filelength( pxFile );

    // If the file is too big, give an error
    if ( file_size > buffer_len ) {
        xil_printf( "[ERROR] - The File is too large. File = %d bytes | Buffer Size = %d bytes\n\r", file_size, buffer_len );
        xil_printf( cliNEW_LINE );
        return 0;
    }

    xil_printf("[INFO] - File opened succesfully. File Size = %d bytes\n\r", file_size);

    // Step 2 - Load the file into memory
    file_to_buffer( pxFile, buffer, buffer_len );

    return file_size;
}

// This functions loads a file into memory. You need to provide the full file path
// This function can perform a memory allocation in case the buffer is new
uint32_t load_file_to_memory_malloc( char *file_name, uint8_t *buffer, uint32_t buffer_len ) {
    FF_FILE *pxFile = NULL;
    size_t file_size;
    uint8_t *new_buffer;

    // Step 1 - Open the file
    xil_printf("[INFO] - Opening the file: \"%s\"\n\r", file_name);
    pxFile = ff_fopen( file_name, "r" );

    // Throw an error if the file cannot be opened
    if ( pxFile == NULL ) {
        xil_printf("[ERROR] - File %s could not be opened!\n\r", file_name);
        return 0;
    }

    // Get the size of the file
    file_size = ff_filelength( pxFile );

    // If the file is too big, give an error
    if ( file_size > buffer_len ) {
        xil_printf( "[ERROR] - The File is too large. File = %d bytes | Buffer Size = %d bytes\n\r", file_size, buffer_len );
        xil_printf( cliNEW_LINE );
        return 0;
    }

    xil_printf("[INFO] - File opened succesfully. File Size = %d bytes\n\r", file_size);

    // Perform memory allocation for the buffer
    xil_printf( "[INFO] - Performing memory allocation for the buffer. Requesting %d bytes\n\r", file_size );
    new_buffer = pvPortMalloc( file_size );
    //new_buffer = malloc( file_size );
    // Check if malloc was succesfull
    if ( new_buffer == NULL ) {
        xil_printf( "[ERROR] - Memory allocation failed. Requested %d bytes\n\r", file_size );
        return 0;
    } else {
        xil_printf( "[INFO] - Memory allocation was succesfull. Buffer address =  0x%x\n\r", new_buffer );
    }

    // Step 2 - Load the file into memory
    file_to_buffer( pxFile, new_buffer, buffer_len );

    *buffer = new_buffer;

    return file_size;
}

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
                xil_printf("Step 1 - Load the JSON File\n\r");
                load_file_to_memory( &path->file_path, instrument_info_buffer, MAX_INST_FILE_SIZE );

                // Step 3 - Initialize the instrument information
                xil_printf("Step 3 - Initializing the instrument information\n\r");
                if ( instrument_information == NULL ){
                    instrument_information = init_instrument_information(MAX_NUM_OF_KEYS, 1);

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

                // Step 4 - Decode the JSON file using JSMN
                xil_printf("Step 4 - Decoding the instrument information...\n\r");
                decode_instrument_information( &instrument_info_buffer, instrument_information);
                xil_printf("Step 4 - Done!\n\r");

                // Step 5 - Load all the samples into memory
                xil_printf("Step 5 - Loading samples into memory...\n\r");
                int key       = 0;
		        int vel_range = 0;
                char full_path[MAX_PATH_LEN];
                uint32_t file_size;
                for (key = 0; key < MAX_NUM_OF_KEYS; key++) {
                    for (vel_range = 0; vel_range < 1; vel_range++) {
                        if ( instrument_information->key_information[key]->key_voice_information[vel_range]->sample_present != 0 ) {

                            // Copy the full path
                            memset( full_path, 0x00, MAX_PATH_LEN );
                            strncat( full_path, path->file_dir, strlen( path->file_dir ));
                            strncat( full_path, "/", 1);
                            strncat( full_path, \
                                     instrument_information->key_information[key]->key_voice_information[vel_range]->sample_path, \
                                     strlen(instrument_information->key_information[key]->key_voice_information[vel_range]->sample_path) );

                            instrument_information->key_information[key]->key_voice_information[vel_range]->sample_buffer = NULL;
                            xil_printf("[INFO] - [%d][%d]Loading Sample \"%s\"\n\r", key, vel_range, instrument_information->key_information[key]->key_voice_information[vel_range]->sample_path );
                            file_size = load_file_to_memory_malloc( full_path, \
                                                                    &instrument_information->key_information[key]->key_voice_information[vel_range]->sample_buffer, \
                                                                    0x100000 );
                            
                            if ( instrument_information->key_information[key]->key_voice_information[vel_range]->sample_buffer == NULL || file_size == 0 ) {
                                xil_printf("[ERROR] - There was a problem when loading the samples into memory!!\n\r");
                                return_value = 1;
                                xQueueSend(path->return_handle, &return_value, 1000);
                                goto get_notification;                                
                            }
                        }
                    }
                }

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
