#import "iCabberApp.h"
#import "Buddy.h"
#import "Notifications.h"
#import <sys/stat.h>
#import <unistd.h>
#import "lib/server.h"
#import "lib/conf.h"
#import "lib/utils.h"
#import "lib/harddefines.h"
#import "lib/connwrap/connwrap.h"

int buddy_compare(id left, id right, void * context)
{
	return [[left getName] localizedCaseInsensitiveCompare:[right getName]];
}

@implementation iCabberApp
    - (int)connectToServer {
	int try = 10; // try connect 10 times
	
	if ([myPrefs useProxy]) {
	    const char *host = [[myPrefs getProxyHost] UTF8String];
	    int port = [myPrefs getProxyPort];
	    const char *user = [[myPrefs getProxyUser] UTF8String];
	    const char *password = [[myPrefs getProxyPassword] UTF8String];
	    
	    NSLog(@"Enable proxy %s:%s@%s:%d\n", user, password, host, port);
	    
    	    cw_setproxy(host, port, user, password);
	} else
	    cw_setproxy(NULL, 0, NULL, NULL);
	
	while(1) {
	    if ((sock = srv_connect(servername, serverport)) < 0) {
		NSLog(@"Error conecting to (%s)\n", servername);
		if (try--) {
		    //wakeup wifi
		    system("ping -c 1 talk.google.com");
		    sleep(1);
		    continue;
		}
		return -1;
	    }
	    break;
	}
	NSLog(@"Connected.\n");
	return 0;
    }

    - (int)loginToServer {
	char *idsession;
	const char *my_username = [[myPrefs getUsername] UTF8String];
	const char *my_password = [[myPrefs getPassword] UTF8String];

	if ((idsession = srv_login(sock, servername, my_username, my_password, my_resource)) == NULL) {
	    NSLog(@"Error sending login string...\n");
	    return -1;
	}
	NSLog(@"Connected to %s: %s\n", servername, idsession);
	free(idsession);
	return 0;
    }

    - (int)disconnectFromServer {
	srv_setpresence(sock, "unavailable");

	srv_close(sock);

	sock = -1;	
	
	return 0;
    }

    - (int)updateBuddies {
	char *roster = srv_getroster(sock);
	
	if (roster) {
	    char *aux;
	    [buddyArray removeAllObjects];
	    
	    //NSLog(@"[roster]: %s\n\n", roster);

	    while ((aux = ut_strrstr(roster, "<item")) != NULL) {
		char *jid = getattr(aux, "jid=");
		char *name = getattr(aux, "name=");
		char *group = gettag(aux, "group");

		//NSLog(@"[roster]: jid=%s, name=%s, group=%s\n\n", jid, name, group);
		
		*aux = '\0';
        	
		//NSLog(@"JID %s\n", jid);
		
		Buddy *theBuddy = [[Buddy alloc] initWithJID:[NSString stringWithUTF8String: jid]
						     andName:[NSString stringWithUTF8String: ((name)?name:jid)]
						     andGroup:[NSString stringWithUTF8String: ((group)?group:"Buddies")]];
		[buddyArray addObject: [theBuddy autorelease]];
		
		if (jid)
		    free(jid);
		if (name)
		    free(name);
		if (group)
		    free(group);
	    }

	    free(roster);
	}
	
	[buddyArray sortUsingFunction:buddy_compare context:nil];

	[usersTable reloadData];

	srv_setpresence(sock, "Online!");

	return 0;
    }

    -(void)sendMessage:(NSString *) msg {
	const char *my_username = [[myPrefs getUsername] UTF8String];
	char *_msg = strdup([msg UTF8String]);
	char *to = strdup([[currBuddy getJID] UTF8String]);
	char from[1024];
	
	if (strchr(my_username, '@'))
	    sprintf(from, "%s/%s", my_username, my_resource);
	else
	    sprintf(from, "%s@%s/%s", my_username, servername, my_resource);

	//NSLog(@"Send from [%s] to [%s] [%s]\n\n", from, to, _msg);

	srv_sendtext(sock, to, _msg, from);

	[[Notifications sharedInstance] playSound: 0];
	
	[self updateHistory:to from:(char *)my_username message:_msg 
	    title:(([currBuddy getRFlag] == 0)?0:1) titlecolor:"#696969"];
	
	[currBuddy clrRFlag];
	
	free(_msg);
	free(to);
    }

    -(void)prepareLogin
    {
	[myPrefs loadConfig];
    }

    -(void)saveLoginSettings
    {
	[myPrefs saveConfig];
    }

    - (void)tolowerStr:(char *) s {
	while (*s) {
	    *s = tolower(*s);
	    s++;
	}
    }

    - (void)updateUserView:(const char *)user {
	char histfile[256];
	char *username = strdup(user);
	FILE *f;

	NSLog(@"updateUserView %s\n", username);
	[userText setText:@""];
	
	strcpy(histfile, [[myPrefs getConfigDir] UTF8String]);
	[self tolowerStr:username];
	strcat(histfile, "/");
	strcat(histfile, username);
	f = fopen(histfile, "r");
	if (f) {
	    char buf[4096 + 1];
	    do {
		int r = fread(buf, 1, 4096, f);
		if (r <= 0)
		    break;
		buf[r] = 0;
		[userText setHTML: [NSString stringWithFormat:@"%@%@", [userText HTML], [NSString stringWithUTF8String:buf]]];
	    } while(1);
	    fclose(f);
	}
	free(username);

	[userText scrollPointVisibleAtTopLeft:CGPointMake(0, 9999999) animated:NO];
    }

    - (void)updateHistory:(char *)username from:(char *) from message:(char *)message title:(int)title titlecolor:(char *)titlecolor {
	char histfile[256];
	char buf[4096];
	FILE *f;

	if (title)
	    snprintf(buf, 4096, "<br/><table><tr><td width=320 bgcolor=%s><font color=#ffffff><b>%s</b></font></td></tr>"
				            "<tr><td width=320>%s</td></tr></table>", titlecolor, from, message);
	else
	    snprintf(buf, 4096, "<table><tr><td width=320>%s</td></tr></table>", message);

	strcpy(histfile, [[myPrefs getConfigDir] UTF8String]);
	[self tolowerStr:username];
	strcat(histfile, "/");
	strcat(histfile, username);
	f = fopen(histfile, "a");
	if (f) {
	    fprintf(f, buf);
	    fclose(f);
	}
	
	if (currBuddy != nil)
	    if ([[[currBuddy getJID] lowercaseString] isEqualToString:[NSString stringWithUTF8String:username]]) {
		//[self updateUserView:username];
		[userText setHTML: [NSString stringWithFormat:@"%@%@", [userText HTML], [NSString stringWithUTF8String:buf]]];

		[userText scrollPointVisibleAtTopLeft:CGPointMake(0, 9999999) animated:YES];
	    }
    }

    - (void)loginMyAccount {
	if (![self connectToServer]) {
	    if (![self loginToServer]) {
		[self updateBuddies];
	    } else {
		NSLog(@"Can't login to server");
		/* handle login error here */
		    [eyeCandy showStandardAlertWithString:@"Error!"
			closeBtnTitle:@"Ok" 
			withError:@"Unable to login. Check your username and password."];
		return;
	    }
	} else {
	    NSLog(@"Can't connect to server");
	    /* handle connection error here */
	    	[eyeCandy showStandardAlertWithString:@"Error!"
		    closeBtnTitle:@"Ok" 
		    withError:@"Unable to connect to remote server. Check your settings and try again."];
	    return;
	}
	[transitionView transition: 1 fromView: mySettings toView: usersView];
	currPage = usersView;
        NSLog(@"0-1");
	ping_counter = ping_interval;
	connected = 1;
    }
    
    - (void)logoffMyAccount {
	connected = 0;
	[self disconnectFromServer];
	[transitionView transition: 2 fromView: usersView toView: mySettings];
	currPage = mySettings;
	NSLog(@"1-0");
    }

    - (void)navigationBar:(UINavigationBar *)navbar buttonClicked:(int)button {

	if (currPage == mySettings) {
	    if (button == 0) {
		//NSLog(@">>%s %s\n", [[myPrefs getUsername] UTF8String], [[myPrefs getPassword] UTF8String]);
		
		[self saveLoginSettings];
		
		/* Connect here */

		[self loginMyAccount];	
	    } else if (button == 1) {
		[eyeCandy showStandardAlertWithString:@"About"
			closeBtnTitle:@"Ok" 
			withError:@"Simple gtalk/jabber client for ipod touch.\n2008 (c) sashz <sashz@pdaXrom.org>"];
	    }
	} else if (currPage == usersView) {
	    if (button == 0) {
		//[transitionView transition: 1 fromView: usersView toView: userView];
		//currPage = userView;
        	//NSLog(@"1-2");
	    } else if (button == 1) {
	    
		/* Disconnect here */
		
		[self logoffMyAccount];	
	    }
	} else if (currPage == userView) {
	    if (button == 0) {
		[transitionView transition: 1 fromView: userView toView: newMsg];
		currPage = newMsg;
        	NSLog(@"2-3");
	    } else if (button == 1) {
		[transitionView transition: 2 fromView: userView toView: usersView];
		currPage = usersView;
		currBuddy = nil;
        	NSLog(@"2-1");
	    }
	} else if (currPage == newMsg) {
	    if (button == 0) {
		[self sendMessage:[replyText text]];

		[transitionView transition: 2 fromView: newMsg toView: userView];
		currPage = userView;
		[replyText setText:@""];
        	NSLog(@"3-2");
	    } else if (button == 1) {
		[transitionView transition: 2 fromView: newMsg toView: userView];
		currPage = userView;
        	NSLog(@"3-2");
	    }
	}
    }

    -(id)MySettings
    {
        struct CGRect rect = [UIHardware fullScreenApplicationContentRect];
        //rect.origin = CGPointMake (0.0f, 0.0f);
	rect.origin.y = 0;
        rect.size.height = 48.0f;
        UINavigationBar *nav = [[UINavigationBar alloc] initWithFrame: rect];
        [nav pushNavigationItem: [[UINavigationItem alloc] initWithTitle:@"Account"]];

        // 0 = greay
        // 1 = red
        // 2 = left arrow
        // 3 = blue
        [nav showLeftButton:@"About" withStyle:3 rightButton:@"Login" withStyle:3];

        [nav setDelegate: self];
	[nav setAutoresizesSubviews: YES];

        rect = [UIHardware fullScreenApplicationContentRect];
        rect.origin = CGPointMake (0.0f, 0.0f);
        UIView *mainView = [[UIView alloc] initWithFrame: rect];

        rect = [UIHardware fullScreenApplicationContentRect];
        rect.origin = CGPointMake (0.0f, 48.0f);
        rect.size.height -= 48.0f;
        myPrefs = [[MyPrefs alloc] initWithFrame: rect];

        [mainView addSubview: myPrefs];
        [mainView addSubview: nav];

	[self prepareLogin];

        return mainView;
    }

    -(id)NewMsg
    {
        struct CGRect rect = [UIHardware fullScreenApplicationContentRect];
        rect.origin = CGPointMake (0.0f, 0.0f);
        rect.size.height = 48.0f;
        UINavigationBar *nav = [[UINavigationBar alloc] initWithFrame: rect];
        [nav pushNavigationItem: [[UINavigationItem alloc] initWithTitle:@"New message"]];
        [nav showButtonsWithLeftTitle:@"Back" rightTitle: @"Send" leftBack: YES];
        [nav setDelegate: self];
        [nav setBarStyle: 0];

        rect = [UIHardware fullScreenApplicationContentRect];
        rect.origin = CGPointMake (0.0f, 0.0f);
        UIView *mainView = [[UIView alloc] initWithFrame: rect];

        rect = [UIHardware fullScreenApplicationContentRect];
        rect.origin = CGPointMake (0.0f, 48.0f);
        rect.size.height -= (245 + 16);
        replyText = [[UITextView alloc] initWithFrame: rect];

	[replyText setTextSize:14];
	[replyText setText:@""];

	[UIKeyboard initImplementationNow];
	UIKeyboard *keyboard = [[UIKeyboard alloc] initWithFrame: CGRectMake(0.0f, 245.0f,
							      320.0f, 480.0f - 245.f - 16.f)];

        [mainView addSubview: replyText];
	[mainView addSubview: keyboard];
        [mainView addSubview: nav];

        return mainView;
    }

    -(id)UserView
    {
        struct CGRect rect = [UIHardware fullScreenApplicationContentRect];
        rect.origin = CGPointMake (0.0f, 0.0f);
        rect.size.height = 48.0f;
        UINavigationBar *nav = [[UINavigationBar alloc] initWithFrame: rect];
        [nav pushNavigationItem: [[UINavigationItem alloc] initWithTitle:@"History"]];
        [nav showButtonsWithLeftTitle:@"Back" rightTitle: @"Reply" leftBack: YES];
        [nav setDelegate: self];
        [nav setBarStyle: 0];

        rect = [UIHardware fullScreenApplicationContentRect];
        rect.origin = CGPointMake (0.0f, 0.0f);
        UIView *mainView = [[UIView alloc] initWithFrame: rect];

        rect = [UIHardware fullScreenApplicationContentRect];
        rect.origin = CGPointMake (0.0f, 48.0f);
        rect.size.height -= 16;
        userText = [[UITextView alloc] initWithFrame: rect];

	[userText setEditable:NO];
	[userText setTextSize:14];
	[userText setText:@""];

        [mainView addSubview: userText];
        [mainView addSubview: nav];

        return mainView;
    }

    -(id)UsersView
    {
        struct CGRect rect = [UIHardware fullScreenApplicationContentRect];
        rect.origin = CGPointMake (0.0f, 0.0f);
        rect.size.height = 48.0f;
        UINavigationBar *nav = [[UINavigationBar alloc] initWithFrame: rect];
        [nav pushNavigationItem: [[UINavigationItem alloc] initWithTitle:@"Buddies"]];
        [nav showButtonsWithLeftTitle:@"Logoff" rightTitle: @"User" leftBack: YES];
        [nav setDelegate: self];
        [nav setBarStyle: 0];

        rect = [UIHardware fullScreenApplicationContentRect];
        rect.origin = CGPointMake (0.0f, 0.0f);
        UIView *mainView = [[UIView alloc] initWithFrame: rect];

        rect = [UIHardware fullScreenApplicationContentRect];
        rect.origin = CGPointMake (0.0f, 48.0f);
        rect.size.height -= 48;
	usersTable = [[UITable alloc] initWithFrame: rect];

	UITableColumn *col = [[[UITableColumn alloc] initWithTitle: @"title" identifier: @"title" width: 320.0f] autorelease];
	[usersTable addTableColumn: col];

	[usersTable setSeparatorStyle:1];
	[usersTable setRowHeight:40];
	[usersTable setDataSource: self];
	[usersTable setDelegate: self];
	[usersTable reloadData];

        [mainView addSubview: nav];
        [mainView addSubview: usersTable];

        return mainView;
    }

    -(int) numberOfRowsInTable: (UITable *)table
    {
	return [buddyArray count];
    }

    -(UITableCell *) table: (UITable *)table cellForRow: (int)row column: (int)col
    {
	UIImageAndTextTableCell *cell = [[UIImageAndTextTableCell alloc] init];

	Buddy *buddy = [buddyArray objectAtIndex:row];
	
	//NSLog(@"JID %s\n", [[buddy getJID] UTF8String]);

	[cell setTitle:[buddy getName]];
	[cell setShowDisclosure:YES];

	if ([buddy getMsgCounter]) {
	    [cell setImage: image_content];
	} else {
	    int status = [buddy getStatus];
	    
	    if (!status)
		[cell setImage: image_offline];
	    else if (status & FLAG_BUDDY_CHAT)
		[cell setImage: image_chat];
	    else if (status & FLAG_BUDDY_DND)
		[cell setImage: image_dnd];
	    else if (status & FLAG_BUDDY_XAWAY)
		[cell setImage: image_xaway];
	    else if (status & FLAG_BUDDY_AWAY)
		[cell setImage: image_away];
	    else
		[cell setImage: image_online];
	}
	return [cell autorelease];
    }

    -(void)tableRowSelected:(NSNotification *)notification 
    {
	int i = [usersTable selectedRow];

	currPage = userView;
	
	Buddy *buddy = [buddyArray objectAtIndex:i];

	[self updateUserView:[[buddy getJID] UTF8String]];

	[buddy clrMsgCounter];

	[usersTable reloadData];

	currBuddy = buddy;

        [transitionView transition: 1 fromView: usersView toView: userView];
    }

    -(Buddy *)getBuddy:(NSString *) jid
    {
	int nbuddies = [buddyArray count];
	int i;
	for (i = 0; i < nbuddies; i++) {
	    Buddy *buddy = [buddyArray objectAtIndex: i];
	    if ([[buddy getJID] isEqualToString:[jid lowercaseString]]) {
		return buddy;
	    }
	}
	return nil;
    }

    -(void)timer:(NSTimer *)aTimer
    {
	if (!connected)
	    return;
	
	int x = check_io(sock);
	
	//NSLog(@"IO %d\n", x);
	
	if (x > 0) {
	    Buddy *b;
	    
	    // reset ping counter
	    
	    ping_counter = ping_interval;
	    
    	    srv_msg *incoming = readserver(sock);
	    
	    //NSLog(@"get incoming message!\n");
	    
    	    switch (incoming->m) {
    		case SM_PRESENCE:
		    b = [self getBuddy:[NSString stringWithUTF8String: incoming->from]];
		    if (b != nil) {
			[b setStatus:incoming->connected];
			[usersTable reloadData];
		    }
		    free(incoming->from);
		    break;

    		case SM_MESSAGE:
		    [[Notifications sharedInstance] playSound: 1];
		    
		    b = [self getBuddy:[NSString stringWithUTF8String: incoming->from]];
		    if (b != nil) {
			if (b != currBuddy) {
			    [b incMsgCounter];
			    if ([b getMsgCounter] < 2)
				[usersTable reloadData];
			}
		    }

		    [self updateHistory:incoming->from from:incoming->from message:incoming->body 
			title:(([b getRFlag] != 1)?1:0) titlecolor:"#50afca"];
		    
		    [b setRFlag];
		    
		    free(incoming->body);
		    free(incoming->from);
		    break;

    		case SM_UNHANDLED:
		    break;
    	    }
    	    free(incoming);
	} else if (x < 0) {
	
	    NSLog(@"select() error\n");
	    
	    if (errno != EINTR) {
		[self logoffMyAccount];
		[eyeCandy showStandardAlertWithString:@"Error!"
			closeBtnTitle:@"Ok" 
			withError:@"Socket error. Check your network and try connect again."];
		return;
	    }
	}
	
	ping_counter--;
	
	if (ping_counter == (ping_interval / 4)) {
	    NSLog(@"Send ping\n");
	    srv_sendping(sock);
	} else if (!ping_counter) {
	    NSLog(@"BUMS! Network offline!\n");
	    [self logoffMyAccount];
	    [eyeCandy showStandardAlertWithString:@"Error!"
		    closeBtnTitle:@"Ok" 
		    withError:@"Unable to get a response from remote server. Check your network and try connect again."];
	    return;
	}
    }

    -(void)applicationSuspend:(GSEvent *)event {
	if (!connected) {
	    exit(0);
	}
    }

    -(void)applicationResume:(GSEvent *)event {
    }

    -(void)applicationExited:(GSEvent *)event {
    }

    -(void)applicationDidFinishLaunching:(NSNotification*)unused
    {
	buddyArray = [[NSMutableArray alloc] init];

	[[Notifications sharedInstance] setApp: self];	

	eyeCandy = [[[EyeCandy alloc] init] retain];

	struct CGRect rect = [UIHardware fullScreenApplicationContentRect];
	rect.origin.x = rect.origin.y = 0.0f;

	UIWindow *window = [[UIWindow alloc] initWithContentRect: rect];

        [window orderFront: self];
        [window makeKey: self];
        [window _setHidden: NO];

        transitionView = [[UITransitionView alloc] initWithFrame: rect];
        
	[window setContentView: transitionView];
	
	mySettings= [self MySettings];
        usersView = [self UsersView];
        userView  = [self UserView];
        newMsg    = [self NewMsg];

	/*
	1 - slide left - pushes
	2 - slide right - pushes
	3 - slide up - pushes
	4 - slides up - doesn't push.. clears background
	5 - slides down, doesn't push.. clears background
	6 - fades out, then fades new view in
	7 - slide down - pushes
	8 - slide up - doesn't push
	9 - slide down - doesn't push
	*/

        [transitionView transition: 0 toView: mySettings];

	image_online  = [UIImage applicationImageNamed: @"available.png"];
	image_away    = [UIImage applicationImageNamed: @"away.png"];
	image_xaway   = [UIImage applicationImageNamed: @"xaway.png"];
	image_dnd     = [UIImage applicationImageNamed: @"dnd.png"];
	image_chat    = [UIImage applicationImageNamed: @"chat.png"];
	image_offline = [UIImage applicationImageNamed: @"offline.png"];
	image_content = [UIImage applicationImageNamed: @"content.png"];

	currBuddy = nil;
	currPage  = mySettings;
	
	connected = 0;

	my_resource = "itouchabber";
	servername = "talk.google.com";
	serverport = 5223;
	
	ping_interval = 80;
	ping_counter = ping_interval;
	
	myTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self 
    		    selector:@selector(timer:) userInfo:nil repeats:YES];		    
    }

@end

