#import "MyPrefs.h"
#import "iCabberView.h"
#import "NSLogX.h"
#import "lib/conf.h"

#define DEFAULT_PROXY_PORT 3124

@implementation MyPrefs
    -(void)changeSwitch {
	NSLogX(@"rere");
	[table reloadData];
    }

    -(id)initPrefs
    {
        CGRect rect = [UIHardware fullScreenApplicationContentRect];
        rect.origin = CGPointMake (0.0f, 0.0f);
	self = [super initWithFrame: rect];

	rect.origin.y = 0;
        rect.size.height = 48.0f;
        UINavigationBar *nav = [[UINavigationBar alloc] initWithFrame: rect];
        [nav pushNavigationItem: [[UINavigationItem alloc] initWithTitle:NSLocalizedString(@"Account", @"Account")]];

        // 0 = greay
        // 1 = red
        // 2 = left arrow
        // 3 = blue
        [nav showLeftButton:NSLocalizedString(@"About", @"About") withStyle:3 rightButton:NSLocalizedString(@"Login", @"Login") withStyle:3];

        [nav setDelegate: self];
	[nav setAutoresizesSubviews: YES];

	[self addSubview: nav];

	_username = [[UIPreferencesTextTableCell alloc] init];
	[_username setTitle:NSLocalizedString(@"Username", @"User")];
	[_username setValue:@""];
	[[_username textField] setAutoCapsType:0];

	_password = [[UIPreferencesTextTableCell alloc] init];
	[_password setTitle:NSLocalizedString(@"Password", @"Password")];
	[_password setValue:@""];
	[[_password textField] setSecure:YES];

	_use_gtalk = [[UIPreferencesControlTableCell alloc] init];
	[_use_gtalk setTitle:NSLocalizedString(@"Google Talk", @"GTalk")];
	UISwitchControl *switchControl = [[UISwitchControl alloc] initWithFrame:CGRectMake(200., 10., 50., 20.)];
	[switchControl addTarget:self action:@selector(changeSwitch) forEvents:(0xf00)];
	[_use_gtalk setControl:switchControl];
	[switchControl release];

	_server = [[UIPreferencesTextTableCell alloc] init];
	[_server setTitle:NSLocalizedString(@"Server", @"Server")];
	[_server setValue:@""];
	[[_server textField] setAutoCapsType:0];

	_port = [[UIPreferencesTextTableCell alloc] init];
	[_port setTitle:NSLocalizedString(@"Port", @"Port")];
	[_port setValue:@""];
	[[_port textField] setAutoCapsType:0];

	_use_ssl = [[UIPreferencesControlTableCell alloc] init];
	[_use_ssl setTitle:NSLocalizedString(@"SSL", @"SSL")];
	switchControl = [[UISwitchControl alloc] initWithFrame:CGRectMake(200., 10., 50., 20.)];
	[_use_ssl setControl:switchControl];
	[switchControl release];

	_use_ssl_verify = [[UIPreferencesControlTableCell alloc] init];
	[_use_ssl_verify setTitle:NSLocalizedString(@"SSL verify", @"SSL verify")];
	switchControl = [[UISwitchControl alloc] initWithFrame:CGRectMake(200., 10., 50., 20.)];
	[_use_ssl_verify setControl:switchControl];
	[switchControl release];

	_proxy_enable = [[UIPreferencesControlTableCell alloc] init];
	[_proxy_enable setTitle:NSLocalizedString(@"Proxy", @"Proxy")];
	switchControl = [[UISwitchControl alloc] initWithFrame:CGRectMake(200., 10., 50., 20.)];
	[switchControl addTarget:self action:@selector(changeSwitch) forEvents:(0xf00)];
	[_proxy_enable setControl:switchControl];
	[switchControl release];

	_proxy_host = [[UIPreferencesTextTableCell alloc] init];
	[_proxy_host setTitle:NSLocalizedString(@"Server", @"Server")];
	[_proxy_host setValue:@""];
	[[_proxy_host textField] setAutoCapsType:0];

	_proxy_port = [[UIPreferencesTextTableCell alloc] init];
	[_proxy_port setTitle:NSLocalizedString(@"Port", @"Port")];
	[_proxy_port setValue:@""];
	[[_proxy_port textField] setAutoCapsType:0];

	_proxy_username = [[UIPreferencesTextTableCell alloc] init];
	[_proxy_username setTitle:NSLocalizedString(@"Username", @"User")];
	[_proxy_username setValue:@""];
	[[_proxy_username textField] setAutoCapsType:0];

	_proxy_password = [[UIPreferencesTextTableCell alloc] init];
	[_proxy_password setTitle:NSLocalizedString(@"Password", @"Password")];
	[_proxy_password setValue:@""];
	[[_proxy_password textField] setSecure:YES];

	_sound_enable = [[UIPreferencesControlTableCell alloc] init];
	[_sound_enable setTitle:NSLocalizedString(@"Sound Alerts", @"Sound")];
	switchControl = [[UISwitchControl alloc] initWithFrame:CGRectMake(200., 10., 50., 20.)];
	[_sound_enable setControl:switchControl];
	[switchControl release];

	_vibro_enable = [[UIPreferencesControlTableCell alloc] init];
	[_vibro_enable setTitle:NSLocalizedString(@"Vibro Alerts", @"Vibro")];
	switchControl = [[UISwitchControl alloc] initWithFrame:CGRectMake(200., 10., 50., 20.)];
	[_vibro_enable setControl:switchControl];
	[switchControl release];

        rect = [UIHardware fullScreenApplicationContentRect];
        rect.origin = CGPointMake (0.0f, 48.0f);
        rect.size.height -= 48.0f;
	table = [[UIPreferencesTable alloc] initWithFrame:rect];
	[table setDataSource:self];
	[table setDelegate:self];
	[table reloadData];

	[self addSubview:table];

	dirPath = [[NSString alloc] initWithString:[NSHomeDirectory() stringByAppendingPathComponent:@CFGDIR]];
	if (![[NSFileManager defaultManager] fileExistsAtPath:dirPath])
	{
		NSLogX(@"had to create directory.");
		[[NSFileManager defaultManager] createDirectoryAtPath:dirPath attributes:nil];
	}

	[self loadConfig];

	eyeCandy = [[[EyeCandy alloc] init] retain];

	return self;
    }

    - (void)loadConfig {
	NSMutableDictionary *user_dict = [NSMutableDictionary dictionaryWithContentsOfFile: GLOBAL_PREF_PATH];
	if (user_dict == nil) {
	    user_dict = [[NSMutableDictionary alloc] init];
	    [user_dict setObject:@"" forKey:@"username"];
	    [user_dict setObject:@"" forKey:@"password"];
	    [user_dict setObject:@"" forKey:@"server"];
	    [user_dict setObject:@"" forKey:@"port"];
	    [user_dict setObject:@"0" forKey:@"useSSL"];
	    [user_dict setObject:@"0" forKey:@"SSLVerify"];
	    [user_dict setObject:@"0" forKey:@"useGTalk"];
	    [user_dict setObject:@"" forKey:@"proxyHost"];
	    [user_dict setObject:@"" forKey:@"proxyPort"];
	    [user_dict setObject:@"" forKey:@"proxyUsername"];
	    [user_dict setObject:@"" forKey:@"proxyPassword"];
	    [user_dict setObject:@"0" forKey:@"proxyEnabled"];
	    [user_dict setObject:@"0" forKey:@"soundEnabled"];
	    [user_dict setObject:@"0" forKey:@"vibroEnabled"];
	    [user_dict writeToFile: GLOBAL_PREF_PATH atomically: TRUE];
	}

#define  _S(obj, str) [obj setValue:[user_dict objectForKey: str]]
#define _SI(obj, str) [obj setValue:[[user_dict objectForKey: str] intValue]]

	_S (_username,	@"username");
	_S (_password,	@"password");
	_S (_server,	@"server");
	_S (_port,	@"port");
	
	UISwitchControl* sw = [_use_ssl control];
	_SI(sw,		@"useSSL");
	sw = [_use_ssl_verify control];
	_SI(sw,		@"SSLVerify");
	sw = [_use_gtalk control];
	_SI(sw,		@"useGTalk");
	
	_S(_proxy_host, @"proxyHost");
	_S(_proxy_port, @"proxyPort");
	_S(_proxy_username, @"proxyUsername");
	_S(_proxy_password, @"proxyPassword");

	sw = [_proxy_enable control];
	_SI(sw,		@"proxyEnabled");
	sw = [_sound_enable control];
	_SI(sw,		@"soundEnabled");
	sw = [_vibro_enable control];
	_SI(sw,		@"vibroEnabled");

#undef _S
#undef _SI

	[table reloadData];
    }
    
    - (void)saveConfig {
	NSMutableDictionary *user_dict = [[NSMutableDictionary alloc] init];

#define  _G(obj, str) [user_dict setObject: [[obj textField] text] forKey: str]
#define _GI(obj, str) [user_dict setObject: ([obj value] == 1.0f)?@"1":@"0" forKey: str]

	_G(_username,	@"username");
	_G(_password,	@"password");
	_G(_server,	@"server");
	_G(_port,	@"port");

	UISwitchControl* sw = [_use_ssl control];
	_GI(sw,		@"useSSL");
	sw = [_use_ssl_verify control];
	_GI(sw,		@"SSLVerify");
	sw = [_use_gtalk control];
	_GI(sw,		@"useGTalk");

	_G(_proxy_host,	@"proxyHost");
	_G(_proxy_port,	@"proxyPort");
	_G(_proxy_username, @"proxyUsername");
	_G(_proxy_password, @"proxyPassword");

	sw = [_proxy_enable control];
	_GI(sw,		@"proxyEnabled");
	sw = [_sound_enable control];
	_GI(sw,		@"soundEnabled");
	sw = [_vibro_enable control];
	_GI(sw,		@"vibroEnabled");

	[user_dict writeToFile: GLOBAL_PREF_PATH atomically: TRUE];

#undef _G
#undef _GI

    }

    - (void)reloadData
    {
    	[table reloadData];
    }

    - (NSString *) getUsername
    {
	return [[_username textField] text];
    }

    - (NSString *) getPassword
    {
	return [[_password textField] text];
    }

    - (NSString *) getResource
    {
	return @"itouchabber";
    }

    - (NSString *) getServer
    {
	UISwitchControl* sw = [_use_gtalk control];
	if ([sw value] == 1.0f)
	    return @"talk.google.com";
	else
	    return [[_server textField] text];
    }
    
    - (int) getPort
    {
	UISwitchControl* sw = [_use_gtalk control];
	if ([sw value] == 1.0f)
	    return 5223;

	sw = [_use_ssl control];
	if ([sw value] == 1.0f)
	    return 5223;
	else
	    return 5222;	
    }

    - (int) useSSL
    {
	UISwitchControl* sw = [_use_gtalk control];
	if ([sw value] == 1.0f)
	    return 1;

	sw = [_use_ssl control];
	if ([sw value] == 1.0f)
	    return 1;
	else
	    return 0;
    }

    - (int) useSSLVerify
    {
	UISwitchControl* sw = [_use_gtalk control];
	if ([sw value] == 1.0f)
	    return 0;

	sw = [_use_ssl_verify control];
	if ([sw value] == 1.0f)
	    return 1;
	else
	    return 0;
    }

    - (int) useProxy
    {
	UISwitchControl* sw = [_proxy_enable control];
	if ([sw value] == 1.0f)
	    return 1;
	else
	    return 0;
    }
    
    - (NSString *) getProxyServer
    {
	return [[_proxy_host textField] text];
    }
    
    - (int) getProxyPort
    {
	NSString *thePort = [[_proxy_port textField] text];
	int port = [thePort intValue];
	if ((port < 1) || (port > 65535)) {
	    NSLogX(@"Bad proxy port value\n");
	    port = DEFAULT_PROXY_PORT;
	}
	return port;
    }
    
    - (NSString *) getProxyUser
    {
	return [[_proxy_username textField] text];
    }
    
    - (NSString *) getProxyPassword
    {
	return [[_proxy_password textField] text];
    }

    - (int) useSound
    {
	UISwitchControl* sw = [_sound_enable control];
	if ([sw value] == 1.0f)
	    return 1;
	else
	    return 0;
    }

    - (int) useVibro;
    {
	UISwitchControl* sw = [_vibro_enable control];
	if ([sw value] == 1.0f)
	    return 1;
	else
	    return 0;
    }

    - (void)tableRowSelected:(NSNotification *)notification
    {
	//NSLogX(@"selected row %d %s\n", [table selectedRow], [[[_username textField] text] UTF8String]);
	//NSLogX(@"selected row %s\n", zz);
    }


    - (int)numberOfGroupsInPreferencesTable:(UIPreferencesTable *)table
    {
	return 3;
    }

    - (int)preferencesTable:(UIPreferencesTable *)table numberOfRowsInGroup:(int)group
    {
	UISwitchControl* sw;
	switch (group) {
	    case 0:
		sw = [_use_gtalk control];
		return ([sw value] == 0.0f)?5:3;
	    case 1:
		sw = [_proxy_enable control];
		return ([sw value] == 0.0f)?1:5;
	    case 2:
		return 2;
	}
    }

    - (UIPreferencesTableCell *)preferencesTable:(UIPreferencesTable *)table cellForGroup:(int)group
    {	
	UIPreferencesTableCell *cell = [[UIPreferencesTableCell alloc] init];
	
	return [cell autorelease];
    }

    - (UIPreferencesTableCell *)preferencesTable:(UIPreferencesTable *)table cellForRow:(int)row inGroup:(int)group
    {
	if (group == 0) {
	    switch(row) {
		case 0:
		    return _username;
		case 1:
		    return _password;
		case 2:
		    return _use_gtalk;
		case 3:
		    return _server;
//		case 4:
//		    return _port;
		case 4:
		    return _use_ssl;
//		case 5:
//		    return _use_ssl_verify;
	    }
	} else if (group == 1) {
	    switch(row) {
	    case 0:
		return _proxy_enable;
	    case 1:
		return _proxy_host;
	    case 2:
		return _proxy_port;
	    case 3:
		return _proxy_username;
	    case 4:
		return _proxy_password;
	    }
	} else if (group == 2) {
	    switch(row) {
	    case 0:
		return _sound_enable;
	    case 1:
		return _vibro_enable;
	    }
	}
	return nil;
    }

    - (void)navigationBar:(UINavigationBar *)navbar buttonClicked:(int)button {
	if (button == 0) {
	    //NSLogX(@">>%s %s\n", [[self getUsername] UTF8String], [[self getPassword] UTF8String]);
		
	    [self saveConfig];
		
	    /* Connect here */

	    [[iCabberView sharedInstance] loginMyAccount];
	} else if (button == 1) {
	    [eyeCandy showAlertWithTitle:@"iChabber "APP_VERSION
		closeBtnTitle:@"Ok" 
		withText:NSLocalizedString(@"Simple gtalk/jabber client for the ipod touch and iphone.\n2008 (c) sashz <sashz@pdaXrom.org>", @"About")
		andStyle:2];
	}
    }

    -(void)dealloc
    {
	[_username release];
	[_password release];
	[_server release];
	[_port release];
	[_use_ssl release];
	[_use_ssl_verify release];
	[_use_gtalk release];
	[_proxy_host release];
	[_proxy_port release];
	[_proxy_username release];
	[_proxy_password release];
	[_proxy_enable release];
	[table release];
	[eyeCandy release];
	[super dealloc];
    }

@end

