#ifndef SAMPLER_FREERTOS_TASKS_H
#define SAMPLER_FREERTOS_TASKS_H

#include "queue.h"
#include "sampler_cfg.h"

#define cliNEW_LINE "\n\r"

// Task names
#define STOP_ALL_TASK_NAME                  "stop_all"
#define KEY_PLAYBACK_TASK_NAME              "key_playback"
#define LOAD_INSTRUMENT_TASK_NAME           "load_instrument"
#define LOAD_SF2_TASK_NAME                  "load_sf2"
#define PRINT_SF2_INFO_TASK_NAME            "print_sf2_info"
#define RUN_MIDI_CMD_TASK_NAME              "run_midi_cmd"
#define SERIAL_MIDI_LISTENER_TASK_TASK_NAME "serial_midi_listener_task"

typedef struct {
    char file_path[MAX_PATH_LEN];
    char file_dir[MAX_PATH_LEN];
    xQueueHandle return_handle;
} file_path_handler_t;

typedef struct {
    uint8_t key;
    uint8_t velocity;
} key_parameters_t;

void vRegisterSamplerEngineTasks ( void );

#endif
