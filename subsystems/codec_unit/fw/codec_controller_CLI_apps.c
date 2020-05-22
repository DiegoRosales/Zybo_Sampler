/////////////////////////////////////////////////////////////////////////
// This file contains all the CLI applications related to the ZyboSampler
// that will be registered in the FreeRTOS CLI
/////////////////////////////////////////////////////////////////////////

// C includes
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

// FreeRTOS Includes
#include "FreeRTOS.h"
#include "task.h"
#include "FreeRTOS_CLI.h"

// Other
#include "codec_controller_CLI_apps.h"
#include "codec_controller_reg_utils.h"
#include "codec_controller_utils.h"
#include "nco.h"

// Defines
#define cliNEW_LINE "\n\r"
#define APPEND_NEWLINE(BUFFER) strcat( BUFFER, cliNEW_LINE )

// Commands
static BaseType_t prv_xEchoCMD( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString );
static BaseType_t prv_xControlRegCMD( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString );
static BaseType_t prv_xCODECRegCMD( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString );

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

////////////////////////////////////////////////////
// External variables
////////////////////////////////////////////////////
extern nco_t sine_nco;

//////////////////////////////////////////////////////
// CLI Command Definitions
//////////////////////////////////////////////////////

// Echo Command
static const CLI_Command_Definition_t prv_xEchoCMD_definition =
{
    "echo",
    "\r\necho:\r\n Simple echo command.\r\n",
    prv_xEchoCMD, /* The function to run. */
    -1 /* The user can enter any number of commands. */
};

// Command to read/write a register from the sampler in the PL
static const CLI_Command_Definition_t prv_xControlRegCMD_definition =
{
    "control_reg",
    "\r\ncontrol_reg <ADDR>\n\rcontrol_reg <ADDR> <DATA>\r\n Read/Write a register from the sampler\r\n",
    prv_xControlRegCMD, /* The function to run. */
    -1 /* The user can enter any number of commands. */
};

// Command to read a register from the CODEC in the Zybo board
static const CLI_Command_Definition_t prv_xCODECRegCMD_definition =
{
    "codec_reg",
    "\r\ncodec_reg <ADDR>\n\rcodec_reg <ADDR> <DATA>\r\n Read/Write a register from the codec\r\n",
    prv_xCODECRegCMD, /* The function to run. */
    -1 /* The user can enter any number of commands. */
};

////////////////////////////////////////////////////////
// Functions
////////////////////////////////////////////////////////

// This function registers all the CLI applications
void vRegisterCODECCLICommands( void ) {

    FreeRTOS_CLIRegisterCommand( &prv_xEchoCMD_definition ); // Echo Command
    FreeRTOS_CLIRegisterCommand( &prv_xControlRegCMD_definition ); // Control Reg Read/Write Command
    FreeRTOS_CLIRegisterCommand( &prv_xCODECRegCMD_definition ); // Sampler Read Command

}




//////////////////////////////////////////////////////
// CLI Command Implementations
//////////////////////////////////////////////////////

static BaseType_t prv_xEchoCMD( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString ) {
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
			APPEND_NEWLINE(pcWriteBuffer);

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
static BaseType_t prv_xControlRegCMD( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString ) {
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
				reg_output = ulCodecCtrlRegRd(addr_int, 0);
				sprintf( pcWriteBuffer, "SAMPLER[0x%lx] = 0x%lx", addr_int, reg_output );
			} else if ( uxParameterNumber == 3 ) {
				// Write the data
				ulCodecCtrlRegWr( addr_int, data_int, 0, 0 );
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


// This command reads/writes data from the CODEC chip of the Zybo board
static BaseType_t prv_xCODECRegCMD( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString ) {
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
					sprintf( pcWriteBuffer, "[ERROR] - Bad number of arguments. Number of parameters = %lu", (uxParameterNumber - 1) );
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
				reg_output = ulCodecRd(addr_int, 0, 0);
				sprintf( pcWriteBuffer, "CODEC[0x%lx] = 0x%lx", addr_int, reg_output );
			} else if ( uxParameterNumber == 3 ) {
				// Write the data
				ulCodecWr( addr_int, data_int, 0, 0, 0 );
				sprintf( pcWriteBuffer, "CODEC[0x%lx] <== 0x%lx", addr_int, data_int );
			} else {
				sprintf( pcWriteBuffer, "Number of parameters = %lu", uxParameterNumber );
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






