

// C includes
#include <string.h>

// FreeRTOS Includes
#include "FreeRTOS.h"
#include "task.h"
#include "FreeRTOS_CLI.h"
#include "FreeRTOSFATConfig.h"

// FreeRTOS+FAT includes
#include "ff_stdio.h"
#include "ff_ramdisk.h"
#include "ff_sddisk.h"

// Other
#include "fat_CLI_apps.h"

extern pxSDDisk;

////////////////////////////////////////////////////////
// Command Register
////////////////////////////////////////////////////////
// Echo Command
static const CLI_Command_Definition_t sd_initialization_command_definition =
{
    "sd_init",
    "\r\rsd_init\r\n Initialize the SD Card and mount it as root\r\n",
    sd_initialization_command, /* The function to run. */
    0 /* The user can enter any number of commands. */
};

/* Structure that defines the DIR command line command, which lists all the
files in the current directory. */
static const CLI_Command_Definition_t xDIR =
{
	"dir", /* The command string to type. */
	"\r\ndir:\r\n Lists the files in the current directory\r\n",
	prvDIRCommand, /* The function to run. */
	0 /* No parameters are expected. */
};

/* Structure that defines the CD command line command, which changes the
working directory. */
static const CLI_Command_Definition_t xCD =
{
	"cd", /* The command string to type. */
	"\r\ncd <dir name>:\r\n Changes the working directory\r\n",
	prvCDCommand, /* The function to run. */
	1 /* One parameter is expected. */
};

/* Structure that defines the TYPE command line command, which prints the
contents of a file to the console. */
static const CLI_Command_Definition_t xTYPE =
{
	"type", /* The command string to type. */
	"\r\ntype <filename>:\r\n Prints file contents to the terminal\r\n",
	prvTYPECommand, /* The function to run. */
	1 /* One parameter is expected. */
};

/* Structure that defines the pwd command line command, which prints the current working directory. */
static const CLI_Command_Definition_t xPWD =
{
	"pwd", /* The command string to type. */
	"\r\npwd:\r\n Print Working Directory\r\n",
	prvPWDCommand, /* The function to run. */
	0 /* No parameters are expected. */
};

////////////////////////////////////////////////////////
// Functions
////////////////////////////////////////////////////////

// This function registers all the CLI applications
void register_fat_cli_commands( void ) {
    FreeRTOS_CLIRegisterCommand( &sd_initialization_command_definition );
    FreeRTOS_CLIRegisterCommand( &xDIR );
    FreeRTOS_CLIRegisterCommand( &xCD );
    FreeRTOS_CLIRegisterCommand( &xTYPE );
    FreeRTOS_CLIRegisterCommand( &xPWD );

}

static void prvCreateFileInfoString( char *pcBuffer, FF_FindData_t *pxFindStruct )
{
    const char * pcWritableFile = "writable file", *pcReadOnlyFile = "read only file", *pcDirectory = "directory";
    const char * pcAttrib;

	/* Point pcAttrib to a string that describes the file. */
	if( ( pxFindStruct->ucAttributes & FF_FAT_ATTR_DIR ) != 0 )
	{
		pcAttrib = pcDirectory;
	}
	else if( pxFindStruct->ucAttributes & FF_FAT_ATTR_READONLY )
	{
		pcAttrib = pcReadOnlyFile;
	}
	else
	{
		pcAttrib = pcWritableFile;
	}

	/* Create a string that includes the file name, the file size and the
	attributes string. */
	sprintf( pcBuffer, "%s [%s] [size=%d]", pxFindStruct->pcFileName, pcAttrib, ( int ) pxFindStruct->ulFileSize );
}

////////////////////////////////////////////////////////
// Commands
////////////////////////////////////////////////////////

static BaseType_t sd_initialization_command( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString ) {

	/* Remove compile time warnings about unused parameters, and check the
	write buffer is not NULL.  NOTE - for simplicity, this example assumes the
	write buffer length is adequate, so does not check for buffer overflows. */
	( void ) pcCommandString;
	( void ) xWriteBufferLen;

    pxSDDisk = FF_SDDiskInit( mainSD_CARD_DISK_NAME );


    return pdFALSE;


}


