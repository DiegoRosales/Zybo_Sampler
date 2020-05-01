
// C includes
#include <string.h>

// Xilinx includes
#include "xil_cache.h"
#include "xil_printf.h"

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
#include "sampler_dma_voice_pb.h"
#include "sampler_engine.h"
#include "nco.h"

// Defines
#define cliNEW_LINE "\n\r"
#define APPEND_NEWLINE(BUFFER) strcat( BUFFER, cliNEW_LINE )


static BaseType_t play_key_command( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString );
static BaseType_t stop_all_command( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString );
static BaseType_t load_instrument_command( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString );
static BaseType_t midi_command( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString );
static BaseType_t midi_ascii_command( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString );
static BaseType_t start_midi_listener_command( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString );
static BaseType_t playback_sine_command( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString );
static BaseType_t load_sine_command( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString );

////////////////////////////////////////////////////
// External variables
////////////////////////////////////////////////////
extern nco_t sine_nco;

//extern instrument_information;

static xQueueHandle my_filename_queue_handler;
static xQueueHandle my_return_queue_handler;

static xQueueHandle my_key_parameters_queue_handler;

// This function converts an string in int or hex to a uint32_t
static uint32_t str2int( const char *input_string, BaseType_t input_string_length ) {

    const char *start_char = input_string;
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

static void ff_get_file_dir ( const char *file_path, char* dest ) {
    size_t path_len = strlen( file_path );
    char     current_char = '\00';
    uint32_t last_slash = 0;

    for ( int i = 0; i < path_len ; i++ ) {
    	current_char = file_path[i];
        if ( current_char == '/' ) last_slash = i;
    }

    strncat( dest, file_path, last_slash );
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

// Command to load a sine wave into memory
static const CLI_Command_Definition_t playback_sine_command_definition =
{
    "play_sine",
    "\r\nplayback_sine <FREQUENCY>\r\n Starts the playback of a sine wave of a given frequency\r\n",
    playback_sine_command, /* The function to run. */
    1 /* The user can enter any number of commands. */
};

// Command to load a sine wave into memory
static const CLI_Command_Definition_t load_sine_command_definition =
{
    "load_sine",
    "\r\nload_sine <Frequency>:\r\n Load a sine wave of a given frequency into memory\r\n",
    load_sine_command, /* The function to run. */
    1 /* The user can enter any number of commands. */
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
    FreeRTOS_CLIRegisterCommand( &start_midi_listener_command_definition );
   	FreeRTOS_CLIRegisterCommand( &playback_sine_command_definition ); // Load sine command
	FreeRTOS_CLIRegisterCommand( &load_sine_command_definition ); // Load sine command

}

static BaseType_t midi_command( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString ) {

    const char *command = NULL;
    const char *byte1   = NULL;
    const char *byte2   = NULL;

    uint32_t full_cmd = 0;

    BaseType_t xParameter1StringLength;
    BaseType_t xParameter2StringLength;

    // Variables for the key playback task
    TaskHandle_t     run_midi_cmd_task_handle = xTaskGetHandle( RUN_MIDI_CMD_TASK_NAME );

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

    const char *command = NULL;
    const char *byte1   = NULL;
    const char *byte2   = NULL;

    uint8_t command_int = 0;
    uint8_t byte1_int   = 0;
    uint8_t byte2_int   = 0;

    uint32_t full_cmd = 0;

    BaseType_t xParameter1StringLength;
    BaseType_t xParameter2StringLength;
    BaseType_t xParameter3StringLength;


    // Variables for the key playback task
    TaskHandle_t     run_midi_cmd_task_handle = xTaskGetHandle( RUN_MIDI_CMD_TASK_NAME );

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
    key_parameters.key      = us_get_midi_note_number( key );
    key_parameters.velocity = str2int( velocity, xParameter2StringLength );

    xil_printf("Playing back Key %d, Velocity: %d", key_parameters.key, key_parameters.velocity);


    xQueueSend(my_key_parameters_queue_handler, &key_parameters , 1000);

    // Wake up the task and send the queue handler of the parameters
    xTaskNotify( key_playback_task_handle,
                 (uint32_t) my_key_parameters_queue_handler,
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
    // 1 - Get the current directory
    ff_getcwd( my_file_path.file_dir, MAX_PATH_LEN );
    xil_printf( "CWD: %s\n\r", my_file_path.file_dir);
    // Sanity check - Check if the path is less than the maximum allowable
    cwd_path_len = strlen( my_file_path.file_dir );
    configASSERT( ! ( (cwd_path_len + xParameterStringLength + 1) > MAX_PATH_LEN) );

    // 2 - Assemble the full path
    // If you're in the root, append the path as is
    if ( strcmp( my_file_path.file_dir, (const char *)"/" ) == 0 ) {
       // If the path is a full path (i.e. referenced from the root), copy as is
        if ( pcParameter[0] == '/' ) {
            sprintf(my_file_path.file_path, "%s", pcParameter);
        } else { // If it's a relative directory, prepend the root slash
            strcat( my_file_path.file_path, "/");
        }
        ff_get_file_dir( pcParameter, my_file_path.file_dir );
        //strncat( my_file_path.file_path, my_file_path.file_dir, STRLEN( my_file_path.file_dir ) );
        strncat( my_file_path.file_path, pcParameter, xParameterStringLength ); 
    } else {
        // If the path is a full path (i.e. referenced from the root), copy as is
        if ( pcParameter[0] == '/' ) {
            sprintf(my_file_path.file_path, "%s", pcParameter);
        } else { // If it's a relative path, prepend the current directory
            strncat( my_file_path.file_path, my_file_path.file_dir, cwd_path_len);
            strcat( my_file_path.file_path, "/");
            strncat( my_file_path.file_path, pcParameter, xParameterStringLength );
        }
    }

    xil_printf( "File Path: %s\n\r", my_file_path.file_path);

    my_file_path.return_handle = my_return_queue_handler;

    // Send the filename to the task
    xQueueSend(my_filename_queue_handler, &my_file_path , 1000);

    xTaskNotify(    task_handle,
                    (uint32_t) my_filename_queue_handler,
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
                 (uint32_t) my_return_queue_handler,
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


// This starts the playback of a sine wave
static BaseType_t playback_sine_command( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString ) {
    const char         *pcParameter;
    BaseType_t         xParameterStringLength;
    BaseType_t         xReturn;
    static UBaseType_t uxParameterNumber = 0;

	// Custom variables
    uint32_t frequency;
	uint32_t voice_slot;
	static BaseType_t command_done;

	/* Remove compile time warnings about unused parameters, and check the
	write buffer is not NULL.  NOTE - for simplicity, this example assumes the
	write buffer length is adequate, so does not check for buffer overflows. */
	( void ) pcCommandString;
	( void ) xWriteBufferLen;
	configASSERT( pcWriteBuffer );

    if( uxParameterNumber == 0 ) // Parameter 0 (aka no parameter yet)
	{
		/* The first time the function is called after the command has been
		entered just a header string is returned. */
		sprintf( pcWriteBuffer, "The parameters were:\r\n" );

		/* Next time the function is called the first parameter will be echoed
		back. */
		uxParameterNumber = 1U;

		/* There is more data to be returned as no parameters have been echoed
		back yet. */
		xReturn = pdPASS;

		// Initialize command_done
		command_done = pdFALSE;		
	} else {
        /* Obtain the parameter string. */
		pcParameter = FreeRTOS_CLIGetParameter
						(
							pcCommandString,		/* The command string itself. */
							uxParameterNumber,		/* Return the next parameter. */
							&xParameterStringLength	/* Store the parameter string length. */
						);

		if ( ( pcParameter != NULL ) && ( command_done != pdTRUE ) ) {
            // Step 1 - Convert the string into an integer to get the frequency
            frequency = str2int(pcParameter, xParameterStringLength);

            // Step 2 - Initialize NCO variables
            nco_init(&sine_nco, frequency, 48000);

			// Step 3 - Load the values into memory
			nco_load_sine_to_mem(&sine_nco);

			// Step 4 - Flush the data to the DDR
			Xil_DCacheFlushRange( (unsigned int) sine_nco.audio_data, (0x100000 * 2));

			// Step 5 - Start the playback
			voice_slot    = start_voice_playback( (uint32_t) sine_nco.audio_data, sine_nco.target_memory_size );
			uint32_t addr = (uint32_t) sine_nco.audio_data;

			/* Return the parameter string. */
			memset( pcWriteBuffer, 0x00, xWriteBufferLen ); // Initialize the buffer
			sprintf( pcWriteBuffer, "Sine wave of frequency %luHz loaded\n\rNumber of samples = %lu\n\rStart address = 0x%lX\n\rVoice Slot ID = %lu\n\rWritten Address = 0x%lX", frequency, sine_nco.target_memory_size, (uint32_t) sine_nco.audio_data, voice_slot, addr );
			APPEND_NEWLINE(pcWriteBuffer);

			/* There might be more parameters to return after this one. */
			xReturn      = pdPASS;
			command_done = pdTRUE; // Command is done

		}
		else if (command_done == pdTRUE) {
			/* No more parameters were found.  Make sure the write buffer does
			not contain a valid string. */
			pcWriteBuffer[ 0 ] = 0x00;

			/* No more data to return. */
			xReturn = pdFALSE;

			/* Start over the next time this command is executed. */
			uxParameterNumber = 0;
		}
    }

    return xReturn;
}


// This loads a section of memory with a sine wave of a give frequency
static BaseType_t load_sine_command( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString ) {
    const char         *pcParameter;
    BaseType_t         xParameterStringLength;
    BaseType_t         xReturn;
    static UBaseType_t uxParameterNumber = 0;

	// Custom variables
    uint32_t frequency;
	static BaseType_t command_done;

	/* Remove compile time warnings about unused parameters, and check the
	write buffer is not NULL.  NOTE - for simplicity, this example assumes the
	write buffer length is adequate, so does not check for buffer overflows. */
	( void ) pcCommandString;
	( void ) xWriteBufferLen;
	configASSERT( pcWriteBuffer );

    if( uxParameterNumber == 0 ) // Parameter 0 (aka no parameter yet)
	{
		/* The first time the function is called after the command has been
		entered just a header string is returned. */
		sprintf( pcWriteBuffer, "The parameters were:\r\n" );

		/* Next time the function is called the first parameter will be echoed
		back. */
		uxParameterNumber = 1U;

		/* There is more data to be returned as no parameters have been echoed
		back yet. */
		xReturn = pdPASS;

		// Initialize command_done
		command_done = pdFALSE;
	} else {
        /* Obtain the parameter string. */
		pcParameter = FreeRTOS_CLIGetParameter
						(
							pcCommandString,		/* The command string itself. */
							uxParameterNumber,		/* Return the next parameter. */
							&xParameterStringLength	/* Store the parameter string length. */
						);

		if ( ( pcParameter != NULL ) && ( command_done != pdTRUE ) ) {
            // Step 1 - Convert the string into an integer to get the frequency
            frequency = str2int(pcParameter, xParameterStringLength);

            // Step 2 - Initialize NCO variables
            nco_init(&sine_nco, frequency, 48000);

			// Step 3 - Load the values into memory
			nco_load_sine_to_mem(&sine_nco);

			// Step 4 - Flush the data to the DDR
			Xil_DCacheFlushRange( (unsigned int) sine_nco.audio_data, (0x100000 * 2));

			/* Return the parameter string. */
			memset( pcWriteBuffer, 0x00, xWriteBufferLen ); // Initialize the buffer
			sprintf( pcWriteBuffer, "Sine wave of frequency %luHz loaded\n\rNumber of samples = %lu\n\rStart address = 0x%lX", frequency, sine_nco.target_memory_size, (uint32_t) sine_nco.audio_data );
			APPEND_NEWLINE(pcWriteBuffer);

			/* There might be more parameters to return after this one. */
			xReturn      = pdPASS;
			command_done = pdTRUE; // Command is done

		}
		else if (command_done == pdTRUE) {
			/* No more parameters were found.  Make sure the write buffer does
			not contain a valid string. */
			pcWriteBuffer[ 0 ] = 0x00;

			/* No more data to return. */
			xReturn = pdFALSE;

			/* Start over the next time this command is executed. */
			uxParameterNumber = 0;
		}
    }

    return xReturn;
}
