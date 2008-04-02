#ifndef _READCONF_H_
#define _READCONF_H_

char *readconf(char *fname, char *name, char *key);

char *writeconf(char *fname, char *name, char *key, int n);

#endif
