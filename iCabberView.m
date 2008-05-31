#import "iCabberView.h"
#import "Buddy.h"
#import "BuddyAction.h"
#import "Notifications.h"
#import "IconSet.h"
#import "BuddyCell.h"
#import "resolveHostname.h"
#import <sys/stat.h>
#import <unistd.h>
#import "lib/server.h"
#import "lib/conf.h"
#import "lib/utils.h"
#import "lib/harddefines.h"
#import "lib/connwrap/connwrap.h"
#import "version.h"

extern UIApplication *UIApp;

static id sharedInstanceiCabber;

int buddy_compare(id left, id right, void * context)
{
    return [[left getName] localizedCaseInsensitiveCompare:[right getName]];
}

int buddy_compare_status(id left, id right, void * context)
{
    int l = [left getMsgCounter];
    int r = [right getMsgCounter];

    if (l && (!r))
	return -1;
    if ((!l) && r)
	return 1;

    l = [left getStatus];
    r = [right getStatus];
    
    if (l && (!r))
	return -1;
    if ((!l) && r)
	return 1;
	
    return [[left getName] localizedCaseInsensitiveCompare:[right getName]];
}

@implementation iCabberView
    - (BOOL)hasNetworkConnection {
	if(![[NetworkController sharedInstance] isNetworkUp]) {
	    NSLog(@"Bring up edge");
	    [[NetworkController sharedInstance] keepEdgeUp];
	    [[NetworkController sharedInstance] bringUpEdge];
	    sleep(4);
	}
	return [[NetworkController sharedInstance] isNetworkUp];
    }
    
    - (int)connectToServer {
	if(![self hasNetworkConnection]) {
	    return -1;
	}
	
	if ([myPrefs useProxy]) {
	    const char *host = [[myPrefs getProxyServer] UTF8String];
	    int port = [myPrefs getProxyPort];
	    const char *user = [[myPrefs getProxyUser] UTF8String];
	    const char *password = [[myPrefs getProxyPassword] UTF8String];
	    
	    NSLog(@"Enable proxy %s:%s@%s:%d\n", user, password, host, port);
	    
    	    cw_setproxy(host, port, user, password);
	} else
	    cw_setproxy(NULL, 0, NULL, NULL);

	NSString *ipa = resolveHostname([myPrefs getServer]);

	if (ipa == nil)
	    return -1;
	
	NSLog(@"Connection to %@...\n", ipa);
	if ((sock = srv_connect([[myPrefs getServer] UTF8String], [myPrefs getPort], [myPrefs useSSL])) < 0) {
	    NSLog(@"Error conecting to (%@)\n", [myPrefs getServer]);
	    return -1;
	}
	NSLog(@"Connected.\n");
	return 0;
    }

    - (int)loginToServer {
	char *idsession;
	const char *my_username = [[myPrefs getUsername] UTF8String];
	const char *my_password = [[myPrefs getPassword] UTF8String];
	const char *my_servername = [[myPrefs getServer] UTF8String];
	const char *my_resource = [[myPrefs getResource] UTF8String];

	if ((idsession = srv_login(sock, my_servername, my_username, my_password, my_resource, [myPrefs useSSL])) == NULL) {
	    NSLog(@"Error sending login string...\n");
	    srv_close(sock, [myPrefs useSSL]);
	    return -1;
	}
	NSLog(@"Connected to %s: %s\n", my_servername, idsession);
	free(idsession);
	return 0;
    }

    - (int)disconnectFromServer {
	srv_setpresence(sock, "unavailable", [myPrefs useSSL]);

	srv_close(sock, [myPrefs useSSL]);

	sock = -1;	
	
	return 0;
    }

    - (int)updateBuddies {
	char *roster = srv_getroster(sock, [myPrefs useSSL]);
	
	if (roster) {
	    char *aux;
	    [buddyArray removeAllObjects];
	    
	    //NSLog(@"[roster]: %s\n\n", roster);

	    while ((aux = ut_strrstr(roster, "<item")) != NULL) {
		char *jid = getattr(aux, "jid=");
		char *name = getattr(aux, "name=");
		char *group = gettag(aux, "group");

		if (name && (strlen(name) == 0)) {
		    free(name);
		    name = NULL;
		}

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
	
	[self updateUsersTable];

	srv_setpresence(sock, "Online!", [myPrefs useSSL]);

	return 0;
    }

    -(void)sendMessage:(NSString *) msg {
	NSString *my_username = [myPrefs getUsername];
	NSString *my_servername = [myPrefs getServer];
	NSString *my_resource = [myPrefs getResource];
	NSString *to = [currBuddy getJID];
	NSString *from = [NSString alloc];

	if ([my_username rangeOfString:@"@"].location != NSNotFound)
	    from = [NSString stringWithFormat:@"%@/%@", my_username, my_resource];
	else
	    from = [NSString stringWithFormat:@"%@@%@/%@", my_username, my_servername, my_resource];

	//NSLog(@"send from [%@] to [%@] [%@]\n\n", from, to, msg);
	
	srv_sendtext(sock, [to UTF8String], [msg UTF8String], [from UTF8String], [myPrefs useSSL]);

	if ([myPrefs useSound])
	    [[Notifications sharedInstance] playSound: 0];
	
	[self updateHistory:to from:my_username message:msg 
	    title:(([currBuddy getRFlag] == 0)?0:1) titlecolor:@"#696969"];
	
	[currBuddy clrRFlag];
    }

    - (void)updateUserView:(Buddy *) buddy {
	[userView setText:@""];
	[userView setTitle:[buddy getName]];

	NSString *name = [NSString stringWithFormat:@"%@/%@", [myPrefs getConfigDir], [[buddy getJID] lowercaseString]];

	//NSLog(@"read history %@\n\n", name);

	NSFileHandle *inFile = [NSFileHandle fileHandleForReadingAtPath:name];

	if (inFile != nil) {
	    NSData *fileData = [inFile readDataToEndOfFile];
	    NSString *tmp = [[NSString alloc] initWithData:fileData encoding:NSUTF8StringEncoding];

	    [userView setText: tmp];
#if 0
	    const char *data, *ptr;
	    
	    unsigned long long fsize = [inFile seekToEndOfFile];
	    
	    if (fsize > MAX_USERLOG_SIZE)
		[inFile seekToFileOffset: fsize - MAX_USERLOG_SIZE];
	    else
		[inFile seekToFileOffset: 0];

	    NSData *fileData = [inFile readDataToEndOfFile];

	    data = [fileData bytes];
	    ptr = strcasestr(data, "<br/><table>");
	    
	    if (ptr) {
		NSString *tmp = [[NSString alloc] initWithData:[[NSData alloc] initWithBytesNoCopy:(void *)ptr length:([fileData length] - (ptr - data))] encoding:NSUTF8StringEncoding];

		[userView setText: tmp];
	    }
#endif
	    [inFile closeFile];
	}
    }

    - (void)updateHistory:(NSString *)username from:(NSString *) from message:(NSString *)message title:(int)title titlecolor:(NSString *)titlecolor {
	NSString *_message;

	NSDate *_time = [[NSDate alloc] init];

	NSString *stamp = [NSString stringWithFormat: @"%@", 
			[_time descriptionWithCalendarFormat: 
			@"%b %d, %Y %I:%M %p" timeZone:nil locale:nil]];
	[_time release];
	//NSLog(@"Stamp: %@", stamp);
	
	if (title)
	    _message = [NSString stringWithFormat:
	    @"<br/><table><tr><td width=320 bgcolor=%@><font color=#ffffff><b>%@<br/>%@</b></font></td></tr>"
	    "<tr><td width=320>%@</td></tr></table>",
	    titlecolor, stamp, from, message];
	else
	    _message = [NSString stringWithFormat:@"<table><tr><td width=320>%@</td></tr></table>", message];

	NSString *name = [NSString stringWithFormat:@"%@/%@", [myPrefs getConfigDir], [username lowercaseString]];

	//NSLog(@"write history %@\n\n", name);

	if (![[NSFileManager defaultManager] fileExistsAtPath:name])
	    [[NSFileManager defaultManager] createFileAtPath:name contents: nil attributes: nil];

	NSFileHandle *outFile = [NSFileHandle fileHandleForUpdatingAtPath:name];

	if (outFile != nil) {
	    [outFile seekToEndOfFile];

	    [outFile writeData:[NSData dataWithBytes:[_message UTF8String] length:[_message lengthOfBytesUsingEncoding:NSUTF8StringEncoding]]];
	    
	    [outFile closeFile];

	    if (currBuddy != nil)
		if ([[[currBuddy getJID] lowercaseString] isEqualToString:[username lowercaseString]]) {
		    [userView appendText: _message];
		}
	}	
    }

    - (void)loginMyAccount {
	//NSLog(@">>%s %s\n", [[myPrefs getUsername] UTF8String], [[myPrefs getPassword] UTF8String]);
	if (![self connectToServer]) {
	    if (![self loginToServer]) {
		[self updateBuddies];
	    } else {
		NSLog(@"Can't login to server");
		/* handle login error here */
		    [eyeCandy showStandardAlertWithString:NSLocalizedString(@"Error!", @"Error")
			closeBtnTitle:@"Ok" 
			withError:NSLocalizedString(@"Unable to login. Check your username and password.", @"Login problem")
		    ];
		return;
	    }
	} else {
	    NSLog(@"Can't connect to server");
	    /* handle connection error here */
	    	[eyeCandy showStandardAlertWithString:NSLocalizedString(@"Error!", @"Error")
		    closeBtnTitle:@"Ok" 
		    withError:NSLocalizedString(@"Unable to connect to remote server. Check your network settings and try again.", @"Connection problem")
		];
	    return;
	}
	[transitionView transition: 1 fromView: myPrefs toView: usersView];
	currPage = usersView;
        NSLog(@"0-1");
	ping_counter = ping_interval;
	connected = 1;
    }
    
    - (void)logoffMyAccount {
	connected = 0;
	[self disconnectFromServer];
	[transitionView transition: 2 fromView: usersView toView: myPrefs];
	currPage = myPrefs;
	NSLog(@"1-0");
    }

    - (void)navigationBar:(UINavigationBar *)navbar buttonClicked:(int)button {
	if (currPage == usersView) {
	    if (button == 0) {
		//[transitionView transition: 1 fromView: usersView toView: userView];
		//currPage = userView;
        	//NSLog(@"1-2");
	    } else if (button == 1) {
	    
		/* Disconnect here */
		
		[self logoffMyAccount];	
	    }
	}
    }

    -(int)numNewMessages
    {
	int nbuddies = [buddyArray count];
	int i;
	int count = 0;
	for (i = 0; i < nbuddies; i++) {
	    Buddy *buddy = [buddyArray objectAtIndex: i];
	    count += [buddy getMsgCounter];
	}
	return count;
    }

    -(void)updateAppBadge
    {
	int n = [self numNewMessages];
	if (n) {
	    NSString *badgeText = [[NSString alloc] initWithFormat:@"%d", n];
	    [UIApp setApplicationBadge: badgeText];
	} else {
	    [UIApp removeApplicationBadge];
	}
    }

    -(void)updateUsersTable
    {
	[buddyArray sortUsingFunction:buddy_compare_status context:nil];
	[usersTable reloadData];
	[self updateAppBadge];
    }

    -(void)switchFromNewMessageToUserView
    {
	[transitionView transition: 2 fromView: newMsg toView: userView];
	currPage = userView;
    }

    -(void)switchFromUserViewToUsers
    {
	[transitionView transition: 2 fromView: userView toView: usersView];
	currPage = usersView;
	currBuddy = nil;
    }
    
    -(void)switchFromUserViewToNewMessage
    {
	[transitionView transition: 1 fromView: userView toView: newMsg];
	currPage = newMsg;
    }

    -(id)UsersView
    {
        struct CGRect rect = [UIHardware fullScreenApplicationContentRect];
        rect.origin = CGPointMake (0.0f, 0.0f);
        rect.size.height = 48.0f;
        UINavigationBar *nav = [[UINavigationBar alloc] initWithFrame: rect];
        [nav pushNavigationItem: [[UINavigationItem alloc] initWithTitle:NSLocalizedString(@"Buddies", @"Buddies")]];
        [nav showButtonsWithLeftTitle:NSLocalizedString(@"Logoff", @"Logoff") rightTitle:NSLocalizedString(@"Menu", @"Menu") leftBack: YES];
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
	[self updateUsersTable];

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
	Buddy *buddy = [buddyArray objectAtIndex:row];
	//NSLog(@"JID %s\n", [[buddy getJID] UTF8String]);

	BuddyCell *cell = [[BuddyCell alloc] initWithJID:[buddy getJID] andName:[buddy getName]];

	if ([buddy getMsgCounter]) {
	    [cell setStatusImage: ICON_CONTENT];
	} else {
	    int status = [buddy getStatus];
		[cell setStatusText: [buddy getStatusText]];
	
	    if (!status)
		[cell setStatusImage: ICON_OFFLINE];
	    else if (status & FLAG_BUDDY_CHAT)
		[cell setStatusImage: ICON_CHAT];
	    else if (status & FLAG_BUDDY_DND)
		[cell setStatusImage: ICON_DND];
	    else if (status & FLAG_BUDDY_XAWAY)
		[cell setStatusImage: ICON_XAWAY];
	    else if (status & FLAG_BUDDY_AWAY)
		[cell setStatusImage: ICON_AWAY];
	    else
		[cell setStatusImage: ICON_ONLINE];
	}

	return [cell autorelease];
    }

    -(void)tableRowSelected:(NSNotification *)notification 
    {
	int i = [usersTable selectedRow];

	currPage = userView;
	
	Buddy *buddy = [buddyArray objectAtIndex:i];

	[self updateUserView:buddy];

	[buddy clrMsgCounter];

	[self updateUsersTable];

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

	int x = check_io(sock, [myPrefs useSSL]);
	
	//NSLog(@"IO %d\n", x);
	
	if (x > 0) {
	    Buddy *b;
	    
	    // reset ping counter
	    
	    ping_counter = ping_interval;
	    
		srv_msg *incoming = readserver(sock, [myPrefs useSSL]);
	    
		switch (incoming->m) {
			case SM_PRESENCE:
				b = [self getBuddy:[NSString stringWithUTF8String: incoming->from]];
				if (b != nil) {
					[b setStatus:incoming->connected];
					if(incoming->body) {
						[b setStatusText: [NSString stringWithUTF8String: incoming->body]];
						free(incoming->body);
					}
					//NSLog(@"status ok");
					[self updateUsersTable];
				}
				free(incoming->from);
			break;

		case SM_SUBSCRIBE: {
		    NSString *jid = [NSString stringWithUTF8String: incoming->from];
		    [eyeCandy showAlertYesNoWithTitle:NSLocalizedString(@"Request received", @"Request received") 
			      withText:[NSString stringWithFormat:NSLocalizedString(@"Do you want to add user %@ to buddies?", @"Accept new buddy"),
			    		jid] 
			      andStyle:2
			      andDelegate:self
			      andContext:[[BuddyAction alloc] initWithBuddy:jid andAction:BUDDYACTION_UNSUBSCRIBE]];
		    free(incoming->from);
		    break;
		    }

		case SM_UNSUBSCRIBE: {
		    NSString *jid = [NSString stringWithUTF8String: incoming->from];
		    NSLog(@"Unsubscribe request from %@", jid);
		    free(incoming->from);
		    break;
		    }
		    
    		case SM_MESSAGE:
		    b = [self getBuddy:[NSString stringWithUTF8String: incoming->from]];
		    if (b != nil) {
			if (b != currBuddy) {
			    [b incMsgCounter];
			    if ([b getMsgCounter] < 2)
				[self updateUsersTable];
			    else
				[self updateAppBadge];
			}
		    }

		    [self updateHistory:[NSString stringWithUTF8String:incoming->from] 
			from:[NSString stringWithUTF8String: incoming->from] 
			message:[NSString stringWithUTF8String: incoming->body] 
			title:(([b getRFlag] != 1)?1:0) titlecolor:@"#50afca"];
		    
		    [b setRFlag];
		    
		    if ([myPrefs useSound])
			[[Notifications sharedInstance] playSound: 1];
		    if ([myPrefs useVibro])
			[[Notifications sharedInstance] vibrate];
		    
		    free(incoming->body);
		    free(incoming->from);
		    break;

		case SM_STREAMERROR:
		    [self logoffMyAccount];
		    [eyeCandy showStandardAlertWithString:NSLocalizedString(@"Error!", @"Error")
			    closeBtnTitle:@"Ok" 
			    withError:NSLocalizedString(@"Stream error. Check your network and try connect again.", @"Stream error")];
		    break;

    		case SM_UNHANDLED:
		    break;
		case SM_NODATA:
		    NSLog(@"No data received");
		    break;
		case SM_NEEDDATA:
		    NSLog(@"Incomplete read");
		    break;
    	    }
    	    free(incoming);
	} else if (x < 0) {
	
	    NSLog(@"select() error");
	    
	    if (errno != EINTR) {
		[self logoffMyAccount];
		[eyeCandy showStandardAlertWithString:NSLocalizedString(@"Error!", @"Error")
			closeBtnTitle:@"Ok" 
			withError:NSLocalizedString(@"Socket error. Check your network and try connect again.", @"Socket error")];
		return;
	    }
	}
	
	ping_counter--;
	
	if (ping_counter == (ping_interval / 4)) {
	    NSLog(@"Send ping");
	    srv_sendping(sock, [myPrefs useSSL]);
	} else if (!ping_counter) {
	    NSLog(@"BUMS! Network offline!");
	    [self logoffMyAccount];
	    [eyeCandy showStandardAlertWithString:NSLocalizedString(@"Error!", @"Error")
		    closeBtnTitle:@"Ok" 
		    withError:NSLocalizedString(@"Unable to get a response from remote server. Check your network and try connect again.", @"Timeout")];
	    return;
	}
    }

    -(int)isConnected {
	return connected;
    }

    - (id)initWithFrame:(CGRect) rect
    {
	if ((self == [super initWithFrame: rect]) == nil)
	    return self;

	buddyArray = [[NSMutableArray alloc] init];

	[[Notifications sharedInstance] setApp: self];	

	eyeCandy = [[[EyeCandy alloc] init] retain];

        transitionView = [[UITransitionView alloc] initWithFrame: rect];
        
	[self addSubview: transitionView];
	
	myPrefs   = [[MyPrefs alloc] initPrefs];
        usersView = [self UsersView];
        userView  = [[UserView alloc] init];
        newMsg    = [[NewMessage alloc] init];

	is = [IconSet initSharedInstance];

	currBuddy = nil;
	currPage  = myPrefs;
	
	connected = 0;

	ping_interval = 80 * 4;
	ping_counter = ping_interval;

	myTimer = [NSTimer scheduledTimerWithTimeInterval:(1.f / 4.f) target:self 
    		    selector:@selector(timer:) userInfo:nil repeats:YES];	

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

        [transitionView transition: 0 toView: myPrefs];
	
	return self;
    }

    +(id) initSharedInstanceWithFrame:(CGRect) rect
    {
	sharedInstanceiCabber = [[iCabberView alloc] initWithFrame:rect];
	return sharedInstanceiCabber;
    }

    +(id) sharedInstance
    {
	return sharedInstanceiCabber;
    }

    - (void) alertSheet: (UIAlertSheet*)sheet buttonClicked:(int)button
    {
	NSLog(@"MAIN alert butt %d\n", button);
	BuddyAction *b = [sheet context];
	if (b != nil) {
	    NSLog(@"jid=%@\n", [b getBuddy]);
	    NSLog(@"action=%d\n", [b getAction]);
	    
	    if (button == 1) {
		NSString *jid = [b getBuddy];
		srv_ReplyToSubscribe(sock, [jid UTF8String], 1, [myPrefs useSSL]);
		Buddy *theBuddy = [[Buddy alloc] initWithJID:jid
						     andName:jid
						     andGroup:@"New"];
		[buddyArray addObject: [theBuddy autorelease]];
		[self updateUsersTable];
	    } else if (button == 2) {
		srv_ReplyToSubscribe(sock, [[b getBuddy] UTF8String], 0, [myPrefs useSSL]);
	    }

	    [b release];
	}
	[sheet dismissAnimated: TRUE];
    }

    - (void) updateAfterResume
    {
	[newMsg updateView];
    }

@end

