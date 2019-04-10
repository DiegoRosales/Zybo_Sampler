#ifndef SAMPLER_FREERTOS_TASKS_H
#define SAMPLER_FREERTOS_TASKS_H

#include "queue.h"
#include "sampler.h"

#define cliNEW_LINE "\n\r"

#define LOAD_INSTRUMENT_TASK_NAME "load_instrument"
#define MAX_PATH_LEN               100

typedef struct {
    char file_path[MAX_PATH_LEN];
    char file_dir[MAX_PATH_LEN];
    xQueueHandle return_handle;
} file_path_t;

uint32_t load_file_to_memory( char * file_name, uint8_t *buffer, uint32_t buffer_len );
uint32_t load_file_to_memory_malloc( char *file_name, uint8_t *buffer, uint32_t buffer_len );
void file_to_buffer( FF_FILE *pxFile, uint8_t *buffer, uint32_t buffer_len );
void notification_test_task( void *pvParameters );
void load_instrument_task( void *pvParameters );

#endif
