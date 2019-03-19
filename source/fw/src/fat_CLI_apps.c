

// C includes
#include <string.h>

// FreeRTOS Includes
#include "FreeRTOS.h"
#include "task.h"
#include "FreeRTOS_CLI.h"

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

////////////////////////////////////////////////////////
// Functions
////////////////////////////////////////////////////////

// This function registers all the CLI applications
void register_fat_cli_commands( void ) {
    FreeRTOS_CLIRegisterCommand( &sd_initialization_command_definition );
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
