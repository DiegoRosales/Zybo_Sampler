

#ifndef FAT_CLI_APPS_H
#define FAT_CLI_APPS_H

// Debug level
#ifndef SD_DEBUG
#define SD_DEBUG 0
#endif

#ifndef SD_PRINTF
    #define SD_PRINTF xil_printf
#endif

#if defined(SD_DEBUG) 
  #if SD_DEBUG >= 3
    #define SD_PRINTF_INFO(fmt, args...)    SD_PRINTF("[SD_INFO]    : %s:%d:%s(): " fmt "\n\r", __FILE__, __LINE__, __func__, ##args)
    #define SD_PRINTF_WARNING(fmt, args...) SD_PRINTF("[SD_WARNING] : %s:%d:%s(): " fmt "\n\r", __FILE__, __LINE__, __func__, ##args)
    #define SD_PRINTF_ERROR(fmt, args...)   SD_PRINTF("[SD_ERROR]   : %s:%d:%s(): " fmt "\n\r", __FILE__, __LINE__, __func__, ##args)
    #define SD_PRINTF_DEBUG(fmt, args...)   SD_PRINTF("[SD_DEBUG]   : %s:%d:%s(): " fmt "\n\r", __FILE__, __LINE__, __func__, ##args)
  #elif SD_DEBUG == 2
    #define SD_PRINTF_INFO(fmt, args...)    SD_PRINTF("[SD_INFO]    : "             fmt "\n\r", ##args)
    #define SD_PRINTF_WARNING(fmt, args...) SD_PRINTF("[SD_WARNING] : "             fmt "\n\r", ##args)
    #define SD_PRINTF_ERROR(fmt, args...)   SD_PRINTF("[SD_ERROR]   : %s:%d:%s(): " fmt "\n\r", __FILE__, __LINE__, __func__, ##args)
    #define SD_PRINTF_DEBUG(fmt, args...)   SD_PRINTF("[SD_DEBUG]   : %s:%d:%s(): " fmt "\n\r", __FILE__, __LINE__, __func__, ##args)
  #elif SD_DEBUG == 1
    #define SD_PRINTF_INFO(fmt, args...)    SD_PRINTF("[SD_INFO]    : " fmt "\n\r", ##args)
    #define SD_PRINTF_WARNING(fmt, args...) SD_PRINTF("[SD_WARNING] : " fmt "\n\r", ##args)
    #define SD_PRINTF_ERROR(fmt, args...)   SD_PRINTF("[SD_ERROR]   : " fmt "\n\r", ##args)
    #define SD_PRINTF_DEBUG(fmt, args...)   SD_PRINTF("[SD_DEBUG]   : " fmt "\n\r", ##args)
  #else
    #define SD_PRINTF_INFO(fmt, args...)    SD_PRINTF("[INFO]    : " fmt "\n\r", ##args)
    #define SD_PRINTF_WARNING(fmt, args...) SD_PRINTF("[WARNING] : " fmt "\n\r", ##args)
    #define SD_PRINTF_ERROR(fmt, args...)   SD_PRINTF("[ERROR]   : " fmt "\n\r", ##args)
    #define SD_PRINTF_DEBUG(fmt, args...)   /* Nothing */
  #endif
#else
    #define SD_PRINTF_INFO(fmt, args...)    SD_PRINTF("[INFO]    : " fmt "\n\r", ##args)
    #define SD_PRINTF_WARNING(fmt, args...) SD_PRINTF("[WARNING] : " fmt "\n\r", ##args)
    #define SD_PRINTF_ERROR(fmt, args...)   SD_PRINTF("[ERROR]   : " fmt "\n\r", ##args)
    #define SD_PRINTF_DEBUG(fmt, args...)   /* Nothing */
#endif

#define mainSD_CARD_DISK_NAME "/"
#define cliNEW_LINE "\n\r"

size_t load_file_to_memory( const char * file_name, uint8_t *buffer, size_t buffer_len );
size_t load_file_to_memory_malloc( const char *file_name, uint8_t ** buffer, size_t max_buffer_len, size_t overhead );
void   unload_file_from_memory( uint8_t * buffer );
void   register_fat_cli_commands( void );

#endif
