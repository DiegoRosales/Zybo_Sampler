
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
static BaseType_t prv_xStopAllPlaybackCMD( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString );


///////////////////////////////////////
// Command Definition Structure
///////////////////////////////////////
// >> stop_all <KEY> <VELOCITY>
static const CLI_Command_Definition_t prv_xStopAllPlaybackCMD_definition =
{
    "stop_all", /* The command string to type. */
    "\r\nstop_all <KEY> <VELOCITY>:\r\n Stops all playback\n\r",
    prv_xStopAllPlaybackCMD, /* The function to run. */
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
void vRegisterStopAllPlaybackCMD( void ) {

  // Queue handlers to send data between the Commands and the Tasks
  xFilenameQueueHandler  = xQueueCreate(1, sizeof(file_path_handler_t));
  xReturnQueueHandler    = xQueueCreate(1, sizeof(uint32_t));
  xKeyParamsQueueHandler = xQueueCreate(1, sizeof(uint32_t));

  FreeRTOS_CLIRegisterCommand( &prv_xStopAllPlaybackCMD_definition );
}

///////////////////////////////////////
// Actual Command Implementation
///////////////////////////////////////
static BaseType_t prv_xStopAllPlaybackCMD( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString ) {

    // Variables for the key playback task
    TaskHandle_t     stop_all_task_handle = xTaskGetHandle( STOP_ALL_TASK_NAME );

    // Wake up the task and send the queue handler of the parameters
    xTaskNotify( stop_all_task_handle,
                 0,
                 eSetValueWithOverwrite );


    vTaskDelay( 100 );

    // Don't wait for any feedback
    return pdFALSE;

}
