#ifndef __PATCH_LOADER_H__
#define __PATCH_LOADER_H__

#include "jsmn.h"
#include "riff_utils.h"
#include "sampler_cfg.h"

// Debug level
#ifndef PATCH_LOADER_DEBUG
  #define PATCH_LOADER_DEBUG 1
#endif

#ifndef PATCH_LOADER_PRINTF
    #define PATCH_LOADER_PRINTF xil_printf
#endif

#if defined(PATCH_LOADER_DEBUG) 
  #if PATCH_LOADER_DEBUG >= 3
    #define PATCH_LOADER_PRINTF_INFO(fmt, args...)    PATCH_LOADER_PRINTF("[PATCH_LOADER][INFO]    : %s:%d:%s(): " fmt "\n\r", __FILE__, __LINE__, __func__, ##args)
    #define PATCH_LOADER_PRINTF_WARNING(fmt, args...) PATCH_LOADER_PRINTF("[PATCH_LOADER][WARNING] : %s:%d:%s(): " fmt "\n\r", __FILE__, __LINE__, __func__, ##args)
    #define PATCH_LOADER_PRINTF_ERROR(fmt, args...)   PATCH_LOADER_PRINTF("[PATCH_LOADER][ERROR]   : %s:%d:%s(): " fmt "\n\r", __FILE__, __LINE__, __func__, ##args)
    #define PATCH_LOADER_PRINTF_DEBUG(fmt, args...)   PATCH_LOADER_PRINTF("[PATCH_LOADER][DEBUG]   : %s:%d:%s(): " fmt "\n\r", __FILE__, __LINE__, __func__, ##args)
  #elif PATCH_LOADER_DEBUG == 2
    #define PATCH_LOADER_PRINTF_INFO(fmt, args...)    PATCH_LOADER_PRINTF("[PATCH_LOADER][INFO]    : "             fmt "\n\r", ##args)
    #define PATCH_LOADER_PRINTF_WARNING(fmt, args...) PATCH_LOADER_PRINTF("[PATCH_LOADER][WARNING] : "             fmt "\n\r", ##args)
    #define PATCH_LOADER_PRINTF_ERROR(fmt, args...)   PATCH_LOADER_PRINTF("[PATCH_LOADER][ERROR]   : %s:%d:%s(): " fmt "\n\r", __FILE__, __LINE__, __func__, ##args)
    #define PATCH_LOADER_PRINTF_DEBUG(fmt, args...)   PATCH_LOADER_PRINTF("[PATCH_LOADER][DEBUG]   : %s:%d:%s(): " fmt "\n\r", __FILE__, __LINE__, __func__, ##args)
  #elif PATCH_LOADER_DEBUG == 1
    #define PATCH_LOADER_PRINTF_INFO(fmt, args...)    PATCH_LOADER_PRINTF("[PATCH_LOADER][INFO]    : " fmt "\n\r", ##args)
    #define PATCH_LOADER_PRINTF_WARNING(fmt, args...) PATCH_LOADER_PRINTF("[PATCH_LOADER][WARNING] : " fmt "\n\r", ##args)
    #define PATCH_LOADER_PRINTF_ERROR(fmt, args...)   PATCH_LOADER_PRINTF("[PATCH_LOADER][ERROR]   : " fmt "\n\r", ##args)
    #define PATCH_LOADER_PRINTF_DEBUG(fmt, args...)   PATCH_LOADER_PRINTF("[PATCH_LOADER][DEBUG]   : " fmt "\n\r", ##args)
  #else
    #define PATCH_LOADER_PRINTF_INFO(fmt, args...)    PATCH_LOADER_PRINTF("[PATCH_LOADER][INFO]    : " fmt "\n\r", ##args)
    #define PATCH_LOADER_PRINTF_WARNING(fmt, args...) PATCH_LOADER_PRINTF("[PATCH_LOADER][WARNING] : " fmt "\n\r", ##args)
    #define PATCH_LOADER_PRINTF_ERROR(fmt, args...)   PATCH_LOADER_PRINTF("[PATCH_LOADER][ERROR]   : " fmt "\n\r", ##args)
    #define PATCH_LOADER_PRINTF_DEBUG(fmt, args...)   /* Nothing */
  #endif
#else
    #define PATCH_LOADER_PRINTF_INFO(fmt, args...)    PATCH_LOADER_PRINTF("[INFO]    : " fmt "\n\r", ##args)
    #define PATCH_LOADER_PRINTF_WARNING(fmt, args...) PATCH_LOADER_PRINTF("[WARNING] : " fmt "\n\r", ##args)
    #define PATCH_LOADER_PRINTF_ERROR(fmt, args...)   PATCH_LOADER_PRINTF("[ERROR]   : " fmt "\n\r", ##args)
    #define PATCH_LOADER_PRINTF_DEBUG(fmt, args...)   /* Nothing */
#endif

typedef struct {
    char file_path[MAX_PATH_LEN];
    char file_dir[MAX_PATH_LEN];
} file_path_t;

PATCH_DESCRIPTOR_t * ulLoadPatchFromJSON( const char * json_file_dirname, const char * json_file_fullpath);
PATCH_DESCRIPTOR_t * ulLoadPatchFromSF2( const char * sf2_file_fullpath );
void                 vPrintSF2FileInfo( const char * sf2_file_fullpath );

#endif
