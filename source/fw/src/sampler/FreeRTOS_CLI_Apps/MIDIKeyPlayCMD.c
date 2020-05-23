
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

// Sampler Includes
#include "sampler_CLI_apps.h"
#include "sampler_FreeRTOS_tasks.h"
#include "sampler_dma_voice_pb.h"
#include "sampler_engine.h"
#include "nco.h"

///////////////////////////////////////
// Static Functions
///////////////////////////////////////
static BaseType_t prv_xMIDIKeyPlayCMD( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString );


///////////////////////////////////////
// Command Definition Structure
///////////////////////////////////////
// >> midi <COMMAND> <DATA_BYTE_1> [<DATA_BYTE_2>]
static const CLI_Command_Definition_t prv_xMIDIKeyPlayCMD_definition =
{
    "midi", /* The command string to type. */
    "\r\nmidi <COMMAND> <DATA_BYTE_1> [<DATA_BYTE_2>]:\r\n Executes a MIDI command. This is intended to use with a bridge since all the arguments are sent in raw binary, not ASCII\n\r",
    prv_xMIDIKeyPlayCMD, /* The function to run. */
    -1 /* 2 - 3 parameters. */
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
void vRegisterMIDIKeyPlayCMD( void ) {

  // Queue handlers to send data between the Commands and the Tasks
  xFilenameQueueHandler  = xQueueCreate(1, sizeof(file_path_handler_t));
  xReturnQueueHandler    = xQueueCreate(1, sizeof(uint32_t));
  xKeyParamsQueueHandler = xQueueCreate(1, sizeof(uint32_t));

  FreeRTOS_CLIRegisterCommand( &prv_xMIDIKeyPlayCMD_definition );
}

///////////////////////////////////////
// Actual Command Implementation
///////////////////////////////////////
static BaseType_t prv_xMIDIKeyPlayCMD( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString ) {

    const char *command = NULL;
    const char *byte1   = NULL;
    const char *byte2   = NULL;

    uint32_t full_cmd = 0;

    BaseType_t xParameter1StringLength;
    BaseType_t xParameter2StringLength;

    // Variables for the key playback task
    TaskHandle_t     run_midi_cmd_task_handle = xTaskGetHandle( RUN_MIDI_CMD_TASK_NAME );

    // First parameter
    command = FreeRTOS_CLIGetParameter
                    (
                        pcCommandString,		/* The command string itself. */
                        1,						/* Return the first parameter. */
                        &xParameter1StringLength	/* Store the parameter string length. */
                    );

    // Second Parameter
    byte1 = FreeRTOS_CLIGetParameter
                    (
                        pcCommandString,		/* The command string itself. */
                        2,						/* Return the first parameter. */
                        &xParameter2StringLength	/* Store the parameter string length. */
                    );

    // Second Parameter
    byte2 = FreeRTOS_CLIGetParameter
                    (
                        pcCommandString,		/* The command string itself. */
                        3,						/* Return the first parameter. */
                        &xParameter2StringLength	/* Store the parameter string length. */
                    );

    // We need at least 2 parameters
    if( command == NULL || byte1 == NULL ) return pdFALSE;

    full_cmd  = *command;
    full_cmd |= *byte1 << 8;
    if ( byte2 != NULL ) full_cmd |= *byte2 << 16;

    // Wake up the task and send the full MIDI command the parameters
    xTaskNotify( run_midi_cmd_task_handle,
                 full_cmd,
                 eSetValueWithOverwrite );

    // Don't wait for any feedback
    return pdFALSE;

}
