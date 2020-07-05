
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

// FreeRTOS+FAT Includes
#include "ff_stdio.h"

// Sampler Includes
#include "sampler_CLI_apps.h"
#include "sampler_FreeRTOS_tasks.h"
#include "sampler_dma_voice_pb.h"
#include "sampler_engine.h"
#include "nco.h"

///////////////////////////////////////
// Static Functions
///////////////////////////////////////
static BaseType_t prv_xPrintSF2InfoCMD( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString );
static void       ff_get_file_dir ( const char *file_path, char* dest );

///////////////////////////////////////
// Command Definition Structure
///////////////////////////////////////
// >> print_sf2_info <FILENAME>
static const CLI_Command_Definition_t prv_xPrintSF2InfoCMD_definition =
{
    "print_sf2_info", /* The command string to type. */
    "\r\nprint_sf2_info <FILENAME>:\r\n Prints the information of a specified SF2 file\r\n",
    prv_xPrintSF2InfoCMD, /* The function to run. */
    1 /* 1 parameter is expected. */
};

///////////////////////////////////////
// Misc. Variables
///////////////////////////////////////

// Queue handlers to send data between the Commands and the Tasks
static xQueueHandle xFilenameQueueHandler;
static xQueueHandle xReturnQueueHandler;
static xQueueHandle xKeyParamsQueueHandler;

///////////////////////////////////////
// Function to register the command
///////////////////////////////////////
void vRegisterPrintSF2InfoCMD( void ) {

  // Queue handlers to send data between the Commands and the Tasks
  xFilenameQueueHandler  = xQueueCreate(1, sizeof(file_path_handler_t));
  xReturnQueueHandler    = xQueueCreate(1, sizeof(uint32_t));
  xKeyParamsQueueHandler = xQueueCreate(1, sizeof(uint32_t));

  FreeRTOS_CLIRegisterCommand( &prv_xPrintSF2InfoCMD_definition );
}

///////////////////////////////////////
// Actual Command Implementation
///////////////////////////////////////
static BaseType_t prv_xPrintSF2InfoCMD( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString ) {
    
    const char *pcParameter;

    // Variables for the CLI Parameter Parser
    BaseType_t   xParameterStringLength;

    // Variables for the sf2 loader task
    TaskHandle_t         task_handle  = xTaskGetHandle( PRINT_SF2_INFO_TASK_NAME );
    uint32_t             return_value = 1;
    uint32_t             cwd_path_len = 0;
    file_path_handler_t  my_file_path_handler;

    /* The file has not been opened yet.  Find the file name. */
    pcParameter = FreeRTOS_CLIGetParameter
                    (
                        pcCommandString,		/* The command string itself. */
                        1,						/* Return the first parameter. */
                        &xParameterStringLength	/* Store the parameter string length. */
                    );

    /* Sanity check something was returned. */
    configASSERT( pcParameter );

    configASSERT( ! (xParameterStringLength > MAX_PATH_LEN) );

    // Initialize the path
    memset( my_file_path_handler.file_path, 0x00, MAX_PATH_LEN );
    memset( my_file_path_handler.file_dir, 0x00, MAX_PATH_LEN );

    // Copy the Path
    // 1 - Get the current directory
    ff_getcwd( my_file_path_handler.file_dir, MAX_PATH_LEN );
    SAMPLER_PRINTF_DEBUG("CWD: %s", my_file_path_handler.file_dir);

    // Sanity check - Check if the path is less than the maximum allowable
    cwd_path_len = strlen( my_file_path_handler.file_dir );
    configASSERT( ! ( (cwd_path_len + xParameterStringLength + 1) > MAX_PATH_LEN) );

    // 2 - Assemble the full path
    // If you're in the root, append the path as is
    if ( strcmp( my_file_path_handler.file_dir, (const char *)"/" ) == 0 ) {
       // If the path is a full path (i.e. referenced from the root), copy as is
        if ( pcParameter[0] == '/' ) {
            sprintf(my_file_path_handler.file_path, "%s", pcParameter);
        } else { // If it's a relative directory, prepend the root slash
            strcat( my_file_path_handler.file_path, "/");
        }
        ff_get_file_dir( pcParameter, my_file_path_handler.file_dir );
        //strncat( my_file_path_handler.file_path, my_file_path_handler.file_dir, STRLEN( my_file_path_handler.file_dir ) );
        strncat( my_file_path_handler.file_path, pcParameter, xParameterStringLength ); 
    } else {
        // If the path is a full path (i.e. referenced from the root), copy as is
        if ( pcParameter[0] == '/' ) {
            sprintf(my_file_path_handler.file_path, "%s", pcParameter);
        } else { // If it's a relative path, prepend the current directory
            strncat( my_file_path_handler.file_path, my_file_path_handler.file_dir, cwd_path_len);
            strcat( my_file_path_handler.file_path, "/");
            strncat( my_file_path_handler.file_path, pcParameter, xParameterStringLength );
        }
    }

    SAMPLER_PRINTF_DEBUG("File Path: %s", my_file_path_handler.file_path);

    my_file_path_handler.return_handle = xReturnQueueHandler;

    // Send the filename to the task
    xQueueSend(xFilenameQueueHandler, &my_file_path_handler , 1000);

    xTaskNotify(    task_handle,
                    (uint32_t) xFilenameQueueHandler,
                    eSetValueWithOverwrite );

    if( ! xQueueReceive(xReturnQueueHandler, &return_value, 20000) ) {
        SAMPLER_PRINTF_ERROR("Error receiving the Queue!");
    }
    else {
        SAMPLER_PRINTF("Done! Return Value = %d\n\r", return_value);
    }

    return pdFALSE;

}

///////////////////////////////////////
// Misc Private Functions
///////////////////////////////////////
// This function gets the directory of a given file
static void ff_get_file_dir ( const char *file_path, char* dest ) {
    size_t path_len = strlen( file_path );
    char     current_char = '\00';
    uint32_t last_slash = 0;

    for ( int i = 0; i < path_len ; i++ ) {
    	current_char = file_path[i];
        if ( current_char == '/' ) last_slash = i;
    }

    strncat( dest, file_path, last_slash );
}
