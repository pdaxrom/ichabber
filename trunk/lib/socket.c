#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <unistd.h>
#include "utils.h"
#include "connwrap/connwrap.h"

#include "socket.h"
#include <signal.h>

static int ssl = 1;

/* Desc: create socket connection
 * 
 * In  : servername, port
 * Out : socket (or -1 on error)
 *
 * Note: -
 */
int sk_conn(struct sockaddr *name)
{
  int sock;

  if ((sock = socket(PF_INET, SOCK_STREAM, 0)) < 0) {
    perror("socket (socket.c:23)");
    return -1;
  }

  if (cw_connect(sock, (struct sockaddr *) name, sizeof(struct sockaddr), ssl) < 0) {
    perror("connect (socket.c:29)");
    close(sock);
    return -1;
  }

/*
  rc = cw_nb_connect(sock, (struct sockaddr *) name, sizeof(struct sockaddr), ssl, &state);
  if (rc == -1 ) {
    perror("connect (socket.c:29)");
    close(sock);
    return(-1);
  }
*/

  return sock;
}


/* Desc: send data through socket
 * 
 * In  : socket, buffer to send
 * Out : 0 = fail, 1 = pass
 *
 * Note: -
 */
int sk_send(int sock, char *buffer)
{
  if ((cw_write(sock, buffer, strlen(buffer), ssl)) == -1)
    return 0;
  else
    return 1;
}

/* Desc: receive data through socket
 * 
 * In  : socket
 * Out : received buffer
 *
 * Note: it is up to the caller to free the returned string
 */

char *old_sk_recv(int sock)
{
    char *buffer = (char *) malloc(2048);
    
    cw_read(sock, buffer, 2048, ssl);
    
    return buffer;
}

char *sk_recv(int sock)
{
  int i = 1;
  int end = 0;
  int tambuffer = 128;
  char *aux;

  char *buffer = malloc(tambuffer + 1);
  char *retval = malloc(tambuffer + 1);

  memset(retval, 0, tambuffer + 1);
  memset(buffer, 0, tambuffer + 1);

  while (!end) {
    int ret = cw_read(sock, buffer, tambuffer, ssl);
    if (ret == 1 && *buffer == ' ' && i == 1)
	break; // skip ping message

    if (i == 1)
      strcpy(retval, buffer);
    else {
      retval = realloc(retval, (tambuffer * i) + 1);
      strncat(retval, buffer, tambuffer + 1);
    }
    i++;
    aux = retval + strlen(retval) - 1;
    if (*aux != '>')
      end = 0;
    else
      end = 1;
    memset(buffer, 0, tambuffer + 1);
  }
  free(buffer);
  return retval;
}

void sk_close(int sock)
{
  cw_close(sock);
}
