#import "IconSet.h"
#import "NSLogX.h"

static id sharedInstanceIcon;

static NSString *file[ICON_MAX] = {
    @"jabber.png",
    @"gtalk.png",
    @"icq.png",
    @"available.png",
    @"away.png",
    @"xaway.png",
    @"dnd.png",
    @"chat.png",
    @"offline.png",
    @"content.png"
};

@implementation IconSet

    + (id) initSharedInstance
    {
	sharedInstanceIcon = [[IconSet alloc] init];
	return sharedInstanceIcon;
    }

    + (id) sharedInstance
    {
	return sharedInstanceIcon;
    }

    - (id) init
    {
	int i;

	self  = [super init];

	for (i = 0; i < ICON_MAX; i++) {
	    _image[i] = [UIImage applicationImageNamed: file[i]];
	    if (_image[i] == nil)
		NSLogX(@"Can't load image %@", file[i]);
	}
	
	return self;
    }

    - (UIImage *) getIcon:(int) i
    {
	return _image[i];
    }

    - (UIImage *) getIconForJID:(NSString *) jid
    {
	int n = ICON_JABBER;
	NSRange range = [jid rangeOfString:@"@gmail.com" options:(NSCaseInsensitiveSearch)];
	if (range.location != NSNotFound)
	    n = ICON_GTALK;
	range = [jid rangeOfString:@"icq" options:(NSCaseInsensitiveSearch)];
	if (range.location != NSNotFound)
	    n = ICON_ICQ;
	
	return _image[n];
    }

    - (void) dealloc
    {
	int i;
	for (i = 0; i < 0; i++) {
	    if (_image[i] != nil)
		[_image[i] release];
	}
	
	[super dealloc];
    }

@end
