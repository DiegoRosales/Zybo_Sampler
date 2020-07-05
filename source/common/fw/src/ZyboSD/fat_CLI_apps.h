

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
    #define SD_PRINTF_INFO(fmt, args...)    SD_PRINTF("[SD][INFO]    : %s:%d:%s(): " fmt "\n\r", __FILE__, __LINE__, __func__, ##args)
    #define SD_PRINTF_WARNING(fmt, args...) SD_PRINTF("[SD][WARNING] : %s:%d:%s(): " fmt "\n\r", __FILE__, __LINE__, __func__, ##args)
    #define SD_PRINTF_ERROR(fmt, args...)   SD_PRINTF("[SD][ERROR]   : %s:%d:%s(): " fmt "\n\r", __FILE__, __LINE__, __func__, ##args)
    #define SD_PRINTF_DEBUG(fmt, args...)   SD_PRINTF("[SD][DEBUG]   : %s:%d:%s(): " fmt "\n\r", __FILE__, __LINE__, __func__, ##args)
  #elif SD_DEBUG == 2
    #define SD_PRINTF_INFO(fmt, args...)    SD_PRINTF("[SD][INFO]    : "             fmt "\n\r", ##args)
    #define SD_PRINTF_WARNING(fmt, args...) SD_PRINTF("[SD][WARNING] : "             fmt "\n\r", ##args)
    #define SD_PRINTF_ERROR(fmt, args...)   SD_PRINTF("[SD][ERROR]   : %s:%d:%s(): " fmt "\n\r", __FILE__, __LINE__, __func__, ##args)
    #define SD_PRINTF_DEBUG(fmt, args...)   SD_PRINTF("[SD][DEBUG]   : %s:%d:%s(): " fmt "\n\r", __FILE__, __LINE__, __func__, ##args)
  #elif SD_DEBUG == 1
    #define SD_PRINTF_INFO(fmt, args...)    SD_PRINTF("[SD][INFO]    : " fmt "\n\r", ##args)
    #define SD_PRINTF_WARNING(fmt, args...) SD_PRINTF("[SD][WARNING] : " fmt "\n\r", ##args)
    #define SD_PRINTF_ERROR(fmt, args...)   SD_PRINTF("[SD][ERROR]   : " fmt "\n\r", ##args)
    #define SD_PRINTF_DEBUG(fmt, args...)   SD_PRINTF("[SD][DEBUG]   : " fmt "\n\r", ##args)
  #else
    #define SD_PRINTF_INFO(fmt, args...)    SD_PRINTF("[SD][INFO]    : " fmt "\n\r", ##args)
    #define SD_PRINTF_WARNING(fmt, args...) SD_PRINTF("[SD][WARNING] : " fmt "\n\r", ##args)
    #define SD_PRINTF_ERROR(fmt, args...)   SD_PRINTF("[SD][ERROR]   : " fmt "\n\r", ##args)
    #define SD_PRINTF_DEBUG(fmt, args...)   /* Nothing */
  #endif
#else
    #define SD_PRINTF_INFO(fmt, args...)    SD_PRINTF("[SD][INFO]    : " fmt "\n\r", ##args)
    #define SD_PRINTF_WARNING(fmt, args...) SD_PRINTF("[SD][WARNING] : " fmt "\n\r", ##args)
    #define SD_PRINTF_ERROR(fmt, args...)   SD_PRINTF("[SD][ERROR]   : " fmt "\n\r", ##args)
    #define SD_PRINTF_DEBUG(fmt, args...)   /* Nothing */
#endif

#define mainSD_CARD_DISK_NAME "/"
#define cliNEW_LINE "\n\r"

size_t xLoadFileToMemory( const char * file_name, uint8_t *buffer, size_t buffer_len );
size_t xLoadFileToMemory_malloc( const char *file_name, uint8_t ** buffer, size_t max_buffer_len, size_t overhead );
void   vClearMemoryBuffer( uint8_t * buffer );
void   vRegisterFATCLICommands( void );

#endif
