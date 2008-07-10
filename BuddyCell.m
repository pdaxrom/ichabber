#import <WebCore/WebFontCache.h>
#import "BuddyCell.h"
#import "IconSet.h"

@implementation BuddyCell

    - (id) initWithJID:(NSString *) jid andName:(NSString *) name
    {
	if ((self == [super initWithFrame:CGRectMake(0.0, 0.0, 320.0, 39.0)]) != nil) 
	{
	    float white[4] = {1.0, 1.0, 1.0, 1.0};
	    float transparent[4] = {0.0, 0.0, 0.0, 0.0};
	    float grey[4] = {0.5, 0.5, 0.5, 1.0};
	    float red[4] = {0.5, 0.0, 0.0, 1.0};
	    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	    [self setBackgroundColor:CGColorCreate(colorSpace, white)];

	    status_image = [[UIImageView alloc] initWithFrame: CGRectMake(2, 13, 13, 13)];
	    [status_image setImage: [[IconSet sharedInstance] getIcon:ICON_OFFLINE]];

	    proto_image = [[UIImageView alloc] initWithFrame: CGRectMake(288, 3.5f, 32, 39)];
	    [proto_image setImage: [[IconSet sharedInstance] getIconForJID:jid]];

	    name_label = [[UITextLabel alloc] initWithFrame: CGRectMake(16, 0, 288, 39)];
	    [name_label setText: name];
	    [name_label setFont: [WebFontCache createFontWithFamily:@"Helvetica" traits:0 size:16]];
	    [name_label setBackgroundColor: CGColorCreate(colorSpace, transparent)];
	
		status_label = [[UITextLabel alloc] initWithFrame: CGRectMake(16, 27, 288, 12)];
		[status_label setText: @""];
	    [status_label setFont: [WebFontCache createFontWithFamily:@"Helvetica" traits:0 size:10]];
	    [status_label setBackgroundColor: CGColorCreate(colorSpace, transparent)];

	    [self addSubview: status_image];
	    [self addSubview: name_label];
	    [self addSubview: proto_image];
		[self addSubview: status_label];
	}
	
	return self;
    }

    - (void) setStatusImage:(int) status
    {
		[status_image setImage: [[IconSet sharedInstance] getIcon:status]];
    }

	- (void) setStatusText:(NSString *) status
	{
		[status_label setText: status];
	}

    - (void) dealloc
    {
	[name_label release];
	[status_image release];
	[proto_image release];
	[status_label release];
	[super dealloc];
    }

@end
