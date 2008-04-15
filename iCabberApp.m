#import "iCabberApp.h"
#import "iCabberView.h"

@implementation iCabberApp

    -(void)applicationSuspend:(GSEvent *)event {
	if (![[iCabberView sharedInstance] isConnected]) {
	    [UIApp removeApplicationBadge];
	    [self terminate];
	}
    }

    -(void)applicationResume:(GSEvent *)event {
	    [[iCabberView sharedInstance] updateAfterResume];
    }

    -(void)applicationExited:(GSEvent *)event {
    }

    -(void)applicationDidFinishLaunching:(NSNotification*)unused
    {
	struct CGRect rect = [UIHardware fullScreenApplicationContentRect];
	rect.origin.x = rect.origin.y = 0.0f;

	window = [[UIWindow alloc] initWithContentRect: rect];
	
	iCabberView *ic = [iCabberView initSharedInstanceWithFrame: rect];

	[window setContentView: ic];	
        [window orderFront: self];
        [window makeKey: self];
        [window _setHidden: NO];
    }

@end
