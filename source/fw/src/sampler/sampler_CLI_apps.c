
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
static const CLI_Command_Definition_t midi_command_definition =
{
    "midi", /* The command string to type. */
    "\r\nmidi <COMMAND> <DATA_BYTE_1> <DATA_BYTE_2>:\r\n Executes a MIDI command. This is intended to use with a bridge since all the arguments are sent in raw binary, not ASCII\n\r",
    midi_command, /* The function to run. */
    -1 /* 2 - 3 parameters. */
};

// Structure defining the key playback command
static const CLI_Command_Definition_t midi_ascii_command_definition =
{
    "midi_ascii", /* The command string to type. */
    "\r\nmidi_ascii <COMMAND> <DATA_BYTE_1> <DATA_BYTE_2>:\r\n Executes a MIDI command\n\r",
    midi_ascii_command, /* The function to run. */
    -1 /* 2 - 3 parameters. */
};

// Structure defining the key playback command
static const CLI_Command_Definition_t play_key_command_definition =
{
    "play_key", /* The command string to type. */
    "\r\nplay_key <key> <velocity>:\r\n Starts the key playback\n\r",
    play_key_command, /* The function to run. */
    2 /* One parameter is expected. */
};

// Structure defining the playback stop command
static const CLI_Command_Definition_t stop_all_command_definition =
{
    "stop_all", /* The command string to type. */
    "\r\nstop_all <key> <velocity>:\r\n Stops all playback\n\r",
    stop_all_command, /* The function to run. */
    0 /* One parameter is expected. */
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

// Structure defining the instrument loader command
static const CLI_Command_Definition_t start_midi_listener_command_definition =
{
    "start_serial_midi_listener", /* The command string to type. */
    "\r\nstart_serial_midi_listener\n\r Starts the MIDI Serial listener\r\n",
    start_midi_listener_command, /* The function to run. */
    0 /* One parameter is expected. */
};

// This function registers all the CLI applications
void register_sampler_cli_commands( void ) {
    my_filename_queue_handler       = xQueueCreate(1, sizeof(file_path_t));
    my_return_queue_handler         = xQueueCreate(1, sizeof(uint32_t));
    my_key_parameters_queue_handler = xQueueCreate(1, sizeof(uint32_t));
    FreeRTOS_CLIRegisterCommand( &play_key_command_definition );
    FreeRTOS_CLIRegisterCommand( &stop_all_command_definition );
    FreeRTOS_CLIRegisterCommand( &load_instrument_command_definition );
    FreeRTOS_CLIRegisterCommand( &midi_command_definition );
    FreeRTOS_CLIRegisterCommand( &midi_ascii_command_definition );
    FreeRTOS_CLIRegisterCommand( &test_notification_definition );
    FreeRTOS_CLIRegisterCommand( &start_midi_listener_command_definition );

}

static BaseType_t midi_command( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString ) {

    const char *key;
    const char *velocity;

    uint8_t *command = NULL;
    uint8_t *byte1   = NULL;
    uint8_t *byte2   = NULL;

    uint32_t full_cmd = 0;

    BaseType_t xParameter1StringLength;
    BaseType_t xParameter2StringLength;

    // Variables for the key playback task
    TaskHandle_t     run_midi_cmd_task_handle = xTaskGetHandle( RUN_MIDI_CMD_TASK_NAME );
    key_parameters_t key_parameters;

    // First parameter
    command = FreeRTOS_CLIGetParameter
                    (
                        pcCommandString,		/* The command string itself. */
                        1,						/* Return the first parameter. */
                        &xParameter1StringLength	/* Store the parameter string length. */
                    );

    // Second Parameter
    byte1 = FreeRTOS_CLIGetParameter
                    (
                        pcCommandString,		/* The command string itself. */
                        2,						/* Return the first parameter. */
                        &xParameter2StringLength	/* Store the parameter string length. */
                    );

    // Second Parameter
    byte2 = FreeRTOS_CLIGetParameter
                    (
                        pcCommandString,		/* The command string itself. */
                        3,						/* Return the first parameter. */
                        &xParameter2StringLength	/* Store the parameter string length. */
                    );

    // We need at least 2 parameters
    if( command == NULL || byte1 == NULL ) return pdFALSE;

    full_cmd  = *command;
    full_cmd |= *byte1 << 8;
    if ( byte2 != NULL ) full_cmd |= *byte2 << 16;

    // Wake up the task and send the full MIDI command the parameters
    xTaskNotify( run_midi_cmd_task_handle,
                 full_cmd,
                 eSetValueWithOverwrite );

    // Don't wait for any feedback
    return pdFALSE;

}

static BaseType_t midi_ascii_command( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString ) {

    const char *key;
    const char *velocity;

    char *command = NULL;
    char *byte1   = NULL;
    char *byte2   = NULL;

    uint8_t command_int = 0;
    uint8_t byte1_int   = 0;
    uint8_t byte2_int   = 0;

    uint32_t full_cmd = 0;

    BaseType_t xParameter1StringLength;
    BaseType_t xParameter2StringLength;
    BaseType_t xParameter3StringLength;


    // Variables for the key playback task
    TaskHandle_t     run_midi_cmd_task_handle = xTaskGetHandle( RUN_MIDI_CMD_TASK_NAME );
    key_parameters_t key_parameters;

    // First parameter
    command = FreeRTOS_CLIGetParameter
                    (
                        pcCommandString,		/* The command string itself. */
                        1,						/* Return the first parameter. */
                        &xParameter1StringLength	/* Store the parameter string length. */
                    );

    // Second Parameter
    byte1 = FreeRTOS_CLIGetParameter
                    (
                        pcCommandString,		/* The command string itself. */
                        2,						/* Return the first parameter. */
                        &xParameter2StringLength	/* Store the parameter string length. */
                    );

    // Second Parameter
    byte2 = FreeRTOS_CLIGetParameter
                    (
                        pcCommandString,		/* The command string itself. */
                        3,						/* Return the first parameter. */
                        &xParameter3StringLength	/* Store the parameter string length. */
                    );

    // We need at least 2 parameters
    if( command == NULL || byte1 == NULL ) return pdFALSE;

    /////////////////////////////////////////////
    // String to int
    /////////////////////////////////////////////

    command_int = str2int( command, xParameter1StringLength );
    byte1_int   = str2int( byte1,   xParameter2StringLength );
    if ( byte2 != NULL ) byte2_int = str2int( byte2,   xParameter3StringLength );

    full_cmd  = command_int;
    full_cmd |= byte1_int << 8;
    if ( byte2 != NULL ) full_cmd |= byte2_int << 16;

    // Wake up the task and send the full MIDI command the parameters
    xTaskNotify( run_midi_cmd_task_handle,
                 full_cmd,
                 eSetValueWithOverwrite );

    // Don't wait for any feedback
    return pdFALSE;

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
    TaskHandle_t     key_playback_task_handle = xTaskGetHandle( KEY_PLAYBACK_TASK_NAME );
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

    xil_printf("Playing back Key %d, Velocity: %d", key_parameters.key, key_parameters.velocity);


    xQueueSend(my_key_parameters_queue_handler, &key_parameters , 1000);

    // Wake up the task and send the queue handler of the parameters
    xTaskNotify( key_playback_task_handle,
                 my_key_parameters_queue_handler,
                 eSetValueWithOverwrite );

    // Don't wait for any feedback
    return pdFALSE;

}

static BaseType_t stop_all_command( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString ) {

    // Variables for the key playback task
    TaskHandle_t     stop_all_task_handle = xTaskGetHandle( STOP_ALL_TASK_NAME );

    // Wake up the task and send the queue handler of the parameters
    xTaskNotify( stop_all_task_handle,
                 0,
                 eSetValueWithOverwrite );


    vTaskDelay( 100 );

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


static BaseType_t start_midi_listener_command( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString ) {

	uint32_t return_value = 1;

    // Variables for the key playback task
    TaskHandle_t     serial_midi_listener_task_handler = xTaskGetHandle( SERIAL_MIDI_LISTENER_TASK_NAME );

    // Wake up the task and send the full MIDI command the parameters
    xTaskNotify( serial_midi_listener_task_handler,
                 my_return_queue_handler,
                 eSetValueWithOverwrite );


    if( ! xQueueReceive(my_return_queue_handler, &return_value, 10000) ) {
        xil_printf("Timeout!\n\r");
    }
    else {
        xil_printf("Done! Return Value = %d\n\r", return_value);
    }

    // Don't wait for any feedback
    return pdFALSE;

}
