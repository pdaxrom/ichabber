#import "BuddyAction.h"

@implementation BuddyAction

    - (id) initWithBuddy:(NSString *) buddy andAction:(int) action
    {
	self  = [super init];

	_buddy = [[NSString alloc] initWithString: buddy];
	_action = action;
	
	return self;
    }
    
    - (NSString *) getBuddy
    {
	return _buddy;
    }
    
    - (int ) getAction
    {
	return _action;
    }

    - (void) dealloc
    {
	[_buddy release];
	[super dealloc];
    }

@end
