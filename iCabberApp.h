#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <UIKit/UIKit.h>
#import <GraphicsServices/GraphicsServices.h>
#import "MyPrefs.h"
#import "Buddy.h"
#import "EyeCandy.h"

@interface iCabberApp : UIApplication {
    UITransitionView *transitionView;
    MyPrefs *myPrefs;
    UIView *mySettings;
    UIView *usersView;
    UIView *userView;
    UIView *newMsg;
    UITable *usersTable;
    NSTimer *myTimer;
    UIView *currPage;
    NSMutableArray *buddyArray;
    EyeCandy *eyeCandy; 
    
    // Buddy
    Buddy *currBuddy;
    UITextView *replyText;
    UITextView *userText;

    //Images
    UIImage *image_online;
    UIImage *image_away;
    UIImage *image_xaway;
    UIImage *image_dnd;
    UIImage *image_chat;
    UIImage *image_offline;
    UIImage *image_content;
    
    // Network variables
    char *servername;
    int  serverport;
    const char *my_resource;
    int sock;
    
    //ping counter
    int ping_counter;
    int ping_interval;
    
    int connected;
}

- (void)updateHistory:(char *)username from:(char *) from message:(char *)message title:(int)title titlecolor:(char *)titlecolor;
- (Buddy *)getBuddy:(NSString *) jid;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification;
- (void)applicationSuspend:(GSEvent *)event;
- (void)applicationResume:(GSEvent *)event;

@end
