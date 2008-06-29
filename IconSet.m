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

struct SmileTable {
    NSString *smile;
    NSString *image;
} smileTable[] = {
    {@":)",	@"smile.png"},
    {@":-)",	@"smile.png"},
    {@";)",	@"wink.png"},
    {@";-)",	@"wink.png"},
    {@":P",	@"tongue.png"},
    {@":-P",	@"tongue.png"},
    {@":D",	@"biggrin.png"},
    {@":-D",	@"biggrin.png"},
    {@":&gt;",	@"biggrin.png"},
    {@":-&gt;",	@"biggrin.png"},
    {@":(",	@"unhappy.png"},
    {@":-(",	@"unhappy.png"},
    {@";(",	@"cry.png"},
    {@";-(",	@"cry.png"},
    {@":'(",	@"cry.png"},
    {@":'-(",	@"cry.png"},
    {@":O",	@"oh.png"},
    {@":-O",	@"oh.png"},
    {@":@",	@"angry.png"},
    {@":-@",	@"angry.png"},
    {@":$",	@"blush.png"},
    {@":-$",	@"blush.png"},
    {@":|",	@"stare.png"},
    {@":-|",	@"stare.png"},
    {@":S",	@"frowning.png"},
    {@":-S",	@"frowning.png"},
    {@"B)",	@"coolglasses.png"},
    {@"B-)",	@"coolglasses.png"},
    {@":[",	@"bat.png"},
    {@":-[",	@"bat.png"},
    {nil, nil}
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

    - (NSString *) insertSmiles:(NSString *) str
    {
	int i = 0;
	
	NSMutableString *_str = [[NSMutableString alloc] initWithString: str];

	while (smileTable[i].smile != nil) {
	    NSString *target = smileTable[i].smile;
	    NSString *replacement = [NSString stringWithFormat: @"<img src='file:///Applications/iChabber.app/smiles/%@'>", smileTable[i].image];

	    [_str replaceOccurrencesOfString:target 
		  withString:replacement
	          options:NSCaseInsensitiveSearch
	          range:NSMakeRange(0, [_str length])
	    ];
	    i++;
	}

	return _str;
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
