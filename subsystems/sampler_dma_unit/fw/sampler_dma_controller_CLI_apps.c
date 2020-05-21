/////////////////////////////////////////////////////////////////////////
// This file contains all the CLI applications related to the
// Sampler DMA Controller
/////////////////////////////////////////////////////////////////////////

// C includes
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

// FreeRTOS Includes
#include "FreeRTOS.h"
#include "task.h"
#include "FreeRTOS_CLI.h"

// Sampler Register Utils
#include "sampler_dma_controller_regs.h"
#include "sampler_dma_controller_reg_utils.h"

// Sampler DMA Controller CLI Apps
#include "sampler_dma_controller_CLI_apps.h"

// Defines
#define cliNEW_LINE "\n\r"
#define APPEND_NEWLINE(BUFFER) strcat( BUFFER, cliNEW_LINE )

static BaseType_t prv_xSamplerRegCMD( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString );
static BaseType_t prv_xGetSamplerHWVersionCMD( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString );

// This function converts an string in int or hex to a uint32_t
static uint32_t prv_ulStr2Int( const char *input_string, BaseType_t input_string_length ) {

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

// Command to read a register from the Sampler DMA Controller
static const CLI_Command_Definition_t prv_xSamplerRegCMD_definition =
{
    "sampler_reg",
    "\r\nsampler_reg <ADDR>\n\rsampler_reg <ADDR> <DATA>\r\n Read/Write a register from the sampler\r\n",
    prv_xSamplerRegCMD, /* The function to run. */
    -1 /* The user can enter any number of commands. */
};

// Command to get the version of the Sampler DMA Controller
static const CLI_Command_Definition_t prv_xGetSamplerHWVersionCMD_definition =
{
    "get_sampler_dma_hw_version",
    "\r\nget_sampler_dma_hw_version\r\n Returns the version of the Hardware Sampler\r\n",
    prv_xGetSamplerHWVersionCMD, /* The function to run. */
    0 /* The user can enter any number of commands. */
};

// Register all the CLI commands
void vRegisterSamplerDMAControllerCLICommands( void ) {
    FreeRTOS_CLIRegisterCommand( &prv_xSamplerRegCMD_definition );         // Sampler Read/Write Command
   	FreeRTOS_CLIRegisterCommand( &prv_xGetSamplerHWVersionCMD_definition ); // Get sampler version

}


// This command reads the data from the sampler in the PL
static BaseType_t prv_xSamplerRegCMD( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString ) {
    const char         *pcParameter;
    BaseType_t         xParameterStringLength;
    BaseType_t         xReturn;
    static UBaseType_t uxParameterNumber = 0;

	// Internal Variables
    static uint32_t addr_int;
	static uint32_t data_int;
    static uint32_t reg_output;
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

		if( pcParameter != NULL ) { // Address

			memset( pcWriteBuffer, 0x00, xWriteBufferLen );

			switch ( uxParameterNumber )
			{
				case 1: // Address
					addr_int = prv_ulStr2Int(pcParameter, xParameterStringLength);
					sprintf( pcWriteBuffer, "Address = 0x%lx", addr_int );
					break;
				case 2: // Data
					data_int = prv_ulStr2Int(pcParameter, xParameterStringLength);
					sprintf( pcWriteBuffer, "Data = 0x%lx", addr_int );
					break;
				default:
					sprintf( pcWriteBuffer, "Unknown Parameter %lu: %s", uxParameterNumber, pcParameter );
					break;
			}

			APPEND_NEWLINE(pcWriteBuffer);


			/* There might be more parameters to return after this one. */
			xReturn = pdPASS;
			uxParameterNumber++;
		}
		else if (command_done != pdTRUE) {

			if ( uxParameterNumber == 2 ) {
				// Read the data
				reg_output = ulSamplerRegRd(addr_int);
				sprintf( pcWriteBuffer, "SAMPLER[0x%lx] = 0x%lx", addr_int, reg_output );
			} else if ( uxParameterNumber == 3 ) {
				// Write the data
				ulSamplerRegWr( addr_int, data_int, 0);
				sprintf( pcWriteBuffer, "SAMPLER[0x%lx] <== 0x%lx", addr_int, data_int );
			} else {
				sprintf( pcWriteBuffer, "[ERROR] - Bad number of arguments. Number of parameters = %lu", (uxParameterNumber - 1) );
			}


			APPEND_NEWLINE(pcWriteBuffer);
			command_done = pdTRUE; // Command is done
			xReturn      = pdPASS;

		} else {
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
static BaseType_t prv_xGetSamplerHWVersionCMD( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString ) {
    BaseType_t         xReturn;

	// Custom variables
  uint32_t sampler_version;
	uint32_t major_version;
	uint32_t minor_version;
	static BaseType_t command_done = pdFALSE;

	/* Remove compile time warnings about unused parameters, and check the
	write buffer is not NULL.  NOTE - for simplicity, this example assumes the
	write buffer length is adequate, so does not check for buffer overflows. */
	( void ) pcCommandString;
	( void ) xWriteBufferLen;
	configASSERT( pcWriteBuffer );


	if ( command_done != pdTRUE ) {
		sampler_version = ulGetDMAEngineHWVersion();
		major_version   = ( sampler_version >> 16 ) & 0xffff;
		minor_version   = sampler_version & 0xffff;


		memset( pcWriteBuffer, 0x00, xWriteBufferLen ); // Initialize the buffer
		sprintf( pcWriteBuffer, "Sampler DMA Controller Version %lu.%lu", major_version, minor_version );
		APPEND_NEWLINE(pcWriteBuffer);

		command_done = pdTRUE;
		xReturn      = pdTRUE; // Come back to re-initialize the variables
	} else {
		/* No more parameters were found.  Make sure the write buffer does
		not contain a valid string. */
		pcWriteBuffer[ 0 ] = 0x00;

		/* No more data to return. */
		xReturn = pdFALSE;

		command_done = pdFALSE;
	}

    return xReturn;
}
