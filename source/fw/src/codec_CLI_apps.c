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
#include "nco.h"
#include "sampler.h"

////////////////////////////////////////////////////
// External variables
////////////////////////////////////////////////////
extern nco_t sine_nco;

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

// Command to read/write a register from the sampler in the PL
static const CLI_Command_Definition_t control_reg_command_definition =
{
    "control_reg",
    "\r\ncontrol_reg <ADDR>\n\rcontrol_reg <ADDR> <DATA>\r\n Read/Write a register from the sampler\r\n",
    control_reg_command, /* The function to run. */
    -1 /* The user can enter any number of commands. */
};

// Command to read a register from the CODEC in the Zybo board
static const CLI_Command_Definition_t sampler_reg_command_definition =
{
    "sampler_reg",
    "\r\nsampler_reg <ADDR>\n\rsampler_reg <ADDR> <DATA>\r\n Read/Write a register from the sampler\r\n",
    sampler_reg_command, /* The function to run. */
    -1 /* The user can enter any number of commands. */
};

// Command to read a register from the CODEC in the Zybo board
static const CLI_Command_Definition_t codec_reg_command_definition =
{
    "codec_reg",
    "\r\ncodec_reg <ADDR>\n\rcodec_reg <ADDR> <DATA>\r\n Read/Write a register from the codec\r\n",
    codec_reg_command, /* The function to run. */
    -1 /* The user can enter any number of commands. */
};

// Command to load a sine wave into memory
static const CLI_Command_Definition_t load_sine_command_definition =
{
    "load_sine",
    "\r\nload_sine <Frequency>:\r\n Load a sine wave of a given frequency into memory\r\n",
    load_sine_command, /* The function to run. */
    1 /* The user can enter any number of commands. */
};

// Command to load a sine wave into memory
static const CLI_Command_Definition_t get_sampler_version_command_definition =
{
    "get_sampler_version",
    "\r\nget_sampler_version\r\n Returns the version of the Hardware Sampler\r\n",
    get_sampler_version_command, /* The function to run. */
    0 /* The user can enter any number of commands. */
};

////////////////////////////////////////////////////////
// Functions
////////////////////////////////////////////////////////

