#import "NewMessage.h"
#import "iCabberView.h"

@implementation NewMessage

    -(id) init {
        CGRect rect = [UIHardware fullScreenApplicationContentRect];
        rect.origin = CGPointMake (0.0f, 0.0f);
	self = [super initWithFrame: rect];

	rect.origin.y = 0;
        rect.size.height = 48.0f;
        UINavigationBar *nav = [[UINavigationBar alloc] initWithFrame: rect];
        [nav pushNavigationItem: [[UINavigationItem alloc] initWithTitle:@"New message"]];
        [nav showButtonsWithLeftTitle:@"Back" rightTitle: @"Send" leftBack: YES];
        [nav setDelegate: self];
        [nav setBarStyle: 0];

        rect = [UIHardware fullScreenApplicationContentRect];
        rect.origin = CGPointMake (0.0f, 48.0f);
        rect.size.height -= (245 + 16);
        replyText = [[UITextView alloc] initWithFrame: rect];

	[replyText setTextSize:14];
	[replyText setText:@""];

	[UIKeyboard initImplementationNow];
	UIKeyboard *keyboard = [[UIKeyboard alloc] initWithFrame: CGRectMake(0.0f, 245.0f,
							      320.0f, 480.0f - 245.f - 16.f)];

        [self addSubview: replyText];
	[self addSubview: keyboard];
        [self addSubview: nav];

	[replyText becomeFirstResponder];

	return self;
    }

    -(void) navigationBar:(UINavigationBar *)navbar buttonClicked:(int)button {
	if (button == 0) {
    	    NSLog(@"pre3-2");

	    [[iCabberView sharedInstance] sendMessage:[replyText text]];
	    [[iCabberView sharedInstance] switchFromNewMessageToUserView];

	    [replyText setText:@""];
    	    NSLog(@"3-2");
	} else if (button == 1) {
	    [[iCabberView sharedInstance] switchFromNewMessageToUserView];
    	    NSLog(@"3-2");
	}
    }
    
@end
