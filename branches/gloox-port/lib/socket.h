#ifndef __SOCKET_H__
#define __SOCKET_H__ 1

#include <sys/socket.h>

int sk_conn(struct sockaddr *name, int ssl);
int sk_send(int sock, char *buffer, int ssl);
char *sk_recv(int sock, int ssl);
void sk_close(int sock, int ssl);

#endif
