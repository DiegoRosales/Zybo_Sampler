

#ifndef FAT_CLI_APPS_H
#define FAT_CLI_APPS_H


#define mainSD_CARD_DISK_NAME "/"
#define cliNEW_LINE "\n\r"

void register_fat_cli_commands( void );
static void prvCreateFileInfoString( char *pcBuffer, FF_FindData_t *pxFindStruct );

static BaseType_t sd_initialization_command( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString );

/*
 * Implements the DIR command.
 */
static BaseType_t prvDIRCommand( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString );

/*
 * Implements the CD command.
 */
static BaseType_t prvCDCommand( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString );

/*
 * Implements the TYPE command.
 */
static BaseType_t prvTYPECommand( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString );

/*
 * Implements the PWD (print working directory) command.
 */
static BaseType_t prvPWDCommand( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString );

#endif