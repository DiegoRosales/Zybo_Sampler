
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
static BaseType_t prv_xMIDIKeyPlayASCIICMD( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString );
static uint32_t   prv_ulStrToInt( const char *input_string, BaseType_t input_string_length );


///////////////////////////////////////
// Command Definition Structure
///////////////////////////////////////
// >> midi_ascii <COMMAND> <DATA_BYTE_1> [<DATA_BYTE_2>]
static const CLI_Command_Definition_t prv_xMIDIKeyPlayASCIICMD_definition =
{
    "midi_ascii", /* The command string to type. */
    "\r\nmidi_ascii <COMMAND> <DATA_BYTE_1> [<DATA_BYTE_2>]:\r\n Executes a MIDI command\n\r",
    prv_xMIDIKeyPlayASCIICMD, /* The function to run. */
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
void vRegisterMIDIKeyPlayASCIICMD( void ) {

  // Queue handlers to send data between the Commands and the Tasks
  xFilenameQueueHandler  = xQueueCreate(1, sizeof(file_path_handler_t));
  xReturnQueueHandler    = xQueueCreate(1, sizeof(uint32_t));
  xKeyParamsQueueHandler = xQueueCreate(1, sizeof(uint32_t));

  FreeRTOS_CLIRegisterCommand( &prv_xMIDIKeyPlayASCIICMD_definition );
}

///////////////////////////////////////
// Actual Command Implementation
///////////////////////////////////////
static BaseType_t prv_xMIDIKeyPlayASCIICMD( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString ) {

    const char *command = NULL;
    const char *byte1   = NULL;
    const char *byte2   = NULL;

    uint8_t command_int = 0;
    uint8_t byte1_int   = 0;
    uint8_t byte2_int   = 0;

    uint32_t full_cmd = 0;

    BaseType_t xParameter1StringLength;
    BaseType_t xParameter2StringLength;
    BaseType_t xParameter3StringLength;


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
                        &xParameter3StringLength	/* Store the parameter string length. */
                    );

    // We need at least 2 parameters
    if( command == NULL || byte1 == NULL ) return pdFALSE;

    /////////////////////////////////////////////
    // String to int
    /////////////////////////////////////////////

    command_int = prv_ulStrToInt( command, xParameter1StringLength );
    byte1_int   = prv_ulStrToInt( byte1,   xParameter2StringLength );
    if ( byte2 != NULL ) byte2_int = prv_ulStrToInt( byte2,   xParameter3StringLength );

    full_cmd  = command_int;
    full_cmd |= byte1_int << 8;
    if ( byte2 != NULL ) full_cmd |= byte2_int << 16;

    // Wake up the task and send the full MIDI command the parameters
    xTaskNotify( run_midi_cmd_task_handle,
                 full_cmd,
                 eSetValueWithOverwrite );

    // Don't wait for any feedback
    return pdFALSE;

}

///////////////////////////////////////
// Misc Private Functions
///////////////////////////////////////
// This function converts an string in int or hex to a uint32_t
static uint32_t prv_ulStrToInt( const char *input_string, BaseType_t input_string_length ) {

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