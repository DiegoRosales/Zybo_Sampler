#ifndef __PATCH_LOADER_H__
#define __PATCH_LOADER_H__

#include "jsmn.h"
#include "riff_utils.h"
#include "sampler_cfg.h"

typedef struct {
    char file_path[MAX_PATH_LEN];
    char file_dir[MAX_PATH_LEN];
} file_path_t;

uint32_t ulLoadPatchFromJSON( const char * json_file_dirname, const char * json_file_fullpath, PATCH_DESCRIPTOR_t * patch_descriptor );
uint32_t ulDecodeJSON_PatchInfo( uint8_t *json_patch_information_buffer, PATCH_DESCRIPTOR_t *patch_descriptor );
uint32_t ulLoadSamplesFromDescriptor( PATCH_DESCRIPTOR_t *patch_descriptor, const char *json_file_root_dir );
uint32_t ulConfigDMADataStructure( PATCH_DESCRIPTOR_t *patch_descriptor );

#endif