static BaseType_t prvDIRCommand( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString )
{
static FF_FindData_t *pxFindStruct = NULL;
int iReturned;
BaseType_t xReturn = pdFALSE;

	/* This assumes pcWriteBuffer is long enough. */
	( void ) pcCommandString;

	/* Ensure the buffer leaves space for the \r\n. */
	configASSERT( xWriteBufferLen > ( strlen( cliNEW_LINE ) * 2 ) );
	xWriteBufferLen -= strlen( cliNEW_LINE );

	if( pxFindStruct == NULL )
	{
		/* This is the first time this function has been executed since the Dir
		command was run.  Create the find structure. */
		pxFindStruct = ( FF_FindData_t * ) pvPortMalloc( sizeof( FF_FindData_t ) );

		if( pxFindStruct != NULL )
		{
			memset( pxFindStruct, 0x00, sizeof( FF_FindData_t ) );
			iReturned = ff_findfirst( "", pxFindStruct );

			if( iReturned == FF_ERR_NONE )
			{
				prvCreateFileInfoString( pcWriteBuffer, pxFindStruct );
				xReturn = pdPASS;
			}
			else
			{
				snprintf( pcWriteBuffer, xWriteBufferLen, "Error: ff_findfirst() failed." );
				pxFindStruct = NULL;
			}
		}
		else
		{
			snprintf( pcWriteBuffer, xWriteBufferLen, "Failed to allocate RAM (using heap_4.c will prevent fragmentation)." );
		}
	}
	else
	{
		/* The find struct has already been created.  Find the next file in
		the directory. */
		iReturned = ff_findnext( pxFindStruct );

		if( iReturned == FF_ERR_NONE )
		{
			prvCreateFileInfoString( pcWriteBuffer, pxFindStruct );
			xReturn = pdPASS;
		}
		else
		{
			vPortFree( pxFindStruct );
			pxFindStruct = NULL;

			/* No string to return. */
			pcWriteBuffer[ 0 ] = 0x00;
		}
	}

	strcat( pcWriteBuffer, cliNEW_LINE );

	return xReturn;
}

static BaseType_t prvCDCommand( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString )
{
const char *pcParameter;
BaseType_t xParameterStringLength;
int iReturned;
size_t xStringLength;

	/* Obtain the parameter string. */
	pcParameter = FreeRTOS_CLIGetParameter
					(
						pcCommandString,		/* The command string itself. */
						1,						/* Return the first parameter. */
						&xParameterStringLength	/* Store the parameter string length. */
					);

	/* Sanity check something was returned. */
	configASSERT( pcParameter );

	/* Attempt to move to the requested directory. */
	iReturned = ff_chdir( pcParameter );

	if( iReturned == FF_ERR_NONE )
	{
		sprintf( pcWriteBuffer, "In: " );
		xStringLength = strlen( pcWriteBuffer );
		ff_getcwd( &( pcWriteBuffer[ xStringLength ] ), ( unsigned char ) ( xWriteBufferLen - xStringLength ) );
	}
	else
	{
		sprintf( pcWriteBuffer, "Error" );
	}

	strcat( pcWriteBuffer, cliNEW_LINE );

	return pdFALSE;
}

static BaseType_t prvTYPECommand( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString )
{
const char *pcParameter;
BaseType_t xParameterStringLength, xReturn = pdTRUE;
static FF_FILE *pxFile = NULL;
int iChar;
size_t xByte;
size_t xColumns = 50U;

	/* Ensure there is always a null terminator after each character written. */
	memset( pcWriteBuffer, 0x00, xWriteBufferLen );

	/* Ensure the buffer leaves space for the \r\n. */
	configASSERT( xWriteBufferLen > ( strlen( cliNEW_LINE ) * 2 ) );
	xWriteBufferLen -= strlen( cliNEW_LINE );
	xColumns = xWriteBufferLen - 1;
//	if( xWriteBufferLen < xColumns )
//	{
//		/* Ensure the loop that uses xColumns as an end condition does not
//		write off the end of the buffer. */
//		xColumns = xWriteBufferLen;
//	}

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
	}

	if( pxFile != NULL )
	{
		/* Read the next chunk of data from the file. */
		for( xByte = 0; xByte < xColumns; xByte++ )
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
				pcWriteBuffer[ xByte ] = ( char ) iChar;
			}
		}
	}

	if( pxFile == NULL )
	{
		/* Either the file was not opened, or all the data from the file has
		been returned and the file is now closed. */
		xReturn = pdFALSE;
	}

	strcat( pcWriteBuffer, cliNEW_LINE );

	return xReturn;
}

static BaseType_t prvPWDCommand( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString )
{
	( void ) pcCommandString;

	/* Copy the current working directory into the output buffer. */
	ff_getcwd( pcWriteBuffer, xWriteBufferLen );
	return pdFALSE;
}