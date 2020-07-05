
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
static BaseType_t prv_xStartMIDIListenerCMD( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString );


///////////////////////////////////////
// Command Definition Structure
///////////////////////////////////////
// >> start_serial_midi_listener
static const CLI_Command_Definition_t prv_xStartMIDIListenerCMD_definition =
{
    "start_serial_midi_listener", /* The command string to type. */
    "\r\nstart_serial_midi_listener\n\r Starts the MIDI Serial listener\r\n",
    prv_xStartMIDIListenerCMD, /* The function to run. */
    0 /* 0 parameters are expected. */
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
void vRegisterStartMIDIListenerCMD( void ) {

  // Queue handlers to send data between the Commands and the Tasks
  xFilenameQueueHandler  = xQueueCreate(1, sizeof(file_path_handler_t));
  xReturnQueueHandler    = xQueueCreate(1, sizeof(uint32_t));
  xKeyParamsQueueHandler = xQueueCreate(1, sizeof(uint32_t));

  FreeRTOS_CLIRegisterCommand( &prv_xStartMIDIListenerCMD_definition );
}

///////////////////////////////////////
// Actual Command Implementation
///////////////////////////////////////
static BaseType_t prv_xStartMIDIListenerCMD( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString ) {

	uint32_t return_value = 1;

    // Variables for the key playback task
    TaskHandle_t     serial_midi_listener_task_handler = xTaskGetHandle( SERIAL_MIDI_LISTENER_TASK_TASK_NAME );

    // Wake up the task and send the full MIDI command the parameters
    xTaskNotify( serial_midi_listener_task_handler,
                 (uint32_t) xReturnQueueHandler,
                 eSetValueWithOverwrite );


    if( ! xQueueReceive(xReturnQueueHandler, &return_value, 10000) ) {
        SAMPLER_PRINTF_ERROR("Timeout!");
    }
    else {
        SAMPLER_PRINTF("Done! Return Value = %d\n\r", return_value);
    }

    // Don't wait for any feedback
    return pdFALSE;

}
