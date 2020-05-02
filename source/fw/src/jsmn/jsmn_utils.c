/*********************************
 * JSMN Utilities
 * *******************************/

#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#include "xil_io.h"

#include "jsmn.h"
#include "jsmn_utils.h"

// Compare a string with a JSON string
int l_json_equal(const char *json, jsmntok_t *tok, const char *s) {
    int token_end   = tok->end;
    int token_start = tok->start;
    int token_len   = token_end - token_start;
    if ( ( tok->type == JSMN_STRING ) && ( ( (int) strlen(s) ) == ( token_len ) ) && ( strncmp( json + token_start, s, token_len ) == 0 ) ) {
        return 1;
    }
    return 0;
}

// Print a JSON string
int l_json_print_string(const char *json, jsmntok_t *tok) {
    int token_end        = tok->end;
    int token_start      = tok->start;
    size_t   token_len   = (size_t)   (token_end - token_start + 1);
    char token_str[MAX_CHAR_IN_TOKEN_STR];
    memset( token_str, (char) '\0', (MAX_CHAR_IN_TOKEN_STR * sizeof(char)) );

    if ( ( tok->type == JSMN_STRING ) && ( token_len <= MAX_CHAR_IN_TOKEN_STR ) ) {
        snprintf( token_str, token_len, (const char *) (json + token_start) );
        xil_printf( token_str );
        return 0;
    }
    return 1;
}

// Copy a JSON String
int l_json_get_string(const char *json, jsmntok_t *tok, char *output_buffer) {
    int token_end        = tok->end;
    int token_start      = tok->start;
    int token_len        = token_end - token_start + 1;
    memset( output_buffer, 0x00, MAX_CHAR_IN_TOKEN_STR );

    if ( ( tok->type == JSMN_STRING ) && ( token_len < MAX_CHAR_IN_TOKEN_STR ) ) {
        snprintf( output_buffer, token_len, json + token_start );
        return 0;
    }
    return 1;
}
