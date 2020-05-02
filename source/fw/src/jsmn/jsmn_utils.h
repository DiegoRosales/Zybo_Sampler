#ifndef __JSMN_UTILS_H__
#define __JSMN_UTILS_H__

#include "jsmn.h"

#ifndef MAX_CHAR_IN_TOKEN_STR
  #define MAX_CHAR_IN_TOKEN_STR 256
#endif

int l_json_equal(const char *json, jsmntok_t *tok, const char *s);
int l_json_print_string(const char *json, jsmntok_t *tok);
int l_json_get_string(const char *json, jsmntok_t *tok, char *output_buffer);

#endif
