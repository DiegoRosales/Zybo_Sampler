
// C includes
#include <string.h>

// FreeRTOS Includes
#include "FreeRTOS.h"
#include "task.h"
#include "FreeRTOS_CLI.h"

// FreeRTOS+FAT includes
#include "ff_stdio.h"
#include "ff_ramdisk.h"
#include "ff_sddisk.h"

// Sampler Includes
#include "sampler_CLI_apps.h"
#include "sampler.h"

static uint8_t instrument_info_buffer[MAX_INST_FILE_SIZE];
extern instrument_information;

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
    FreeRTOS_CLIRegisterCommand( &load_instrument_command_definition );
}



static BaseType_t load_instrument_command( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString )
{
    const char *pcParameter;
    BaseType_t xParameterStringLength, xReturn = pdTRUE;
    static FF_FILE *pxFile = NULL;
    int iChar;
    size_t xByte;
    size_t xColumns = 50U;
    size_t file_size = 0;

	

	/* Ensure there is always a null terminator after each character written. */
	memset( pcWriteBuffer, 0x00, xWriteBufferLen );

	// Clear the buffer
	memset( instrument_info_buffer, 0x00, MAX_INST_FILE_SIZE );

	/* Ensure the buffer leaves space for the \r\n. */
	configASSERT( xWriteBufferLen > ( strlen( cliNEW_LINE ) * 2 ) );
	xWriteBufferLen -= strlen( cliNEW_LINE );
	xColumns = xWriteBufferLen - 1;

    // Step 1 - Open the json file containing the instrument information
	if( pxFile == NULL )
	{
		/* The file has not been opened yet.  Find the file name. */
		pcParameter = FreeRTOS_CLIGetParameter
						(
							pcCommandString,		/* The command string itself. */
							1,						/* Return the first parameter. */
							&xParameterStringLength	/* Store the parameter string length. */
						);

		/* Sanity check something was returned. */
		configASSERT( pcParameter );

		/* Attempt to open the requested file. */
		pxFile = ff_fopen( pcParameter, "r" );

        // Get the size of the file
        file_size = ff_filelength( pxFile );

        // If the file is too big, give an error
        if ( file_size > MAX_INST_FILE_SIZE ) {
            sprintf( pcWriteBuffer, "[ERROR] - Instrument information file is too large. File = %d bytes | max supported = %d bytes", file_size, MAX_INST_FILE_SIZE );
            strcat( pcWriteBuffer, cliNEW_LINE );
            xReturn = pdFALSE;
            return xReturn;
        }
	}

    // Step 2 - Load the file into memory
	if( pxFile != NULL )
	{
		/* Read the next chunk of data from the file. */
		for( xByte = 0; xByte < MAX_INST_FILE_SIZE; xByte++ )
		{
			iChar = ff_fgetc( pxFile );

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
	}

	// Step 3 - Initialize the instrument information
	if ( instrument_information == NULL ){
		instrument_information = init_instrument_information(88, 1);
		if ( instrument_information == NULL ){
			xReturn = pdFALSE;
			return xReturn;
		}
	}
    // Step 4 - Decode the JSON file
    decode_instrument_information( &instrument_info_buffer, &instrument_information);

	if( pxFile == NULL )
	{
		/* Either the file was not opened, or all the data from the file has
		been returned and the file is now closed. */
		xReturn = pdFALSE;
	}

	strcat( pcWriteBuffer, cliNEW_LINE );

	return xReturn;
}