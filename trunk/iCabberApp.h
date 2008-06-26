#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <UIKit/UIKit.h>
#import <GraphicsServices/GraphicsServices.h>

@interface iCabberApp : UIApplication {
    UIWindow *window;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification;
- (void)applicationWillTerminate;
- (void)applicationSuspend:(GSEvent *)event;
- (void)applicationResume:(GSEvent *)event;
- (BOOL)isSuspendingUnderLock;
- (BOOL)applicationIsReadyToSuspend;
- (BOOL) suspendRemainInMemory;
- (void)applicationDidResumeFromUnderLock;
- (void)applicationWillSuspendUnderLock;

@end
