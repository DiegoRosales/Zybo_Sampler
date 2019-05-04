#ifndef SAMPLER_CLI_APPS_H
#define SAMPLER_CLI_APPS_H


#define cliNEW_LINE "\n\r"
#define APPEND_NEWLINE(BUFFER) strncat( BUFFER, cliNEW_LINE, strlen( cliNEW_LINE ) )

void register_sampler_cli_commands( void );




#endif
