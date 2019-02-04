/////////////////////////////////////////////////////////////////////////
// This file contains all the CLI applications related to the ZyboSampler
// that will be registered in the FreeRTOS CLI
/////////////////////////////////////////////////////////////////////////

// C includes
#include <string.h>

// FreeRTOS Includes
#include "FreeRTOS.h"
#include "task.h"
#include "FreeRTOS_CLI.h"

// Other
#include "codec_CLI_apps.h"
#include "reg_utils.h"
#include "codec_utils.h"

//////////////////////////////////////////////////////
// CLI Command Definitions
//////////////////////////////////////////////////////

// Echo Command
static const CLI_Command_Definition_t echo_command_definition =
{
    "echo",
    "\r\necho:\r\n Simple echo command.\r\n",
    echo_command, /* The function to run. */
    -1 /* The user can enter any number of commands. */
};

// Command to read a register from the sampler in the PL
static const CLI_Command_Definition_t sampler_read_command_definition =
{
    "sampler_read",
    "\r\nsampler_read <ADDR>:\r\n Read a register from the sampler\r\n",
    sampler_read_command, /* The function to run. */
    1 /* The user can enter any number of commands. */
};

// Command to read a register from the CODEC in the Zybo board
static const CLI_Command_Definition_t codec_read_command_definition =
{
    "codec_read",
    "\r\ncodec_read <ADDR>:\r\n Read a register from the CODEC\r\n",
    codec_read_command, /* The function to run. */
    1 /* The user can enter any number of commands. */
};

////////////////////////////////////////////////////////
// Functions
////////////////////////////////////////////////////////

// This function registers all the CLI applications
void register_codec_cli_commands( void ) {

    FreeRTOS_CLIRegisterCommand( &echo_command_definition ); // Echo Command
    FreeRTOS_CLIRegisterCommand( &sampler_read_command_definition ); // Sampler Read Command
    FreeRTOS_CLIRegisterCommand( &codec_read_command_definition ); // Sampler Read Command

}

// This function converts an string in int or hex to a uint32_t
uint32_t str2int( char *input_string, BaseType_t input_string_length ) {

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

            uxParameterNumber = 0;
			/* There might be more parameters to return after this one. */
			xReturn = pdFALSE;
			//uxParameterNumber++;
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

// This command reads the data from the sampler in the PL
static BaseType_t sampler_read_command( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString ) {
    const char         *pcParameter;
    BaseType_t         xParameterStringLength;
    BaseType_t         xReturn;
    static UBaseType_t uxParameterNumber = 0;
    uint32_t           addr_int;
    uint32_t           reg_output;

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
	} else {
        /* Obtain the parameter string. */
		pcParameter = FreeRTOS_CLIGetParameter
						(
							pcCommandString,		/* The command string itself. */
							uxParameterNumber,		/* Return the next parameter. */
							&xParameterStringLength	/* Store the parameter string length. */
						);

		if( pcParameter != NULL ) { // Address
            // Step 1 - Convert the string into an integer
            addr_int = str2int(pcParameter, xParameterStringLength);

            // Step 2 - Read the address
            reg_output = RegRd(addr_int, 0);

			/* Return the parameter string. */
			memset( pcWriteBuffer, 0x00, xWriteBufferLen );
			sprintf( pcWriteBuffer, "SAMPLER[0x%x] = 0x%x", addr_int, reg_output );
			//strncat( pcWriteBuffer, ( char * ) pcParameter, ( size_t ) xParameterStringLength );
			strncat( pcWriteBuffer, "\r\n", strlen( "\r\n" ) );

			/* There might be more parameters to return after this one. */
			xReturn = pdFALSE;
			uxParameterNumber = 0;
		}
		else {
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

// This command reads from the CODEC chip in the Zybo
static BaseType_t codec_read_command( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString ) {
    const char         *pcParameter;
    BaseType_t         xParameterStringLength;
    BaseType_t         xReturn;
    static UBaseType_t uxParameterNumber = 0;
    uint32_t           addr_int;
    uint32_t           reg_output;

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
	} else {
        /* Obtain the parameter string. */
		pcParameter = FreeRTOS_CLIGetParameter
						(
							pcCommandString,		/* The command string itself. */
							uxParameterNumber,		/* Return the next parameter. */
							&xParameterStringLength	/* Store the parameter string length. */
						);

		if( pcParameter != NULL ) { // Address
            // Step 1 - Convert the string into an integer
            addr_int = str2int(pcParameter, xParameterStringLength);

            // Step 2 - Read the address
            reg_output = CodecRd(addr_int, 0, 0);

			/* Return the parameter string. */
			memset( pcWriteBuffer, 0x00, xWriteBufferLen );
			sprintf( pcWriteBuffer, "CODEC[0x%x] = 0x%x", addr_int, reg_output );
			//strncat( pcWriteBuffer, ( char * ) pcParameter, ( size_t ) xParameterStringLength );
			strncat( pcWriteBuffer, "\r\n", strlen( "\r\n" ) );

			/* There might be more parameters to return after this one. */
			xReturn = pdFALSE;
			uxParameterNumber = 0;
		}
		else {
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