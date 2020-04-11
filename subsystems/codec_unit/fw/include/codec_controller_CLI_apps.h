
#ifndef CODEC_CLI_APPS_H
#define CODEC_CLI_APPS_H

#define APPEND_NEWLINE(BUFFER) strncat( BUFFER, "\r\n", strlen( "\r\n" ) )

void register_codec_cli_commands( void );

#endif
