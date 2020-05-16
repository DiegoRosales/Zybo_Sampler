#ifndef __PATCH_LOADER_H__
#define __PATCH_LOADER_H__

#include "jsmn.h"
#include "riff_utils.h"
#include "sampler_cfg.h"

typedef struct {
    char file_path[MAX_PATH_LEN];
    char file_dir[MAX_PATH_LEN];
} file_path_t;

PATCH_DESCRIPTOR_t * ulLoadPatchFromJSON( const char * json_file_dirname, const char * json_file_fullpath);
PATCH_DESCRIPTOR_t * ulLoadPatchFromSF3( const char * sf3_file_fullpath );

#endif
