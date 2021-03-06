#include <stdlib.h>
#include <string.h>

#include "utf8.h"


/* Desc: convert UTF8 -> ASCII
 * 
 * In  : UTF8 string
 * Out : ASCII string
 *
 * Note: it is up to the caller to free the returned string
 */
char *utf8_decode(const char *src)
{
  char *ret = calloc(1, strlen(src) + 1);
  char *aux = ret;

  while (*src) {
    unsigned char lead = *src++;
    if ((lead & 0xe0) == 0xc0) {
      unsigned char ch2 = *src++;
      *aux = ((lead & 0x1f) << 6) | (ch2 & 0x3f);
    } else {
      *aux = lead;
    }
    aux++;
  }

  return ret;
}


/* Desc: convert ASCII -> UTF8
 * 
 * In  : ASCII string
 * Out : UTF8 string
 *
 * Note: it is up to the caller to free the returned string
 */
char *utf8_encode(const char *src)
{
  char *ret = calloc(1, (strlen(src) * 2) + 1);
  char *aux = ret;

  while (*src) {
    unsigned char ch = *src++;
    if (ch < 0x80) {
      *aux = ch;
    } else {			/* if (ch < 0x800) { */
      *aux++ = 0xc0 | (ch >> 6 & 0x1f);
      *aux = 0xc0 | (0x80 | (ch & 0x3f));
    }
    aux++;
  }

  return ret;
}
