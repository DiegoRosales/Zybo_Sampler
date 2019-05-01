
// C includes
#include <string.h>

// FreeRTOS Includes
#include "FreeRTOS.h"
#include "task.h"
#include "semphr.h"
#include "queue.h"
#include "FreeRTOS_CLI.h"

// FreeRTOS+FAT includes
#include "ff_stdio.h"
#include "ff_ramdisk.h"
#include "ff_sddisk.h"

// Sampler Includes
#include "sampler_CLI_apps.h"
#include "sampler_FreeRTOS_tasks.h"
#include "sampler.h"


//extern instrument_information;

static xQueueHandle my_filename_queue_handler;
static xQueueHandle my_return_queue_handler;

static xQueueHandle my_key_parameters_queue_handler;

// This function converts an string in int or hex to a uint32_t
static uint32_t str2int( char *input_string, BaseType_t input_string_length ) {

    char *start_char = input_string;
    char *end_char;
    uint32_t output_int;

    // Check if hex by identifying the '0x'
    if( strncmp( start_char, (const char *) "0x", 2 ) == 0 ) {
        start_char += 2; // Go forward 2 characters
        output_int = (uint32_t)strtoul(start_char, &end_char, 16);
    } else {
        output_int = (uint32_t)strtoul(start_char, &end_char, 10);
    }

    return output_int;

}

// Structure defining the key playback command
static const CLI_Command_Definition_t play_key_command_definition =
{
    "play_key", /* The command string to type. */
    "\r\nplay_key <key> <velocity>:\r\n Starts the key playback\n\r",
    play_key_command, /* The function to run. */
    2 /* One parameter is expected. */
};

// Structure defining the instrument loader command
static const CLI_Command_Definition_t test_notification_definition =
{
    "test_notif", /* The command string to type. */
    "\r\ntest_notification\r\n",
    test_notification, /* The function to run. */
    0 /* One parameter is expected. */
};

// Structure defining the instrument loader command
static const CLI_Command_Definition_t load_instrument_command_definition =
{
    "load_instrument", /* The command string to type. */
    "\r\nload_instrument <filename>:\r\n Loads the specified instrument\r\n",
    load_instrument_command, /* The function to run. */
    1 /* One parameter is expected. */
};

// This function registers all the CLI applications
void register_sampler_cli_commands( void ) {
    my_filename_queue_handler       = xQueueCreate(1, sizeof(file_path_t));
    my_return_queue_handler         = xQueueCreate(1, sizeof(uint32_t));
    my_key_parameters_queue_handler = xQueueCreate(1, sizeof(uint32_t));
    FreeRTOS_CLIRegisterCommand( &play_key_command_definition );
    FreeRTOS_CLIRegisterCommand( &load_instrument_command_definition );
    FreeRTOS_CLIRegisterCommand( &test_notification_definition );

}


static BaseType_t test_notification( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString ) {
    
    TaskHandle_t task_handle = xTaskGetHandle( "notification_test_task" );
    uint32_t     return_value = 1;
    file_path_t  my_file_path = {"Hello", my_return_queue_handler};

    xQueueSend(my_filename_queue_handler, &my_file_path , 1000);

    xTaskNotify(    task_handle,
                    my_filename_queue_handler,
                    eSetValueWithOverwrite );

    if( ! xQueueReceive(my_return_queue_handler, &return_value, 10000) ) {
        xil_printf("Error receiving the Queue!\n\r");
    }
    else {
        xil_printf("Done! Return Value = %d\n\r", return_value);
    }

    return pdFALSE;

}

static BaseType_t play_key_command( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString ) {

    const char *key;
    const char *velocity;

    BaseType_t xParameter1StringLength;
    BaseType_t xParameter2StringLength;

    // Variables for the key playback task
    TaskHandle_t     key_playback_task_hanle = xTaskGetHandle( KEY_PLAYBACK_TASK_NAME );
    key_parameters_t key_parameters;

    // First parameter
    key = FreeRTOS_CLIGetParameter
                    (
                        pcCommandString,		/* The command string itself. */
                        1,						/* Return the first parameter. */
                        &xParameter1StringLength	/* Store the parameter string length. */
                    );

    // Second Parameter
    velocity = FreeRTOS_CLIGetParameter
                    (
                        pcCommandString,		/* The command string itself. */
                        2,						/* Return the first parameter. */
                        &xParameter2StringLength	/* Store the parameter string length. */
                    );


    if ( ( xParameter1StringLength != 2 ) && ( xParameter1StringLength != 4 ) ) {
        xil_printf("[ERROR] - Incorrect key format.\n\rExample 1: f2\n\rExample 2: a5_s\n\r");
        return pdFALSE;
    }

    // Get the Key number and the velocity in uint8_t form
    key_parameters.key      = get_midi_note_number( key );
    key_parameters.velocity = str2int( velocity, xParameter2StringLength );

//    if( key_parameters.key == 0 || key_parameters.velocity == 0 ) {
//        xil_printf("[ERROR] - Bad key or velocity.\n\r");
//        return pdFALSE;
//    }

    xil_printf("Playing back Key %d, Velocity: %d", key_parameters.key, key_parameters.velocity);


    xQueueSend(my_key_parameters_queue_handler, &key_parameters , 1000);

    // Wake up the task and send the queue handler of the parameters
    xTaskNotify( key_playback_task_hanle,
                 my_key_parameters_queue_handler,
                 eSetValueWithOverwrite );

    // Don't wait for any feedback
    return pdFALSE;

}

