#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <UIKit/UIKit.h>
#import <UIKit/UIView.h>
#import <UIKit/UIApplication.h>
#import <UIKit/UIPushButton.h>
#import <UIKit/UITableCell.h>
#import <UIKit/UIImageAndTextTableCell.h>
#import <UIKit/UIPreferencesTable.h>
#import <UIKit/UIPreferencesTableCell.h>
#import <UIKit/UIPreferencesTextTableCell.h>
#import <UIKit/UIPreferencesControlTableCell.h>
#import <UIKit/UIPreferencesDeleteTableCell.h>
#import <UIKit/UISwitchControl.h>
#import <UIKit/UIControl.h>

enum {
    ICON_JABBER = 0,
    ICON_GTALK,
    ICON_ICQ,
    ICON_ONLINE,
    ICON_AWAY,
    ICON_XAWAY,
    ICON_DND,
    ICON_CHAT,
    ICON_OFFLINE,
    ICON_CONTENT,
    ICON_MAX
};

@interface IconSet: NSObject {
    UIImage *_image[ICON_MAX];
}

- (id) init;
- (UIImage *) getIcon:(int) i;
- (UIImage *) getIconForJID:(NSString *) jid;
- (NSString *) insertSmiles:(NSString *) str;
- (void) dealloc;

+ (id) initSharedInstance;
+ (id) sharedInstance;

@end
