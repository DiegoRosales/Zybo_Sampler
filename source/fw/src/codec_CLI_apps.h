
#ifndef CODEC_CLI_APPS_H
#define CODEC_CLI_APPS_H

void register_codec_cli_commands( void );

// Commands
static BaseType_t echo_command( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString );


#endif