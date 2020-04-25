#ifndef SAMPLER_FREERTOS_TASKS_H
#define SAMPLER_FREERTOS_TASKS_H

#include "queue.h"
#include "sampler.h"

#define cliNEW_LINE "\n\r"

#define LOAD_INSTRUMENT_TASK_NAME      "load_instrument"
#define KEY_PLAYBACK_TASK_NAME         "key_playback"
#define STOP_ALL_TASK_NAME             "stop_all"
#define RUN_MIDI_CMD_TASK_NAME         "run_midi_cmd"
#define SERIAL_MIDI_LISTENER_TASK_NAME "serial_midi_listener_task"
#define MAX_PATH_LEN                   100

typedef struct {
    char file_path[MAX_PATH_LEN];
    char file_dir[MAX_PATH_LEN];
    xQueueHandle return_handle;
} file_path_t;

typedef struct {
    uint8_t key;
    uint8_t velocity;
} key_parameters_t;

uint32_t load_samples_into_memory( INSTRUMENT_INFORMATION_t *instrument_information, char *json_file_root_dir );
void create_sampler_tasks ( void );

#endif
