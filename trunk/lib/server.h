#ifndef __SERVER_H__
#define __SERVER_H__ 1

typedef enum {
  SM_MESSAGE,
  SM_PRESENCE,
  SM_SUBSCRIBE,
  SM_UNSUBSCRIBE,
  SM_STREAMERROR,
  SM_NEEDDATA,
  SM_NODATA,
  SM_UNHANDLED
} SRV_MSGTYPE;

typedef struct {
  SRV_MSGTYPE m;		/* message type: see above! */
  int connected;		/* meaningful only with SM_PRESENCE */
  char *from;			/* sender */
  char *body;			/* meaningful only with SM_MESSAGE */
} srv_msg;

char *srv_poll(int sock, int ssl);
int srv_connect(const char *server, unsigned int port, int ssl);
int srv_close(int sock, int ssl);
char *srv_login(int sock, const char *server, const char *user,
		const char *pass, const char *resource, int ssl);
int srv_setpresence(int sock, const char *type, const char *msg, int ssl);
char *srv_getroster(int sock, int ssl);
int srv_sendtext(int sock, const char *to, const char *text,
		 const char *from, int ssl);
int srv_sendping(int sock, int ssl);
int check_io(int fd1, int ssl);
srv_msg *readserver(int sock, int ssl);
void srv_DelBuddy(int sock, char *jidname, int ssl);
void srv_AddBuddy(int sock, char *jidname, int ssl);
int srv_ReplyToSubscribe(int sock, const char *to, int status, int ssl);

#endif