static BaseType_t load_instrument_command( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString ) {
    
    const char *pcParameter;

    // Variables for the CLI Parameter Parser
    BaseType_t   xParameterStringLength;
    BaseType_t   xReturn = pdTRUE;

    // Variables for the instrument loader task
    TaskHandle_t task_handle = xTaskGetHandle( LOAD_INSTRUMENT_TASK_NAME );
    file_path_t  my_file_path;
    uint32_t     return_value = 1;
    uint32_t     cwd_path_len = 0;

    /* The file has not been opened yet.  Find the file name. */
    pcParameter = FreeRTOS_CLIGetParameter
                    (
                        pcCommandString,		/* The command string itself. */
                        1,						/* Return the first parameter. */
                        &xParameterStringLength	/* Store the parameter string length. */
                    );

    /* Sanity check something was returned. */
    configASSERT( pcParameter );

    configASSERT( ! (xParameterStringLength > MAX_PATH_LEN) );

    // Initialize the path
    memset( my_file_path.file_path, 0x00, MAX_PATH_LEN );
    memset( my_file_path.file_dir, 0x00, MAX_PATH_LEN );
    // Copy the Path
    if ( pcParameter[0] != '/' ) {
        // 1 - Get the current directory
        ff_getcwd( my_file_path.file_dir, MAX_PATH_LEN );
        xil_printf( "CWD: %s\n\r", my_file_path.file_dir);

        // 2 - Assemble the full path
        cwd_path_len = strlen( my_file_path.file_dir );
        configASSERT( ! ( (cwd_path_len + xParameterStringLength + 1) > MAX_PATH_LEN) );
        strncat( my_file_path.file_path, my_file_path.file_dir, cwd_path_len);
        strncat( my_file_path.file_path, "/", 1);
        strncat( my_file_path.file_path, pcParameter, xParameterStringLength );
    } else {
        sprintf(my_file_path.file_path, "%s", pcParameter);
    }

    //memcpy( &my_file_path.file_path, pcParameter, xParameterStringLength );
    my_file_path.return_handle = my_return_queue_handler;

    // Send the filename to the task
    xQueueSend(my_filename_queue_handler, &my_file_path , 1000);

    xTaskNotify(    task_handle,
                    my_filename_queue_handler,
                    eSetValueWithOverwrite );

    if( ! xQueueReceive(my_return_queue_handler, &return_value, 10000) ) {
        xil_printf("Error receiving the Queue!\n\r");
    }
    else {
        xil_printf("Done! Return Value = %d\n\r", return_value);
    }

    return pdFALSE;

}

//static BaseType_t load_instrument_command( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString )
//{
//    const char *pcParameter;
//    BaseType_t xParameterStringLength, xReturn = pdTRUE;
//    static FF_FILE *pxFile = NULL;
//    int iChar;
//    size_t xByte;
//    size_t xColumns = 50U;
//    size_t file_size = 0;
//
//    
//
//    /* Ensure there is always a null terminator after each character written. */
//    memset( pcWriteBuffer, 0x00, xWriteBufferLen );
//
//    // Clear the buffer
//    memset( instrument_info_buffer, 0x00, MAX_INST_FILE_SIZE );
//
//    /* Ensure the buffer leaves space for the \r\n. */
//    configASSERT( xWriteBufferLen > ( strlen( cliNEW_LINE ) * 2 ) );
//    xWriteBufferLen -= strlen( cliNEW_LINE );
//    xColumns = xWriteBufferLen - 1;
//
//    // Step 1 - Open the json file containing the instrument information
//    if( pxFile == NULL )
//    {
//        /* The file has not been opened yet.  Find the file name. */
//        pcParameter = FreeRTOS_CLIGetParameter
//                        (
//                            pcCommandString,		/* The command string itself. */
//                            1,						/* Return the first parameter. */
//                            &xParameterStringLength	/* Store the parameter string length. */
//                        );
//
//        /* Sanity check something was returned. */
//        configASSERT( pcParameter );
//
//        /* Attempt to open the requested file. */
//        pxFile = ff_fopen( pcParameter, "r" );
//
//        // Get the size of the file
//        file_size = ff_filelength( pxFile );
//
//        // If the file is too big, give an error
//        if ( file_size > MAX_INST_FILE_SIZE ) {
//            sprintf( pcWriteBuffer, "[ERROR] - Instrument information file is too large. File = %d bytes | max supported = %d bytes", file_size, MAX_INST_FILE_SIZE );
//            strcat( pcWriteBuffer, cliNEW_LINE );
//            xReturn = pdFALSE;
//            return xReturn;
//        }
//    }
//
//    // Step 2 - Load the file into memory
//    if( pxFile != NULL )
//    {
//        /* Read the next chunk of data from the file. */
//        for( xByte = 0; xByte < MAX_INST_FILE_SIZE; xByte++ )
//        {
//            iChar = ff_fgetc( pxFile );
//
//            if( iChar == -1 )
//            {
//                /* No more characters to return. */
//                ff_fclose( pxFile );
//                pxFile = NULL;
//                break;
//            }
//            else
//            {
//                instrument_info_buffer[ xByte ] = ( uint8_t ) iChar;
//            }
//        }
//    }
//
//    // Step 3 - Initialize the instrument information
//    if ( instrument_information == NULL ){
//        instrument_information = init_instrument_information(88, 1);
//        if ( instrument_information == NULL ){
//            xReturn = pdFALSE;
//            return xReturn;
//        }
//    }
//    // Step 4 - Decode the JSON file
//    decode_instrument_information( &instrument_info_buffer, &instrument_information);
//
//    if( pxFile == NULL )
//    {
//        /* Either the file was not opened, or all the data from the file has
//        been returned and the file is now closed. */
//        xReturn = pdFALSE;
//    }
//
//    strcat( pcWriteBuffer, cliNEW_LINE );
//
//    return xReturn;
//
//}
