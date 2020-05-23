
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
static BaseType_t prv_xPlayKeyCMD( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString );
static uint32_t   prv_ulStrToInt( const char *input_string, BaseType_t input_string_length );


///////////////////////////////////////
// Command Definition Structure
///////////////////////////////////////
// >> play_key <KEY> <VELOCITY>
static const CLI_Command_Definition_t prv_xPlayKeyCMD_definition =
{
    "play_key",                                                       /* The command string to type. */
    "\r\nplay_key <KEY> <VELOCITY>:\r\n Starts the key playback\n\r", /* Help */
    prv_xPlayKeyCMD,                                                  /* The function to run. */
    2                                                                 /* 2 parameters are expected. */
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
void vRegisterPlayKeyCMD( void ) {

  // Queue handlers to send data between the Commands and the Tasks
  xFilenameQueueHandler  = xQueueCreate(1, sizeof(file_path_handler_t));
  xReturnQueueHandler    = xQueueCreate(1, sizeof(uint32_t));
  xKeyParamsQueueHandler = xQueueCreate(1, sizeof(uint32_t));

  FreeRTOS_CLIRegisterCommand( &prv_xPlayKeyCMD_definition );
}

///////////////////////////////////////
// Actual Command Implementation
///////////////////////////////////////
static BaseType_t prv_xPlayKeyCMD( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString ) {

    const char *key;
    const char *velocity;

    BaseType_t xParameter1StringLength;
    BaseType_t xParameter2StringLength;

    // Variables for the key playback task
    TaskHandle_t     key_playback_task_handle = xTaskGetHandle( KEY_PLAYBACK_TASK_NAME );
    key_parameters_t key_parameters;

    // First parameter
    key = FreeRTOS_CLIGetParameter
                    (
                        pcCommandString,		/* The command string itself. */
                        1,						/* Return the first parameter. */
                        &xParameter1StringLength	/* Store the parameter string length. */
                    );

    // Second Parameter
    velocity = FreeRTOS_CLIGetParameter
                    (
                        pcCommandString,		/* The command string itself. */
                        2,						/* Return the first parameter. */
                        &xParameter2StringLength	/* Store the parameter string length. */
                    );


    if ( ( xParameter1StringLength != 2 ) && ( xParameter1StringLength != 4 ) ) {
        SAMPLER_PRINTF_ERROR("Incorrect key format.\n\rExample 1: f2\n\rExample 2: a5_s");
        return pdFALSE;
    }

    // Get the Key number and the velocity in uint8_t form
    key_parameters.key      = usGetMIDINoteNumber( key );
    key_parameters.velocity = prv_ulStrToInt( velocity, xParameter2StringLength );

    SAMPLER_PRINTF_INFO("Playing back Key %d, Velocity: %d", key_parameters.key, key_parameters.velocity);


    xQueueSend(xKeyParamsQueueHandler, &key_parameters , 1000);

    // Wake up the task and send the queue handler of the parameters
    xTaskNotify( key_playback_task_handle,
                 (uint32_t) xKeyParamsQueueHandler,
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