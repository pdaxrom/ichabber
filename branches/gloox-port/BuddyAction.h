#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UIKit/UIAnimator.h>
#import "Buddy.h"

enum {
    BUDDYACTION_SUBSCRIBE = 0,
    BUDDYACTION_UNSUBSCRIBE
};

@interface BuddyAction : NSObject
{
    NSString 	*_buddy;
    int 	_action;
}

    - (id) initWithBuddy:(NSString *) buddy andAction:(int) action;
    
    - (NSString *) getBuddy;
    
    - (int ) getAction;

    - (void) dealloc;

@end
