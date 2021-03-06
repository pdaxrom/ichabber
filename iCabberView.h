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
#import "UserView.h"
#import "NewMessage.h"
#import "Buddy.h"
#import "EyeCandy.h"
#import "IconSet.h"

#define MAX_USERLOG_SIZE 2048

@interface iCabberView : UIView {
    UITransitionView *transitionView;

    MyPrefs	*myPrefs;
    UIView 	*usersView;
    UserView	*userView;
    NewMessage	*newMsg;
    
    UITable *usersTable;
    NSTimer *myTimer;
    UIView *currPage;
    NSMutableArray *buddyArray;
    EyeCandy *eyeCandy; 
    
    // Buddy
    Buddy *currBuddy;

    // Icons
    IconSet *is;
    
    // Network variables
    int sock;
    
    //ping counter
    int ping_counter;
    int ping_interval;
    int ping_errors;
    
    int connection_started;
    int connected;
    int connection_error;
    int connection_hud;
}

- (id)initWithFrame:(CGRect) rect;

- (int)isConnected;

- (void)loginMyAccount;
- (void)loginMyAccount2;
- (void)logoffMyAccount;

- (void)sendMessage:(NSString *) msg;

- (void)switchFromUserViewToUsers;
- (void)switchFromUserViewToNewMessage;
- (void)switchFromNewMessageToUserView;

- (void)updateHistory:(NSString *)username from:(NSString *) from message:(NSString *)message title:(int)title titlecolor:(NSString *)titlecolor;
- (Buddy *)getBuddy:(NSString *) jid;
- (Buddy *)getOfflineBuddy:(NSString *) jid;
- (void)updateUsersTable;
- (void)setStatus:(NSString *) status withText:(NSString *) message;

- (void)updateAfterResume;

+ (id)initSharedInstanceWithFrame:(CGRect) rect;
+ (id)sharedInstance;

@end
