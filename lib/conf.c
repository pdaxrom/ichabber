#include <stdio.h>
#include <string.h>
#include <syslog.h>
#include <stdlib.h>

char *readconf(char *fname, char *name, char *out)
{
    char rbuf[1024];
    FILE *f;
    
    out[0] = 0;
    
    f = fopen(fname, "rb");
    if (!f) {
        fprintf(stderr, "no such config file: '%s'\n", fname);
	return NULL;
    }

    while (fgets(rbuf, 1024, f)) {
        char *buf = rbuf;
        while(*buf && (*buf <= ' '))
            buf++;

        if (*buf == '#')
            continue;

        if (!strncmp(name, buf, strlen(name))) {
            char *ptr = buf + strlen(buf);
            while ((ptr > buf) && (*ptr <= ' '))
                *ptr-- = 0;
        
            ptr = buf + strlen(name);
            while (*ptr && (*ptr <= ' '))
                ptr++;    
        
            strncpy(out, ptr, 256);
        }
    }

    if (!strlen(out)) {
        fprintf(stderr, "can't find variable: '%s' in config file: '%s'\n", name, fname);
        return NULL;
    }

    fclose(f);
    return out;
}

char *writeconf(char *fname, char *name, char *key, int n)
{
    FILE *f;
    
    if (n)
	f = fopen(fname, "w");
    else
	f = fopen(fname, "a");

    if (f) {
	fprintf(f, "%s %s\n", name, key);
	fclose(f);
    } else {
        fprintf(stderr, "no such config file: '%s'\n", fname);    
	return NULL;
    }
    
    return key;
}

