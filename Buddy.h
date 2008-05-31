#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UIKit/UIAnimator.h>

@interface Buddy : NSObject
{
	NSString * jid;
	NSString * name;
	NSString * group;
	NSString * statusText;
	int status;
	int newmsg;
	int rflag;
}

- (id) initWithJID:(NSString *) ajid andName:(NSString *) aname andGroup:(NSString *) agroup;

- (void) dealloc;

- (NSString *) getGroup;

- (NSString *) getName;

- (NSString *) getJID;

- (int) getStatus;

- (void) setStatus:(int) s;

- (NSString*)getStatusText;

- (void)setStatusText:(NSString*)s;

- (void) incMsgCounter;

- (int) getMsgCounter;

- (void) clrMsgCounter;

- (void) setRFlag;

- (void) clrRFlag;

- (int) getRFlag;

@end
