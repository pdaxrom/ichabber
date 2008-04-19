#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UIKit/UITableCell.h>
#import <UIKit/UIImageAndTextTableCell.h>
#import <UIKit/UIImage.h>
#import <UIKit/UITextLabel.h>
#import <UIKit/UISwitchControl.h>

@interface BuddyCell : UIImageAndTextTableCell 
{
    UIImageView *status_image;
    UIImageView *proto_image;
    UITextLabel *name_label;
    //UITextLabel *mesg;
}

- (id) initWithJID:(NSString *) jid andName:(NSString *) name;

- (void) setStatusImage:(int) status;

- (void) dealloc;

@end
