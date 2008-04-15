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

@interface NewMessage: UIView {
    UITextView *replyText;
}

- (id) init;
- (void)navigationBar:(UINavigationBar *)navbar buttonClicked:(int)button;

@end
