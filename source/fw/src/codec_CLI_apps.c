/////////////////////////////////////////////////////////////////////////
// This file contains all the CLI applications related to the ZyboSampler
// that will be registered in the FreeRTOS CLI
/////////////////////////////////////////////////////////////////////////

// FreeRTOS Includes
#include "FreeRTOS.h"
#include "task.h"
#include "FreeRTOS_CLI.h"

// Other
#include "codec_CLI_apps.h"

//////////////////////////////////////////////////////
// CLI Command Definitions
//////////////////////////////////////////////////////

static const CLI_Command_Definition_t echo_command_definition =
{
    "echo",
    "\r\echo:\r\n Simple echo command.\r\n",
    echo_command, /* The function to run. */
    -1 /* The user can enter any number of commands. */
};


void register_codec_cli_commands( void ) {

    FreeRTOS_CLIRegisterCommand( &echo_command_definition ); // Echo Command

}



//////////////////////////////////////////////////////
// CLI Command Implementations
//////////////////////////////////////////////////////

static BaseType_t echo_command( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString ) {
    const char *pcParameter;
    BaseType_t xParameterStringLength, xReturn;
    static UBaseType_t uxParameterNumber = 0;

	/* Remove compile time warnings about unused parameters, and check the
	write buffer is not NULL.  NOTE - for simplicity, this example assumes the
	write buffer length is adequate, so does not check for buffer overflows. */
	( void ) pcCommandString;
	( void ) xWriteBufferLen;
	configASSERT( pcWriteBuffer );

	if( uxParameterNumber == 0 )
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
	}
	else
	{
		/* Obtain the parameter string. */
		pcParameter = FreeRTOS_CLIGetParameter
						(
							pcCommandString,		/* The command string itself. */
							uxParameterNumber,		/* Return the next parameter. */
							&xParameterStringLength	/* Store the parameter string length. */
						);

		if( pcParameter != NULL )
		{
			/* Return the parameter string. */
			memset( pcWriteBuffer, 0x00, xWriteBufferLen );
			sprintf( pcWriteBuffer, "%d: ", ( int ) uxParameterNumber );
			strncat( pcWriteBuffer, ( char * ) pcParameter, ( size_t ) xParameterStringLength );
			strncat( pcWriteBuffer, "\r\n", strlen( "\r\n" ) );

			/* There might be more parameters to return after this one. */
			xReturn = pdTRUE;
			uxParameterNumber++;
		}
		else
		{
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
