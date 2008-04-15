#import "UserView.h"
#import "iCabberView.h"

@implementation UserView

    -(id) init {
        CGRect rect = [UIHardware fullScreenApplicationContentRect];
        rect.origin = CGPointMake (0.0f, 0.0f);
	self = [super initWithFrame: rect];

        rect.origin = CGPointMake (0.0f, 0.0f);
        rect.size.height = 48.0f;
        UINavigationBar *userViewNav = [[UINavigationBar alloc] initWithFrame: rect];
	userViewNavItem = [[UINavigationItem alloc] initWithTitle:@"History"];
        [userViewNav pushNavigationItem: userViewNavItem];
        [userViewNav showButtonsWithLeftTitle:@"Back" rightTitle: @"Reply" leftBack: YES];
        [userViewNav setDelegate: self];
        [userViewNav setBarStyle: 0];

        rect = [UIHardware fullScreenApplicationContentRect];
        rect.origin = CGPointMake (0.0f, 48.0f);
        rect.size.height -= 16;
        userText = [[UITextView alloc] initWithFrame: rect];

	[userText setEditable:NO];
	[userText setTextSize:14];
	[userText setText:@""];

        [self addSubview: userText];
        [self addSubview: userViewNav];

	return self;
    }

    -(void) setTitle:(NSString *)_title {
	[userViewNavItem setTitle:_title];
    }

    -(void) setText:(NSString *) _text {
	[userText setHTML:_text];
	[userText scrollPointVisibleAtTopLeft:CGPointMake(0, 9999999) animated:NO];
    }

    -(void) appendText:(NSString *) _text {
	[userText setHTML: [NSString stringWithFormat:@"%@%@", [userText HTML], _text]];
	[userText scrollPointVisibleAtTopLeft:CGPointMake(0, 9999999) animated:YES];
    }

    - (void)navigationBar:(UINavigationBar *)navbar buttonClicked:(int)button {
	if (button == 0) {
	    [[iCabberView sharedInstance] switchFromUserViewToNewMessage];
	} else if (button == 1) {
	    [[iCabberView sharedInstance] switchFromUserViewToUsers];
	}
    }
    
@end
