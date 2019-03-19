

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

////////////////////////////////////////////////////////
// Functions
////////////////////////////////////////////////////////

// This function registers all the CLI applications
void register_fat_cli_commands( void ) {
    FreeRTOS_CLIRegisterCommand( &sd_initialization_command_definition );
    FreeRTOS_CLIRegisterCommand( &xDIR );
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