#import "iCabberView.h"
#import "Buddy.h"
#import "BuddyAction.h"
#import "Notifications.h"
#import "IconSet.h"
#import "BuddyCell.h"
#import "resolveHostname.h"
#import "NSLogX.h"
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
	if (![[NetworkController sharedInstance] isNetworkUp]) {
	    if (![[NetworkController sharedInstance]isEdgeUp]) {
		NSLogX(@"Bring up edge");
		[[NetworkController sharedInstance] keepEdgeUp];
		[[NetworkController sharedInstance] bringUpEdge];
		sleep(5);
	    }
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
	    
	    NSLogX(@"Enable proxy %s:%s@%s:%d\n", user, password, host, port);
	    
    	    cw_setproxy(host, port, user, password);
	} else
	    cw_setproxy(NULL, 0, NULL, NULL);

	NSString *ipa = resolveHostname([myPrefs getServer]);

	if (ipa == nil)
	    return -1;
	
	NSLogX(@"Connection to %@...\n", ipa);
	if ((sock = srv_connect([[myPrefs getServer] UTF8String], [myPrefs getPort], [myPrefs useSSL])) < 0) {
	    NSLogX(@"Error conecting to (%@)\n", [myPrefs getServer]);
	    return -1;
	}
	NSLogX(@"Connected.\n");
	return 0;
    }

    - (int)loginToServer {
	char *idsession;
	const char *my_username = [[myPrefs getUsername] UTF8String];
	const char *my_password = [[myPrefs getPassword] UTF8String];
	const char *my_servername = [[myPrefs getServer] UTF8String];
	const char *my_resource = [[myPrefs getResource] UTF8String];

	if ((idsession = srv_login(sock, my_servername, my_username, my_password, my_resource, [myPrefs useSSL])) == NULL) {
	    NSLogX(@"Error sending login string...\n");
	    srv_close(sock, [myPrefs useSSL]);
	    return -1;
	}
	NSLogX(@"Connected to %s: %s\n", my_servername, idsession);
	free(idsession);
	return 0;
    }

    - (int)disconnectFromServer {
	srv_setpresence(sock, "", "unavailable", [myPrefs useSSL]);

	srv_close(sock, [myPrefs useSSL]);

	sock = -1;	
	
	return 0;
    }

    - (int)updateBuddies {
	char *roster = srv_getroster(sock, [myPrefs useSSL]);
	
	if (roster) {
	    char *aux;
	    [buddyArray removeAllObjects];
	    
	    NSLogX(@"[roster]: %s\n\n", roster);

	    while ((aux = ut_strrstr(roster, "<item")) != NULL) {
		char *jid = getattr(aux, "jid=");
		char *name = getattr(aux, "name=");
		char *group = gettag(aux, "group");

		if (name && (strlen(name) == 0)) {
		    free(name);
		    name = NULL;
		}

		NSLogX(@"[roster]: jid=%@, name=%@, group=%@", 
			[NSString stringWithUTF8String: jid], 
			[NSString stringWithUTF8String: ((name)?name:jid)], 
			[NSString stringWithUTF8String: ((group)?group:"Buddies")]
		      );
		
		*aux = '\0';
        	
		//NSLogX(@"JID %s\n", jid);

		NSMutableDictionary *user_dict = [NSMutableDictionary dictionaryWithContentsOfFile: USER_PREF_PATH([[NSString stringWithUTF8String: jid] lowercaseString])];
		if (user_dict == nil) {
		    user_dict = [[NSMutableDictionary alloc] init];
		    [user_dict setObject:[NSString stringWithUTF8String: ((name)?name:jid)] forKey:@"name"];
		    [user_dict setObject:[NSString stringWithUTF8String: jid] forKey:@"jid"];
		    [user_dict setObject:[NSString stringWithUTF8String: ((group)?group:"Buddies")] forKey:@"group"];
		    [user_dict setObject:@"0" forKey:@"newMessages"];
		    [user_dict writeToFile: USER_PREF_PATH([[NSString stringWithUTF8String: jid] lowercaseString]) atomically: TRUE];
		}
		
		int new_messages = [[user_dict objectForKey:@"newMessages"] intValue];

		
		if ([myPrefs offlineUsers] ||
		    new_messages) {

		    Buddy *theBuddy = [[Buddy alloc] initWithJID:[NSString stringWithUTF8String: jid]
						     andName:[NSString stringWithUTF8String: ((name)?name:jid)]
						     andGroup:[NSString stringWithUTF8String: ((group)?group:"Buddies")]];
		    [theBuddy setMsgCounter: new_messages];
		    [buddyArray addObject: [theBuddy autorelease]];
		}
		
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

	srv_setpresence(sock, "", "Online!", [myPrefs useSSL]);

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

	//NSLogX(@"send from [%@] to [%@] [%@]\n\n", from, to, msg);
	
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

	NSString *name = [NSString stringWithFormat:@"%@/%@", PATH, [[buddy getJID] lowercaseString]];

	//NSLogX(@"read history %@\n\n", name);

	NSFileHandle *inFile = [NSFileHandle fileHandleForReadingAtPath:name];

	if (inFile != nil) {
#if 1
	    NSData *fileData = [inFile readDataToEndOfFile];
	    NSString *tmp = [[NSString alloc] initWithData:fileData encoding:NSUTF8StringEncoding];
	    [fileData release];

	    if ([tmp length] > MAX_USERLOG_SIZE) {
		NSString *tmp1 = [[NSString alloc] initWithString: [tmp substringFromIndex: [tmp length] - MAX_USERLOG_SIZE]];
		NSRange r = [tmp1 rangeOfString:@"<br/><table>"];
		[tmp release];
		if (r.location != NSNotFound)
		    tmp = [[NSString alloc] initWithString: [tmp1 substringFromIndex:r.location]];
		else
		    tmp = [[NSString alloc] initWithString: @""];
		[tmp1 release];
	    }

	    NSString *tmp1 = [[IconSet sharedInstance] insertSmiles: tmp];
	    [userView setText: tmp1];
	    //[tmp1 release];
#else
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
		NSString *tmp = [[NSString alloc] initWithData:[[NSData alloc] initWithBytesNoCopy:(void *)ptr length: strlen(ptr)] encoding:NSUTF8StringEncoding];

		[userView setText: [[IconSet sharedInstance] insertSmiles: tmp]];
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
	//NSLogX(@"Stamp: %@", stamp);
	
	if (title)
	    _message = [NSString stringWithFormat:
	    @"<br/><table><tr><td width=320 bgcolor=%@><font color=#ffffff><b>%@<br/>%@</b></font></td></tr>"
	    "<tr><td width=320>%@</td></tr></table>",
	    titlecolor, stamp, from, message];
	else
	    _message = [NSString stringWithFormat:@"<table><tr><td width=320>%@</td></tr></table>", 
	    message];

	NSString *name = [NSString stringWithFormat:@"%@/%@", PATH, [username lowercaseString]];

	//NSLogX(@"write history %@\n\n", name);

	if (![[NSFileManager defaultManager] fileExistsAtPath:name])
	    [[NSFileManager defaultManager] createFileAtPath:name contents: nil attributes: nil];

	NSFileHandle *outFile = [NSFileHandle fileHandleForUpdatingAtPath:name];

	if (outFile != nil) {
	    [outFile seekToEndOfFile];

	    [outFile writeData:[NSData dataWithBytes:[_message UTF8String] length:[_message lengthOfBytesUsingEncoding:NSUTF8StringEncoding]]];
	    
	    [outFile closeFile];

	    if (currBuddy != nil)
		if ([[[currBuddy getJID] lowercaseString] isEqualToString:[username lowercaseString]]) {
		    [userView appendText: [[IconSet sharedInstance] insertSmiles: _message]];
		}
	}	
    }

    - (void)loginMyAccount2 {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	//NSLogX(@">>%s %s\n", [[myPrefs getUsername] UTF8String], [[myPrefs getPassword] UTF8String]);
	if (![self connectToServer]) {
	    [eyeCandy hideProgressHUD];
	    [eyeCandy showProgressHUD:NSLocalizedString(@"Authorization...", @"Authorization...") withView:self withRect:CGRectMake(0, 140, 320, 480 - 280)];
	    if (![self loginToServer]) {
		[self updateBuddies];
	    } else {
//		[eyeCandy hideProgressHUD];
		NSLogX(@"Can't login to server");
		/* handle login error here */
		connection_error = 2;
		[pool release];
		return;
	    }
	} else {
//	    [eyeCandy hideProgressHUD];
	    NSLogX(@"Can't connect to server");
	    /* handle connection error here */
	    connection_error = 1;
	    [pool release];
	    return;
	}
//	[eyeCandy hideProgressHUD];
	ping_counter = ping_interval;
	connected = 1;
	[pool release];
    }

    - (void)loginMyAccount {
	if (connection_started)
	    return;
	connection_started = 1;
	[eyeCandy showProgressHUD:NSLocalizedString(@"Connecting...", @"Connecting...") withView:self withRect:CGRectMake(0, 140, 320, 480 - 280)];
	connection_hud = 1;
	connection_error = 0;
	
	[NSThread detachNewThreadSelector:@selector(loginMyAccount2) toTarget:self withObject:nil];
    }
    
    - (void)logoffMyAccount {
	connected = 0;
	connection_started = 0;
	[self disconnectFromServer];
	[buddyArray removeAllObjects];
	[transitionView transition: 2 fromView: usersView toView: myPrefs];
	currPage = myPrefs;
	NSLogX(@"1-0");
    }

    - (void)navigationBar:(UINavigationBar *)navbar buttonClicked:(int)button {
	if (currPage == usersView) {
	    if (button == 0) {
		//[transitionView transition: 1 fromView: usersView toView: userView];
		//currPage = userView;
        	//NSLogX(@"1-2");
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

	    NSMutableDictionary *user_dict = [NSMutableDictionary dictionaryWithContentsOfFile: USER_PREF_PATH([buddy getJID])];
	    if(user_dict == nil) {
			user_dict = [[NSMutableDictionary alloc] init];
			[user_dict setObject:[buddy getName] forKey:@"name"];
			[user_dict setObject:[buddy getJID] forKey:@"jid"];
			[user_dict setObject:[buddy getGroup] forKey:@"group"];
			[user_dict setObject:@"0" forKey:@"newMessages"];
	    }
	    int new_messages = [[user_dict objectForKey:@"newMessages"] intValue];
	    if (new_messages != [buddy getMsgCounter]) {
		[user_dict setObject: [NSString stringWithFormat:@"%d", [buddy getMsgCounter]] forKey:@"newMessages"];
		[user_dict writeToFile: USER_PREF_PATH([buddy getJID]) atomically: TRUE];
	    }
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
	//NSLogX(@"JID %s\n", [[buddy getJID] UTF8String]);

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

    -(Buddy *)getOfflineBuddy:(NSString *)jid
    {
	NSMutableDictionary *user_dict = [NSMutableDictionary dictionaryWithContentsOfFile: USER_PREF_PATH([jid lowercaseString])];
	if (user_dict != nil) {
	    NSString *_jid   = [user_dict objectForKey:@"jid"];
	    NSString *_name  = [user_dict objectForKey:@"name"];
	    NSString *_group = [user_dict objectForKey:@"group"];
	    Buddy *buddy = [[Buddy alloc] initWithJID:  _jid
					  andName:	_name
				          andGroup: 	_group];
	    [buddyArray addObject: [buddy autorelease]];
	    return buddy;
	}
	return nil;
    }

    -(void)timer:(NSTimer *)aTimer
    {
	if (connection_error) {
	    [eyeCandy hideProgressHUD];
	    connection_started = 0;
	    switch (connection_error) {
	    case 1:
	    	[eyeCandy showStandardAlertWithString:NSLocalizedString(@"Error!", @"Error")
		    closeBtnTitle:@"Ok" 
		    withError:NSLocalizedString(@"Unable to connect to remote server. Check your network settings and try again.", @"Connection problem")
		];
		break;
	    case 2:
		[eyeCandy showStandardAlertWithString:NSLocalizedString(@"Error!", @"Error")
			closeBtnTitle:@"Ok" 
			withError:NSLocalizedString(@"Unable to login. Check your username and password.", @"Login problem")
		];
		break;
	    }
	    connection_error = 0;
	}

	if (!connected)
	    return;

	if (connection_hud) {
	    [eyeCandy hideProgressHUD];
	    [transitionView transition: 1 fromView: myPrefs toView: usersView];
	    currPage = usersView;
    	    NSLogX(@"0-1");
	    connection_hud = 0;
	}
	
	int x = check_io(sock, [myPrefs useSSL]);
	
	//NSLogX(@"IO %d\n", x);
	
	if (x > 0) {
	    Buddy *b;
	    
	    // reset ping counter
	    
	    ping_counter = ping_interval;
	    ping_errors = 0;
	    
		srv_msg *incoming = readserver(sock, [myPrefs useSSL]);
	    
		switch (incoming->m) {
			case SM_PRESENCE:
				NSLogX(@"Presence from %@", [[NSString stringWithUTF8String: incoming->from] lowercaseString]);
				b = [self getBuddy:[NSString stringWithUTF8String: incoming->from]];
				if (b == nil)
				    b = [self getOfflineBuddy:[NSString stringWithUTF8String: incoming->from]];
				if (b != nil) {
					[b setStatus:incoming->connected];
					if(incoming->body) {
					    [b setStatusText: [NSString stringWithUTF8String: incoming->body]];
					    free(incoming->body);
					} else
					    [b setStatusText: @""];
					//NSLogX(@"status ok");
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
		    NSLogX(@"Unsubscribe request from %@", jid);
		    free(incoming->from);
		    break;
		    }
		    
    		case SM_MESSAGE:
		    b = [self getBuddy:[NSString stringWithUTF8String: incoming->from]];
		    if (b == nil)
			b = [self getOfflineBuddy:[NSString stringWithUTF8String: incoming->from]];
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
		case SM_NODATA:
		    NSLogX(@"No data received");
		    //break;
		case SM_STREAMERROR:
		    [self logoffMyAccount];
		    [eyeCandy showStandardAlertWithString:NSLocalizedString(@"Error!", @"Error")
			    closeBtnTitle:@"Ok" 
			    withError:NSLocalizedString(@"Stream error. Check your network and try connect again.", @"Stream error")];
		    break;
    		case SM_UNHANDLED:
		    break;
		case SM_NEEDDATA:
		    NSLogX(@"Incomplete read");
		    break;
    	    }
    	    free(incoming);
	} else if (x < 0) {
	
	    NSLogX(@"select() error");
	    
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
	    NSLogX(@"Send ping");
	    srv_sendping(sock, [myPrefs useSSL]);
	} else if (!ping_counter) {
	    ping_errors++;
	    ping_counter = ping_interval;
	    NSLogX(@"Ping timeout %d\n", ping_errors);
	    if (ping_errors > 2) {
		NSLogX(@"BUMS! Network offline!");
		[self logoffMyAccount];
		[eyeCandy showStandardAlertWithString:NSLocalizedString(@"Error!", @"Error")
		    closeBtnTitle:@"Ok" 
		    withError:NSLocalizedString(@"Unable to get a response from remote server. Check your network and try connect again.", @"Timeout")];
		return;
	    }
	}
    }

    -(int)isConnected {
	return connected;
    }

    -(void)setStatus:(NSString *) status withText:(NSString *) message {
	if ([self isConnected])
	    srv_setpresence(sock, [status UTF8String], [message UTF8String], [myPrefs useSSL]);
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
	
	connection_started = 0;
	connected = 0;

	ping_interval = 80 * 5;
	ping_counter = ping_interval;
	ping_errors = 0;

	myTimer = [NSTimer scheduledTimerWithTimeInterval:(1.f / 5.f) target:self 
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
	NSLogX(@"MAIN alert butt %d\n", button);
	BuddyAction *b = [sheet context];
	if (b != nil) {
	    NSLogX(@"jid=%@\n", [b getBuddy]);
	    NSLogX(@"action=%d\n", [b getAction]);
	    
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

