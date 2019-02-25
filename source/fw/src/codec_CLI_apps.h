
#ifndef CODEC_CLI_APPS_H
#define CODEC_CLI_APPS_H

#define APPEND_NEWLINE(BUFFER) strncat( BUFFER, "\r\n", strlen( "\r\n" ) )

void register_codec_cli_commands( void );

// Commands
static BaseType_t echo_command( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString );
static BaseType_t control_reg_command( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString );
static BaseType_t sampler_reg_command( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString );
static BaseType_t codec_reg_command( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString );
static BaseType_t load_sine_command( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString );
static BaseType_t get_sampler_version_command( char *pcWriteBuffer, size_t xWriteBufferLen, const char *pcCommandString );


#endif