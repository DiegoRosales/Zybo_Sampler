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
//#include "fat_CLI_apps.h"

// Sampler Includes
#include "sampler_FreeRTOS_tasks.h"
#include "sampler.h"

static INSTRUMENT_INFORMATION_t *instrument_information = NULL;
static uint8_t                   instrument_info_buffer[MAX_INST_FILE_SIZE];

uint32_t load_samples_into_memory( INSTRUMENT_INFORMATION_t *instrument_information, char *json_file_root_dir ) {

    // Initialize the variables
    uint32_t key        = 0;
    uint32_t vel_range  = 0;    
    uint32_t file_size  = 0;
    //size_t   total_size = 0;
    //size_t   total_keys = 0;
    char     full_path[MAX_PATH_LEN]; // Path to the sample

    instrument_information->total_size = 0;
    instrument_information->total_keys = 0;

    KEY_INFORMATION_t       *current_key;
    KEY_VOICE_INFORMATION_t *current_voice;

    for (key = 0; key < MAX_NUM_OF_KEYS; key++) {

        current_key = instrument_information->key_information[key];

        if ( current_key != NULL ) {

            for (vel_range = 0; vel_range < 1; vel_range++) {

                current_voice = current_key->key_voice_information[vel_range];

                if ( current_voice != NULL ) {
                    if ( current_voice->sample_present != 0 ) {

                        // Copy the full path
                        memset( full_path, 0x00, MAX_PATH_LEN );
                        strncat( full_path, json_file_root_dir, strlen( json_file_root_dir ));
                        strncat( full_path, "/", 1);
                        strncat( full_path, \
                                 current_voice->sample_path, \
                                 strlen(current_voice->sample_path) );

                        current_voice->sample_buffer = NULL;
                        xil_printf("[INFO] - [%d][%d]Loading Sample \"%s\"\n\r", key, vel_range, current_voice->sample_path );
                        file_size = load_file_to_memory_malloc( 
                                                                full_path,
                                                                &current_voice->sample_buffer,
                                                                (size_t) MAX_SAMPLE_SIZE,
                                                                sizeof(uint32_t) // Overhead to allow realignment
                                                                );
                        
                        current_voice->sample_size = file_size;
                        instrument_information->total_size += file_size;
                        instrument_information->total_keys++;
                        if ( current_voice->sample_buffer == NULL || file_size == 0 ) {
                            return 1;                          
                        }
                    }
                }
            }
        }
    }

    return 0;
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

    xTaskCreate(
                    key_playback_task,                 /* Function that implements the task. */
                    KEY_PLAYBACK_TASK_NAME,            /* Text name for the task. */
                    0x2000,                            /* Stack size in words, not bytes. */
                    ( void * ) instrument_information, /* Parameter passed into the task. */
                    tskIDLE_PRIORITY,                  /* Priority at which the task is created. */
                    NULL );                            /* Used to pass out the created task's handle. */                    
}

void notification_test_task( void *pvParameters ) {
    BaseType_t        notification_received;
    uint32_t          ulNotifiedValue;
    file_path_t       *path = malloc( sizeof( file_path_t ) );
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


// This task receives the notification to start playing a key
// The notification must also pass the value of a Queue Handler
// Once the notification is recieved, the task will receive the key parameters
// using the provided Queue handler
void key_playback_task( void *pvParameters ) {
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

            xil_printf("Starting key playback...\n\n\r");

            // Receive the key parameters from the CLI command
            if( ! xQueueReceive((QueueHandle_t) ulNotifiedValue, key_parameters, xBlockTime) ) {
                xil_printf("[ERROR] - Error receiving the Queue!\n\r");
                goto get_playback_notification;
            }

            if( key_parameters == NULL ){
                xil_printf("[ERROR] - The key parameters are NULL!\n\r");
                goto get_playback_notification;
            }

            // Start the playback
            error = play_instrument_key( key_parameters->key, key_parameters->velocity, instrument_information );

            if( error ) {
                xil_printf("[ERROR] - Failed playing the key\n\r");
            }

        }
    }
}

