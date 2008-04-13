#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <UIKit/UIKit.h>
#import <UIKit/UITableCell.h>
#import <UIKit/UIImageAndTextTableCell.h>
#import <UIKit/UIImage.h>
#import <UIKit/UITextView.h>
#import <UIKit/UISwitchControl.h>
#import <UIKit/UITransitionView.h>
#import <UIKit/UIWindow.h>
#import <UIKit/UIView.h>
#import <GraphicsServices/GraphicsServices.h>
#import <Message/NetworkController.h>

#import "MyPrefs.h"
#import "Buddy.h"
#import "EyeCandy.h"

#define MAX_USERLOG_SIZE 2048

@interface iCabberView : UIView {
    UITransitionView *transitionView;
    MyPrefs *myPrefs;
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
    UINavigationItem *userViewNavItem;
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
    int sock;
    
    //ping counter
    int ping_counter;
    int ping_interval;
    
    int connected;
}

- (id)initWithFrame:(CGRect) rect;

- (int)isConnected;

- (void)loginMyAccount;
- (void)logoffMyAccount;

- (void)updateHistory:(NSString *)username from:(NSString *) from message:(NSString *)message title:(int)title titlecolor:(NSString *)titlecolor;
- (Buddy *)getBuddy:(NSString *) jid;
- (void)updateUsersTable;

+ (id)initSharedInstanceWithFrame:(CGRect) rect;
+ (id)sharedInstance;

@end
