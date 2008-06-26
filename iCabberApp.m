#import "iCabberApp.h"
#import "iCabberView.h"

@implementation iCabberApp

    -(void)applicationSuspend:(GSEvent *)event {
	if (![[iCabberView sharedInstance] isConnected]) {
	    [UIApp removeApplicationBadge];
	    system("rm /tmp/SummerBoard.DisablePowerManagement");
	    [self terminate];
	} else {
	    [[NSString stringWithString:@"NINJA"]writeToFile:@"/tmp/SummerBoard.DisablePowerManagement" atomically:YES encoding:NSUTF8StringEncoding error:nil];
	}
    }

    -(void)applicationResume:(GSEvent *)event {
	[[iCabberView sharedInstance] updateAfterResume];
	system("rm /tmp/SummerBoard.DisablePowerManagement");	
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

    - (void)applicationWillTerminate 
    {	
	[UIApp removeApplicationBadge];
	system("rm /tmp/SummerBoard.DisablePowerManagement");
    }

    - (void)applicationDidResumeFromUnderLock
    {
	system("rm /tmp/SummerBoard.DisablePowerManagement");	
    }

    - (void)applicationWillSuspendUnderLock
    {
	if(![UIApp isLocked])
	{
	    if ([[iCabberView sharedInstance] isConnected])
		[[NSString stringWithString:@"NINJA"]writeToFile:@"/tmp/SummerBoard.DisablePowerManagement" atomically:YES encoding:NSUTF8StringEncoding error:nil];	
	}
    }

    - (BOOL)applicationIsReadyToSuspend
    {
	return NO;
    }

    - (BOOL)isSuspendingUnderLock
    {
	return NO;
    }

    - (BOOL) suspendRemainInMemory
    {
	if (![[iCabberView sharedInstance] isConnected])
		return NO;
	return YES;
    }

@end
