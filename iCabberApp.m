#import "iCabberApp.h"
#import "iCabberView.h"

@implementation iCabberApp

    -(void)applicationSuspend:(GSEvent *)event {
	NSLog(@"applicationSuspend");
	if (![[iCabberView sharedInstance] isConnected]) {
	    [UIApp removeApplicationBadge];
	    system("rm /tmp/SummerBoard.DisablePowerManagement");
	    [self terminate];
	} else {
	    [[NSString stringWithString:@"NINJA"]writeToFile:@"/tmp/SummerBoard.DisablePowerManagement" atomically:YES encoding:NSUTF8StringEncoding error:nil];
	}
    }

    -(void)applicationResume:(GSEvent *)event {
	NSLog(@"applicationResume");
	[[iCabberView sharedInstance] updateAfterResume];
	system("rm /tmp/SummerBoard.DisablePowerManagement");	
    }

    -(void)applicationExited:(GSEvent *)event {
	NSLog(@"applicationExited");
    }

    void powerCallback(void *refCon, io_service_t service, natural_t messageType, void *messageArgument)
    {	
	NSLog(@"powerCallback");
	[(iCabberApp *)refCon powerMessageReceived: messageType withArgument: messageArgument];
    }

    - (void)powerMessageReceived:(natural_t)messageType withArgument:(void *) messageArgument
    {
	NSLog(@"powerMessageReceived %p %p", messageType, messageArgument);
	switch (messageType) {
        case kIOMessageSystemWillSleep:
	    /* The system WILL go to sleep. If you do not call IOAllowPowerChange or
    	       IOCancelPowerChange to acknowledge this message, sleep will be
    	       delayed by 30 seconds.

               NOTE: If you call IOCancelPowerChange to deny sleep it returns kIOReturnSuccess,
               however the system WILL still go to sleep.
             */

            // we cannot deny forced sleep
  	    NSLog(@"powerMessageReceived kIOMessageSystemWillSleep");
            IOAllowPowerChange(root_port, (long)messageArgument);  
            break;
        case kIOMessageCanSystemSleep:
	    /* Idle sleep is about to kick in.
               Applications have a chance to prevent sleep by calling IOCancelPowerChange.
               Most applications should not prevent idle sleep.

               Power Management waits up to 30 seconds for you to either allow or deny idle sleep.
               If you don't acknowledge this power change by calling either IOAllowPowerChange
               or IOCancelPowerChange, the system will wait 30 seconds then go to sleep.
             */

	    NSLog(@"powerMessageReceived kIOMessageCanSystemSleep");

	    //cancel the change to prevent sleep
	    IOCancelPowerChange(root_port, (long)messageArgument);
	    //IOAllowPowerChange(root_port, (long)messageArgument);	

            break; 
        case kIOMessageSystemHasPoweredOn:
            NSLog(@"powerMessageReceived kIOMessageSystemHasPoweredOn");
            break;
	}
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

	IONotificationPortRef notificationPort;
	root_port = IORegisterForSystemPower(self, &notificationPort, powerCallback, &notifier);

	// add the notification port to the application runloop
	CFRunLoopAddSource(CFRunLoopGetCurrent(),
                    	    IONotificationPortGetRunLoopSource(notificationPort),
                    	    kCFRunLoopCommonModes );

	//[self performSelector: @selector(suspendWithAnimation:) withObject:nil afterDelay: 0];

    }

    - (void)applicationWillTerminate 
    {	
	NSLog(@"applicationWillTerminate");
	[UIApp removeApplicationBadge];
	system("rm /tmp/SummerBoard.DisablePowerManagement");
    }

    - (void)applicationDidResumeFromUnderLock
    {
	NSLog(@"applicationDidResumeFromUnderLock");
	system("rm /tmp/SummerBoard.DisablePowerManagement");	
    }

    - (void)applicationWillSuspendUnderLock
    {
	NSLog(@"applicationWillSuspendUnderLock");
	if(![UIApp isLocked])
	{
	    if ([[iCabberView sharedInstance] isConnected])
		[[NSString stringWithString:@"NINJA"]writeToFile:@"/tmp/SummerBoard.DisablePowerManagement" atomically:YES encoding:NSUTF8StringEncoding error:nil];	
	}
    }

    - (BOOL)applicationIsReadyToSuspend
    {
	NSLog(@"applicationIsReadyToSuspend");
	return NO;
    }

    - (BOOL)isSuspendingUnderLock
    {
	NSLog(@"isSuspendingUnderLock");
	return NO;
    }

    - (BOOL) suspendRemainInMemory
    {
	NSLog(@"suspendRemainInMemory");
	if (![[iCabberView sharedInstance] isConnected])
		return NO;
	return YES;
    }

@end
