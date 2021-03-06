#import "NewMessage.h"
#import "iCabberView.h"
#import "NSLogX.h"

@implementation NewMessage

    -(id) init {
        CGRect rect = [UIHardware fullScreenApplicationContentRect];
        rect.origin = CGPointMake (0.0f, 0.0f);
	self = [super initWithFrame: rect];

	rect.origin.y = 0;
        rect.size.height = 48.0f;
        UINavigationBar *nav = [[UINavigationBar alloc] initWithFrame: rect];
        [nav pushNavigationItem: [[UINavigationItem alloc] initWithTitle:NSLocalizedString(@"New message", @"New message")]];
        [nav showButtonsWithLeftTitle:NSLocalizedString(@"Back", @"Back") rightTitle:NSLocalizedString(@"Send", @"Send") leftBack: YES];
        [nav setDelegate: self];
        [nav setBarStyle: 0];

        rect = [UIHardware fullScreenApplicationContentRect];
        rect.origin = CGPointMake (0.0f, 48.0f);
        rect.size.height = (245 - 48);
        replyText = [[UITextView alloc] initWithFrame: rect];

	[replyText setTextSize:14];
	[replyText setText:@""];

	[UIKeyboard initImplementationNow];
	keyboard = [[UIKeyboard alloc] initWithFrame: CGRectMake(0.0f, 245.0f, 320.0f, 235.0f)];

        [self addSubview: replyText];
	[self addSubview: keyboard];
        [self addSubview: nav];

	[replyText becomeFirstResponder];

	return self;
    }

    -(void)updateView {
	[replyText removeFromSuperview];
	[keyboard removeFromSuperview];
	[self addSubview: replyText];
	[self addSubview: keyboard];
	[replyText becomeFirstResponder];
    }

    -(void) navigationBar:(UINavigationBar *)navbar buttonClicked:(int)button {
	if (button == 0) {
    	    NSLogX(@"pre3-2");

	    [[iCabberView sharedInstance] sendMessage:[replyText text]];
	    [[iCabberView sharedInstance] switchFromNewMessageToUserView];

	    [replyText setText:@""];
    	    NSLogX(@"3-2");
	} else if (button == 1) {
	    [[iCabberView sharedInstance] switchFromNewMessageToUserView];
    	    NSLogX(@"3-2");
	}
    }
    
@end
