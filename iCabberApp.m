#import "iCabberApp.h"
#import "Buddy.h"
#import "BuddyAction.h"
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

int buddy_compare_status(id left, id right, void * context)
{
    int l = [left getStatus];
    int r = [right getStatus];
    
    if (l && (!r))
	return -1;
    if ((!l) && r)
	return 1;
	
    return [[left getName] localizedCaseInsensitiveCompare:[right getName]];
}

@implementation iCabberApp
    - (int)connectToServer {
	int try = 10; // try connect 10 times
	
	if ([myPrefs useProxy]) {
	    const char *host = [[myPrefs getProxyServer] UTF8String];
	    int port = [myPrefs getProxyPort];
	    const char *user = [[myPrefs getProxyUser] UTF8String];
	    const char *password = [[myPrefs getProxyPassword] UTF8String];
	    
	    NSLog(@"Enable proxy %s:%s@%s:%d\n", user, password, host, port);
	    
    	    cw_setproxy(host, port, user, password);
	} else
	    cw_setproxy(NULL, 0, NULL, NULL);
	
	while(1) {
	    NSLog(@"Connection...\n");
	    if ((sock = srv_connect([[myPrefs getServer] UTF8String], [myPrefs getPort], [myPrefs useSSL])) < 0) {
		NSLog(@"Error conecting to (%@)\n", [myPrefs getServer]);
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
	
	[buddyArray sortUsingFunction:buddy_compare_status context:nil];

	[usersTable reloadData];

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

	[[Notifications sharedInstance] playSound: 0];
	
	[self updateHistory:to from:my_username message:msg 
	    title:(([currBuddy getRFlag] == 0)?0:1) titlecolor:@"#696969"];
	
	[currBuddy clrRFlag];
    }

    -(void)prepareLogin
    {
	[myPrefs loadConfig];
    }

    -(void)saveLoginSettings
    {
	[myPrefs saveConfig];
    }

    - (void)updateUserView:(NSString *)username {
	[userText setHTML:@""];
	[userViewNavItem setTitle:username];

	NSString *name = [NSString stringWithFormat:@"%@/%@", [myPrefs getConfigDir], [username lowercaseString]];

	//NSLog(@"read history %@\n\n", name);

	NSFileHandle *inFile = [NSFileHandle fileHandleForReadingAtPath:name];

	if (inFile != nil) {
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
		NSString *tmp = [[NSString alloc] initWithData:[[NSData alloc] initWithBytesNoCopy:(void *)ptr length:(MAX_USERLOG_SIZE - (ptr - data))] encoding:NSUTF8StringEncoding];

		[userText setHTML: tmp];
		[userText scrollPointVisibleAtTopLeft:CGPointMake(0, 9999999) animated:NO];
	    }
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
		    [userText setHTML: [NSString stringWithFormat:@"%@%@", [userText HTML], _message]];
		    [userText scrollPointVisibleAtTopLeft:CGPointMake(0, 9999999) animated:YES];
		}
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
		[eyeCandy showAlertWithTitle:@"About"
			closeBtnTitle:@"Ok" 
			withText:@"Simple gtalk/jabber client for the ipod touch and iphone.\n2008 (c) sashz <sashz@pdaXrom.org>"
			andStyle:2];
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
        	NSLog(@"pre3-2");
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
        UINavigationBar *userViewNav = [[UINavigationBar alloc] initWithFrame: rect];
	userViewNavItem = [[UINavigationItem alloc] initWithTitle:@"History"];
        [userViewNav pushNavigationItem: userViewNavItem];
        [userViewNav showButtonsWithLeftTitle:@"Back" rightTitle: @"Reply" leftBack: YES];
        [userViewNav setDelegate: self];
        [userViewNav setBarStyle: 0];

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
        [mainView addSubview: userViewNav];

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

	[self updateUserView:[buddy getJID]];

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
			[buddyArray sortUsingFunction:buddy_compare_status context:nil];
			[usersTable reloadData];
		    }
		    free(incoming->from);
		    break;

		case SM_SUBSCRIBE: {
		    NSString *jid = [NSString stringWithUTF8String: incoming->from];
		    [eyeCandy showAlertYesNoWithTitle:@"Request received" 
			      withText:[NSString stringWithFormat:@"Do you want to add user %@ to buddies?", jid] 
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
		    [[Notifications sharedInstance] playSound: 1];
		    
		    b = [self getBuddy:[NSString stringWithUTF8String: incoming->from]];
		    if (b != nil) {
			if (b != currBuddy) {
			    [b incMsgCounter];
			    if ([b getMsgCounter] < 2)
				[usersTable reloadData];
			}
		    }

		    [self updateHistory:[NSString stringWithUTF8String:incoming->from] 
			from:[NSString stringWithUTF8String: incoming->from] 
			message:[NSString stringWithUTF8String: incoming->body] 
			title:(([b getRFlag] != 1)?1:0) titlecolor:@"#50afca"];
		    
		    [b setRFlag];
		    
		    free(incoming->body);
		    free(incoming->from);
		    break;

		case SM_STREAMERROR:
		    [self logoffMyAccount];
		    [eyeCandy showStandardAlertWithString:@"Error!"
			    closeBtnTitle:@"Ok" 
			    withError:@"Stream error. Check your network and try connect again."];
		    break;

    		case SM_UNHANDLED:
		    break;
    	    }
    	    free(incoming);
	} else if (x < 0) {
	
	    NSLog(@"select() error");
	    
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
	    NSLog(@"Send ping");
	    srv_sendping(sock, [myPrefs useSSL]);
	} else if (!ping_counter) {
	    NSLog(@"BUMS! Network offline!");
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

	ping_interval = 80 * 4;
	ping_counter = ping_interval;

	myTimer = [NSTimer scheduledTimerWithTimeInterval:(1.f / 4.f) target:self 
    		    selector:@selector(timer:) userInfo:nil repeats:YES];		    
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
		[buddyArray sortUsingFunction:buddy_compare_status context:nil];
		[usersTable reloadData];
	    } else if (button == 2) {
		srv_ReplyToSubscribe(sock, [[b getBuddy] UTF8String], 0, [myPrefs useSSL]);
	    }

	    [b release];
	}
	[sheet dismissAnimated: TRUE];
}

@end

