

#ifndef FAT_CLI_APPS_H
#define FAT_CLI_APPS_H


#define mainSD_CARD_DISK_NAME "/"


void register_fat_cli_commands( void );

static BaseType_t sd_initialization_command( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString );

#endif