// This task loads the instrument using a .json file
// The .json file contains all the information regarding
// Key, velocity ranges, and associated sample
void load_instrument_task( void *pvParameters ) {
    BaseType_t        notification_received;
    const TickType_t  xBlockTime = 500;
    uint32_t          ulNotifiedValue;
    file_path_t       *path = malloc( sizeof( file_path_t ) );
    uint32_t          return_value = 1;

    // Variables for the sample loading
    uint32_t error      = 0;
    //uint32_t key        = 0;
    //uint32_t vel_range  = 0;
    //uint32_t total_keys = 0;
    //size_t   file_size  = 0;
    //size_t   total_size = 0;
    //char     full_path[MAX_PATH_LEN];

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

            if( ! xQueueReceive((QueueHandle_t) ulNotifiedValue, path, xBlockTime) ) {
                xil_printf("Error receiving the Queue!\n\r");
            }
            else {
                return_value = 0;
                xil_printf("Loading instrument \"%s\"\n\r", path->file_path);

                // Step 1 - Open the json file containing the instrument information
                xil_printf("Step 1 - Load the JSON File\n\r");
                load_file_to_memory( &path->file_path, instrument_info_buffer, (size_t) MAX_INST_FILE_SIZE );

                // Step 2 - Initialize the instrument information
                xil_printf("Step 2 - Initializing the instrument information\n\r");
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
                
                instrument_information->instrument_loaded = 0;

                xil_printf("Step 2 - Done!\n\r");

                // Step 3 - Decode the JSON file using JSMN
                xil_printf("Step 3 - Decoding the instrument information...\n\r");
                decode_instrument_information( &instrument_info_buffer, instrument_information);
                xil_printf("Step 3 - Done!\n\r");

                // Step 4 - Load all the samples into memory
                // Initialize the variables
//                file_size  = 0;
//                total_size = 0;
//                total_keys = 0;
                xil_printf("Step 4 - Loading samples into memory...\n\r");
                error = load_samples_into_memory( instrument_information, &path->file_dir );
                if ( error ) {
                    xil_printf("[ERROR] - There was a problem when loading the samples into memory!!\n\r");
                    return_value = 1;
                    xQueueSend(path->return_handle, &return_value, 1000);
                    goto get_notification;                                
                }                
//                for (key = 0; key < MAX_NUM_OF_KEYS; key++) {
//                    for (vel_range = 0; vel_range < 1; vel_range++) {
//                        if ( instrument_information->key_information[key]->key_voice_information[vel_range]->sample_present != 0 ) {
//
//                            // Copy the full path
//                            memset( full_path, 0x00, MAX_PATH_LEN );
//                            strncat( full_path, path->file_dir, strlen( path->file_dir ));
//                            strncat( full_path, "/", 1);
//                            strncat( full_path, \
//                                     instrument_information->key_information[key]->key_voice_information[vel_range]->sample_path, \
//                                     strlen(instrument_information->key_information[key]->key_voice_information[vel_range]->sample_path) );
//
//                            instrument_information->key_information[key]->key_voice_information[vel_range]->sample_buffer = NULL;
//                            xil_printf("[INFO] - [%d][%d]Loading Sample \"%s\"\n\r", key, vel_range, instrument_information->key_information[key]->key_voice_information[vel_range]->sample_path );
//                            file_size = load_file_to_memory_malloc( full_path, \
//                                                                    &instrument_information->key_information[key]->key_voice_information[vel_range]->sample_buffer, \
//                                                                    (size_t) MAX_SAMPLE_SIZE );
//                            
//                            instrument_information->key_information[key]->key_voice_information[vel_range]->sample_size = file_size;
//                            total_size += file_size;
//                            total_keys++;
//                            if ( instrument_information->key_information[key]->key_voice_information[vel_range]->sample_buffer == NULL || file_size == 0 ) {
//                                xil_printf("[ERROR] - There was a problem when loading the samples into memory!!\n\r");
//                                return_value = 1;
//                                xQueueSend(path->return_handle, &return_value, 1000);
//                                goto get_notification;                                
//                            }
//                        }
//                    }
//                }
                xil_printf("---\n\r");
                xil_printf("[INFO] - Loaded %d keys\n\r", instrument_information->total_keys);
                xil_printf("[INFO] - Total Memory Used = %d bytes\n\r", instrument_information->total_size);
                xil_printf("Step 4 - Done!\n\r");

                xil_printf("Step 5 - Populating the sampler data structures...\n\r");

                load_sample_information( instrument_information );
                instrument_information->instrument_loaded = 1;

                xil_printf("Step 5 - Done!\n\r");

                xil_printf("------------\n\r");
                xil_printf("Instrument Succesfully Loaded!\n\r");
                xil_printf("------------\n\r\n\r");

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
