
// C includes
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

// Xilinx includes
#include "xil_cache.h"
#include "xil_printf.h"

// FreeRTOS Includes
#include "FreeRTOS.h"
#include "task.h"
#include "semphr.h"
#include "queue.h"
#include "FreeRTOS_CLI.h"

// Sampler Includes
#include "sampler_CLI_apps.h"
#include "sampler_FreeRTOS_tasks.h"
#include "sampler_dma_voice_pb.h"
#include "sampler_engine.h"
#include "nco.h"

///////////////////////////////////////
// Defines
///////////////////////////////////////
#define APPEND_NEWLINE(BUFFER) strcat( BUFFER, cliNEW_LINE )

///////////////////////////////////////
// Static Functions
///////////////////////////////////////
static BaseType_t prv_xPlaybackSineWaveCMD( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString );
static uint32_t   prv_ulStrToInt( const char *input_string, BaseType_t input_string_length );


///////////////////////////////////////
// Command Definition Structure
///////////////////////////////////////
// >> playback_sine <FREQUENCY>
static const CLI_Command_Definition_t prv_xPlaybackSineWaveCMD_definition =
{
    "play_sine",
    "\r\nplayback_sine <FREQUENCY>\r\n Starts the playback of a sine wave of a given frequency\r\n",
    prv_xPlaybackSineWaveCMD, /* The function to run. */
    1 /* 1 parameter is expected. */
};

///////////////////////////////////////
// Misc. Variables
///////////////////////////////////////
extern nco_t sine_nco;

// Queue handlers to send data between the Commands and the Tasks
static xQueueHandle xFilenameQueueHandler;
static xQueueHandle xReturnQueueHandler;
static xQueueHandle xKeyParamsQueueHandler;

///////////////////////////////////////
// Function to register the command
///////////////////////////////////////
void vRegisterPlaybackSineWaveCMD( void ) {

  // Queue handlers to send data between the Commands and the Tasks
  xFilenameQueueHandler  = xQueueCreate(1, sizeof(file_path_handler_t));
  xReturnQueueHandler    = xQueueCreate(1, sizeof(uint32_t));
  xKeyParamsQueueHandler = xQueueCreate(1, sizeof(uint32_t));

  FreeRTOS_CLIRegisterCommand( &prv_xPlaybackSineWaveCMD_definition ); // Load sine command
}

///////////////////////////////////////
// Actual Command Implementation
///////////////////////////////////////
// This starts the playback of a sine wave
static BaseType_t prv_xPlaybackSineWaveCMD( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString ) {
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
            frequency = prv_ulStrToInt(pcParameter, xParameterStringLength);

            // Step 2 - Initialize NCO variables
            nco_init(&sine_nco, frequency, 48000);

			// Step 3 - Load the values into memory
			nco_load_sine_to_mem(&sine_nco);

			// Step 4 - Flush the data to the DDR
			Xil_DCacheFlushRange( (unsigned int) sine_nco.audio_data, (0x100000 * 2));

			// Step 5 - Start the playback
			voice_slot    = ulStartVoicePlayback( (uint32_t) sine_nco.audio_data, sine_nco.target_memory_size );
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
///////////////////////////////////////
// Misc Private Functions
///////////////////////////////////////
// This function converts an string in int or hex to a uint32_t
static uint32_t prv_ulStrToInt( const char *input_string, BaseType_t input_string_length ) {

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