#import "iLocatorApp.h"

static CTServerConnectionRef connection;
static CFMachPortRef ref;
static mach_port_t tl;
static mach_port_t tx;

static int  callback(void *connection, CFStringRef string, CFDictionaryRef dictionary, void *data);
static void sourcecallback ( CFMachPortRef port, void *msg, CFIndex size, void *info);

static int callback(void *connection, CFStringRef string, CFDictionaryRef dictionary, void *data) {
    NSLog(@"callback (but it never calls me back :( ))\n");
    return 0;
}

static void sourcecallback ( CFMachPortRef port, void *msg, CFIndex size, void *info)
{
    NSLog(@"Source called back\n");
}

@implementation iLocatorApp

-(void)dealloc
{
    [super dealloc];
}

-(void)addLocationFromPacket:(NSMutableArray *) packet
{

    NSString *name = [[NSString alloc] initWithString:@"/tmp/iLocator.txt"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:name])
	[[NSFileManager defaultManager] createFileAtPath:name contents: nil attributes: nil];

    NSFileHandle *outFile = [NSFileHandle fileHandleForUpdatingAtPath:name];

    if (outFile != nil) {
	    [outFile seekToEndOfFile];

	    int count = [packet count];
	    NSLog(@"count=%d", count);
	    int i;
	    for (i = 0; i < count; i++) {
		LLData *d = [packet objectAtIndex: i];
		NSString *_message = [NSString stringWithFormat:@"%@ lat=%f lon=%f\n",
			    	[[d getDate] descriptionWithCalendarFormat: 
				    @"%b %d, %Y %I:%M %p" 
				    timeZone:nil locale:nil
				],
				[d getLat],
				[d getLon]
			];
		[outFile writeData:[NSData dataWithBytes:[_message UTF8String] length:[_message lengthOfBytesUsingEncoding:NSUTF8StringEncoding]]];
	    }
	    [outFile closeFile];
    }
}

-(LLData *)showLocationWithMNC:(int) MNC andMCC:(int) MCC andCID:(int) CID andLAC:(int) LAC
{	
    char pd[] = {
	0x00, 0x0e,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00,
	0x00, 0x00,
	0x00, 0x00,

	0x1b, 
	0x00, 0x00, 0x00, 0x00, // Offset 0x11
	0x00, 0x00, 0x00, 0x00, // Offset 0x15
	0x00, 0x00, 0x00, 0x00, // Offset 0x19
	0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, // Offset 0x1f
	0x00, 0x00, 0x00, 0x00, // Offset 0x23
	0x00, 0x00, 0x00, 0x00, // Offset 0x27
	0x00, 0x00, 0x00, 0x00, // Offset 0x2b
	0xff, 0xff, 0xff, 0xff,
	0x00, 0x00, 0x00, 0x00
    };

    if (CID > 65535)
	pd[0x1c] = 5;
    else {
	pd[0x1c] = 3;
	CID &= 0xffff;
    }

    pd[0x11] = (unsigned char)((MNC >> 24) & 0xFF);
    pd[0x12] = (unsigned char)((MNC >> 16) & 0xFF);
    pd[0x13] = (unsigned char)((MNC >> 8) & 0xFF);
    pd[0x14] = (unsigned char)((MNC >> 0) & 0xFF);

    pd[0x15] = (unsigned char)((MCC >> 24) & 0xFF);
    pd[0x16] = (unsigned char)((MCC >> 16) & 0xFF);
    pd[0x17] = (unsigned char)((MCC >> 8) & 0xFF);
    pd[0x18] = (unsigned char)((MCC >> 0) & 0xFF);

    pd[0x27] = (unsigned char)((MNC >> 24) & 0xFF);
    pd[0x28] = (unsigned char)((MNC >> 16) & 0xFF);
    pd[0x29] = (unsigned char)((MNC >> 8) & 0xFF);
    pd[0x2a] = (unsigned char)((MNC >> 0) & 0xFF);

    pd[0x2b] = (unsigned char)((MCC >> 24) & 0xFF);
    pd[0x2c] = (unsigned char)((MCC >> 16) & 0xFF);
    pd[0x2d] = (unsigned char)((MCC >> 8) & 0xFF);
    pd[0x2e] = (unsigned char)((MCC >> 0) & 0xFF);

    pd[0x1f] = (unsigned char)((CID >> 24) & 0xFF);
    pd[0x20] = (unsigned char)((CID >> 16) & 0xFF);
    pd[0x21] = (unsigned char)((CID >> 8) & 0xFF);
    pd[0x22] = (unsigned char)((CID >> 0) & 0xFF);

    pd[0x23] = (unsigned char)((LAC >> 24) & 0xFF);
    pd[0x24] = (unsigned char)((LAC >> 16) & 0xFF);
    pd[0x25] = (unsigned char)((LAC >> 8) & 0xFF);
    pd[0x26] = (unsigned char)((LAC >> 0) & 0xFF);

    NSString *url = [NSString stringWithFormat:@"http://google.com/glm/mmap"];

    NSLog(@"String is (%@) req len %d", url, sizeof(pd));

    NSURL *theURL = [NSURL URLWithString:url];
	
    NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:theURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:1000.0f];
    [theRequest setHTTPMethod:@"POST"];

    NSData *body = [[NSData alloc] initWithBytes:pd length:sizeof(pd)];