// This function registers all the CLI applications
void register_codec_cli_commands( void ) {

    FreeRTOS_CLIRegisterCommand( &echo_command_definition ); // Echo Command
    FreeRTOS_CLIRegisterCommand( &control_reg_command_definition ); // Control Reg Read/Write Command
    FreeRTOS_CLIRegisterCommand( &sampler_reg_command_definition ); // Sampler Read/Write Command	
    FreeRTOS_CLIRegisterCommand( &codec_reg_command_definition ); // Sampler Read Command
	FreeRTOS_CLIRegisterCommand( &load_sine_command_definition ); // Load sine command
	FreeRTOS_CLIRegisterCommand( &get_sampler_version_command_definition ); // Load sine command

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
static BaseType_t control_reg_command( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString ) {
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
					addr_int = str2int(pcParameter, xParameterStringLength);
					sprintf( pcWriteBuffer, "Address = 0x%x", addr_int );
					break;
				case 2: // Data
					data_int = str2int(pcParameter, xParameterStringLength);
					sprintf( pcWriteBuffer, "Data = 0x%x", addr_int );
					break;
				default:
					sprintf( pcWriteBuffer, "Unknown Parameter %d: %x", uxParameterNumber, pcParameter );
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
				reg_output = RegRd(addr_int, 0);
				sprintf( pcWriteBuffer, "SAMPLER[0x%x] = 0x%x", addr_int, reg_output );
			} else if ( uxParameterNumber == 3 ) {
				// Write the data
				RegWr( addr_int, data_int, 0, 0 );
				sprintf( pcWriteBuffer, "SAMPLER[0x%x] <== 0x%x", addr_int, data_int );
			} else {
				sprintf( pcWriteBuffer, "[ERROR] - Bad number of arguments. Number of parameters = %d", (uxParameterNumber - 1) );
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

// This command reads the data from the sampler in the PL
static BaseType_t sampler_reg_command( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString ) {
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
					addr_int = str2int(pcParameter, xParameterStringLength);
					sprintf( pcWriteBuffer, "Address = 0x%x", addr_int );
					break;
				case 2: // Data
					data_int = str2int(pcParameter, xParameterStringLength);
					sprintf( pcWriteBuffer, "Data = 0x%x", addr_int );
					break;
				default:
					sprintf( pcWriteBuffer, "Unknown Parameter %d: %x", uxParameterNumber, pcParameter );
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
				reg_output = SamplerRegRd(addr_int);
				sprintf( pcWriteBuffer, "SAMPLER[0x%x] = 0x%x", addr_int, reg_output );
			} else if ( uxParameterNumber == 3 ) {
				// Write the data
				SamplerRegWr( addr_int, data_int, 0);
				sprintf( pcWriteBuffer, "SAMPLER[0x%x] <== 0x%x", addr_int, data_int );
			} else {
				sprintf( pcWriteBuffer, "[ERROR] - Bad number of arguments. Number of parameters = %d", (uxParameterNumber - 1) );
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
static BaseType_t codec_reg_command( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString ) {
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
					addr_int = str2int(pcParameter, xParameterStringLength);
					sprintf( pcWriteBuffer, "Address = 0x%x", addr_int );
					break;
				case 2: // Data
					data_int = str2int(pcParameter, xParameterStringLength);
					sprintf( pcWriteBuffer, "Data = 0x%x", addr_int );
					break;
				default:
					sprintf( pcWriteBuffer, "[ERROR] - Bad number of arguments. Number of parameters = %d", (uxParameterNumber - 1) );
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
				reg_output = CodecRd(addr_int, 0, 0);
				sprintf( pcWriteBuffer, "CODEC[0x%x] = 0x%x", addr_int, reg_output );
			} else if ( uxParameterNumber == 3 ) {
				// Write the data
				CodecWr( addr_int, data_int, 0, 0, 0 );
				sprintf( pcWriteBuffer, "CODEC[0x%x] <== 0x%x", addr_int, data_int );
			} else {
				sprintf( pcWriteBuffer, "Number of parameters = %d", uxParameterNumber );
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
			Xil_DCacheFlushRange(sine_nco.audio_data, (0x100000 * 2));

			/* Return the parameter string. */
			memset( pcWriteBuffer, 0x00, xWriteBufferLen ); // Initialize the buffer
			sprintf( pcWriteBuffer, "Sine wave of frequency %dHz loaded\n\rNumber of samples = %d\n\rStart address = 0x%x", frequency, sine_nco.target_memory_size, sine_nco.audio_data );
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
static BaseType_t get_sampler_version_command( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString ) {
    const char         *pcParameter;
    BaseType_t         xParameterStringLength;
    BaseType_t         xReturn;
    static UBaseType_t uxParameterNumber = 0;

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
		sampler_version = get_sampler_version();
		major_version   = ( sampler_version >> 16 ) & 0xffff;
		minor_version   = sampler_version & 0xffff;


		memset( pcWriteBuffer, 0x00, xWriteBufferLen ); // Initialize the buffer
		sprintf( pcWriteBuffer, "Sampler Version %d.%d", major_version, minor_version );
		APPEND_NEWLINE(pcWriteBuffer);

		command_done = pdTRUE;
		xReturn      = pdTRUE; // Come back to re-initialize the variables
	} else {
		/* No more parameters were found.  Make sure the write buffer does
		not contain a valid string. */
		pcWriteBuffer[ 0 ] = 0x00;

		/* No more data to return. */
		xReturn = pdFALSE;

		/* Start over the next time this command is executed. */
		uxParameterNumber = 0;

		command_done = pdFALSE;
	}

    return xReturn;
}