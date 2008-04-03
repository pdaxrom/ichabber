#import "MyPrefs.h"
#import "lib/conf.h"

#define DEFAULT_PROXY_PORT 3124

@implementation MyPrefs

    -(id)initWithFrame:(struct CGRect)frame
    {
	self = [super initWithFrame: frame];

	CGRect rect = [UIHardware fullScreenApplicationContentRect];
	//NSLog (@"::: %f, %f, %f, %f\n\n", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);

        rect.origin = CGPointMake (0.0f, 0.0f);
        rect.size.height -= 48;

	_username = [[UIPreferencesTextTableCell alloc] init];
	[_username setTitle:@"Username"];
	[_username setValue:@""];
	[[_username textField] setAutoCapsType:0];

	_password = [[UIPreferencesTextTableCell alloc] init];
	[_password setTitle:@"Password"];
	[_password setValue:@""];
	[[_password textField] setSecure:YES];

	_use_gtalk = [[UIPreferencesControlTableCell alloc] init];
	[_use_gtalk setTitle:@"Google Talk"];
	UISwitchControl *switchControl = [[UISwitchControl alloc] initWithFrame:CGRectMake(200., 10., 50., 20.)];
	[_use_gtalk setControl:switchControl];
	[switchControl release];

	_server = [[UIPreferencesTextTableCell alloc] init];
	[_server setTitle:@"Server"];
	[_server setValue:@""];
	[[_server textField] setAutoCapsType:0];

	_port = [[UIPreferencesTextTableCell alloc] init];
	[_port setTitle:@"Port"];
	[_port setValue:@""];
	[[_port textField] setAutoCapsType:0];

	_use_ssl = [[UIPreferencesControlTableCell alloc] init];
	[_use_ssl setTitle:@"SSL"];
	switchControl = [[UISwitchControl alloc] initWithFrame:CGRectMake(200., 10., 50., 20.)];
	[_use_ssl setControl:switchControl];
	[switchControl release];

	_use_ssl_verify = [[UIPreferencesControlTableCell alloc] init];
	[_use_ssl_verify setTitle:@"SSL verify"];
	switchControl = [[UISwitchControl alloc] initWithFrame:CGRectMake(200., 10., 50., 20.)];
	[_use_ssl_verify setControl:switchControl];
	[switchControl release];

	_proxy_enable = [[UIPreferencesControlTableCell alloc] init];
	[_proxy_enable setTitle:@"Proxy"];
	switchControl = [[UISwitchControl alloc] initWithFrame:CGRectMake(200., 10., 50., 20.)];
	[_proxy_enable setControl:switchControl];
	[switchControl release];

	_proxy_host = [[UIPreferencesTextTableCell alloc] init];
	[_proxy_host setTitle:@"Server"];
	[_proxy_host setValue:@""];
	[[_proxy_host textField] setAutoCapsType:0];

	_proxy_port = [[UIPreferencesTextTableCell alloc] init];
	[_proxy_port setTitle:@"Port"];
	[_proxy_port setValue:@""];
	[[_proxy_port textField] setAutoCapsType:0];

	_proxy_username = [[UIPreferencesTextTableCell alloc] init];
	[_proxy_username setTitle:@"Username"];
	[_proxy_username setValue:@""];
	[[_proxy_username textField] setAutoCapsType:0];

	_proxy_password = [[UIPreferencesTextTableCell alloc] init];
	[_proxy_password setTitle:@"Password"];
	[_proxy_password setValue:@""];
	[[_proxy_password textField] setSecure:YES];

	table = [[UIPreferencesTable alloc] initWithFrame:rect];
	[table setDataSource:self];
	[table setDelegate:self];
	[table reloadData];

	[self addSubview:table];

	dirPath = [[NSString alloc] initWithString:[NSHomeDirectory() stringByAppendingPathComponent:@CFGDIR]];
	if (![[NSFileManager defaultManager] fileExistsAtPath:dirPath])
	{
		NSLog(@"had to create directory.");
		[[NSFileManager defaultManager] createDirectoryAtPath:dirPath attributes:nil];
	}

	return self;
    }

    - (void)loadConfig {
	char conf[256];
	char data[256];

	strcpy(conf, [dirPath UTF8String]);
	strcat(conf, "/");
	strcat(conf, CFGNAME);

#define _S(obj, str) [obj setValue:[NSString stringWithUTF8String: str]]
	
	if (readconf(conf, "username", data))
	    _S(_username, data);
	if (readconf(conf, "password", data))
	    _S(_password, data);
	if (readconf(conf, "server", data))
	    _S(_server, data);
	if (readconf(conf, "port", data))
	    _S(_port, data);

	if (readconf(conf, "use_ssl", data)) {
	    UISwitchControl* sw = [_use_ssl control];
	    if (!strcmp(data, "yes"))
		[sw setValue:1.0f];
	    else
		[sw setValue:0.0f];
	}

	if (readconf(conf, "ssl_verify", data)) {
	    UISwitchControl* sw = [_use_ssl_verify control];
	    if (!strcmp(data, "yes"))
		[sw setValue:1.0f];
	    else
		[sw setValue:0.0f];
	}

	if (readconf(conf, "use_gtalk", data)) {
	    UISwitchControl* sw = [_use_gtalk control];
	    if (!strcmp(data, "yes"))
		[sw setValue:1.0f];
	    else
		[sw setValue:0.0f];
	}

	if (readconf(conf, "proxy_host", data))
	    _S(_proxy_host, data);
	if (readconf(conf, "proxy_port", data))
	    _S(_proxy_port, data);
	if (readconf(conf, "proxy_username", data))
	    _S(_proxy_username, data);
	if (readconf(conf, "proxy_password", data))
	    _S(_proxy_password, data);

	if (readconf(conf, "proxy_enabled", data)) {
	    UISwitchControl* sw = [_proxy_enable control];
	    if (!strcmp(data, "yes"))
		[sw setValue:1.0f];
	    else
		[sw setValue:0.0f];
	}

#undef _STR
    }
    
    - (void)saveConfig {
	char conf[256];
	
	strcpy(conf, [dirPath UTF8String]);
	strcat(conf, "/");
	strcat(conf, CFGNAME);

#define _G(obj) ((char *)[[[obj textField] text] UTF8String])

	writeconf(conf, "username", _G(_username), 1);
	writeconf(conf, "password", _G(_password), 0);
	writeconf(conf, "server", _G(_server), 0);
	writeconf(conf, "port", _G(_port), 0);

	UISwitchControl* sw = [_use_ssl control];
	writeconf(conf, "use_ssl", ([sw value] == 1.0f)?"yes":"no", 0);
	sw = [_use_ssl_verify control];
	writeconf(conf, "ssl_verify", ([sw value] == 1.0f)?"yes":"no", 0);
	sw = [_use_gtalk control];
	writeconf(conf, "use_gtalk", ([sw value] == 1.0f)?"yes":"no", 0);

	writeconf(conf, "proxy_host", _G(_proxy_host), 0);
	writeconf(conf, "proxy_port", _G(_proxy_port), 0);
	writeconf(conf, "proxy_username", _G(_proxy_username), 0);
	writeconf(conf, "proxy_password", _G(_proxy_password), 0);

	sw = [_proxy_enable control];
	writeconf(conf, "proxy_enabled", ([sw value] == 1.0f)?"yes":"no", 0);

#undef _G
    }

    - (NSString *)getConfigDir {
	return dirPath;
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
	    NSLog(@"Bad proxy port value\n");
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

    - (void)tableRowSelected:(NSNotification *)notification
    {
	//NSLog(@"selected row %d %s\n", [table selectedRow], [[[_username textField] text] UTF8String]);
	//NSLog(@"selected row %s\n", zz);
    }


    - (int)numberOfGroupsInPreferencesTable:(UIPreferencesTable *)table
    {
	return 2;
    }

    - (int)preferencesTable:(UIPreferencesTable *)table numberOfRowsInGroup:(int)group
    {
	switch (group) {
	    case 0:
		return 5;
	    case 1:
		return 5;
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
	}
	return nil;
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
	[super dealloc];
    }

@end