//    NSString *contentLen = [NSString stringWithFormat:@"%d", [body length]];
//    [theRequest addValue:contentLen  forHTTPHeaderField:@"Content-Length"];
    NSString *contentType = [NSString stringWithFormat:@"application/binary"];
    [theRequest addValue:contentType forHTTPHeaderField: @"Content-Type"];

    [theRequest setHTTPBody: body];

    NSURLResponse *theResponse = NULL;
    NSError *theError = NULL;
    NSData *theResponseData = [NSURLConnection sendSynchronousRequest:theRequest returningResponse:&theResponse error:&theError];
    NSLog(@"response len %d", [theResponseData length]);

    unsigned char *ps = [theResponseData bytes];
    short opcode1 = (short)(ps[0] << 8 | ps[1]);
    unsigned char opcode2 = ps[2];
    int ret_code = (int)((ps[3] << 24) | (ps[4] << 16) | (ps[5] << 8) | (ps[6]));
    if ((opcode1 == 0x0e) &&
	(opcode2 == 0x1b) &&
	(ret_code == 0)) {
	double lat = ((double)((ps[7] << 24) | (ps[8] << 16) | (ps[9] << 8) | (ps[10]))) / 1000000;
	double lon = ((double)((ps[11] << 24) | (ps[12] << 16) | (ps[13] << 8) | (ps[14]))) / 1000000;
	NSLog(@"Latitude %f, Longtitude %f\n", lat, lon);
	//[self addLocationWithLat: lat andLon: lon andDate: [[NSDate alloc] init]];
	return [[LLData alloc] initWithLat: lat andLon: lon andDate: [[NSDate alloc] init]];
    } else {
	NSLog(@"opcode1=%04X", opcode1);
	NSLog(@"opcode2=%02X", opcode1);
	NSLog(@"ret_cod=%d", ret_code);
	NSLog(@"Can't get GPS data");
    }
    return nil;
}

-(void)cellConnect
{
    connection = _CTServerConnectionCreate(kCFAllocatorDefault, callback, NULL);

    CFMachPortContext  context = { 0, 0, NULL, NULL, NULL };

    ref = CFMachPortCreateWithPort(kCFAllocatorDefault, _CTServerConnectionGetPort(connection), sourcecallback, &context, NULL);

    _CTServerConnectionCellMonitorStart(&tx, connection);

    NSLog(@"Connected\n");
}

-(int)getCellCount
{
    int cellcount;
		
    _CTServerConnectionCellMonitorGetCellCount(&tl, connection, &cellcount);

    return cellcount;
}

-(void)getCellInfo:(int) cell
{
    char *a = malloc(sizeof(CellInfo));

    _CTServerConnectionCellMonitorGetCellInfo(&tl, connection, cell, a);

    memcpy(&cellinfo, a, sizeof(CellInfo));

    NSLog(@"Cell Site: %d, MCC: %d, ", cell, cellinfo.servingmnc);
    NSLog(@"MNC: %d ", cellinfo.network);
    NSLog(@"Location: %d, Cell ID: %d, Station: %d, ", cellinfo.location, cellinfo.cellid, cellinfo.station);
    NSLog(@"Freq: %d, RxLevel: %d, ", cellinfo.freq, cellinfo.rxlevel);
    NSLog(@"C1: %d, C2: %d\n", cellinfo.c1, cellinfo.c2);

    free(a);
}

-(void) main
{
    int i;
    NSLog(@"Starting...");
    theDataArray = [[NSMutableArray alloc] init];
    [self cellConnect];
    [theDataArray removeAllObjects];
    int cellcount = [self getCellCount];
    NSLog(@"Cells %d", cellcount);
    for (i = 0; i < cellcount; i++) {
	[self getCellInfo: i];
	LLData *data = [self showLocationWithMNC: cellinfo.network 
		    andMCC: cellinfo.servingmnc 
		    andCID: cellinfo.cellid
		    andLAC: cellinfo.location
	];
	if (data != nil)
	    [theDataArray addObject: data];
    }
    [self addLocationFromPacket: theDataArray];
    NSLog(@"Finishing...");
}

@end
