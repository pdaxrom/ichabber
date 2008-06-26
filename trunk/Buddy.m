#import "Buddy.h"

@implementation Buddy

    -(id) initWithJID:(NSString *) ajid andName:(NSString *) aname andGroup:(NSString *) agroup {
	self  = [super init];
	jid   = [[NSString alloc]initWithString:ajid];
	name  = [[NSString alloc]initWithString:aname];
	group = [[NSString alloc]initWithString:agroup];
	statusText = [[NSString alloc] initWithString:@""];
	
	status = 0;
	newmsg = 0;
	rflag = -1;
	    
	return self;
    }

    -(void) dealloc {
	[jid release];
	[name release];
	[group release];
	[super dealloc];
    }

    -(NSString *) getGroup {
	return group;
    }

    -(NSString *) getName {
	return name;
    }

    -(NSString *) getJID {
	return jid;
    }

    -(int) getStatus {
	return status;
    }

	- (NSString*)getStatusText
	{
		return statusText;
	}

    -(void) setStatus:(int) s {
		status = s;
    }

	- (void)setStatusText:(NSString*)s
	{
		[statusText release];
		statusText = [[NSString alloc] initWithString:s];
	}

    - (void) setMsgCounter:(int)n {
	newmsg = n;
    }

    -(void) incMsgCounter {
	newmsg++;
    }

    -(int) getMsgCounter {
	return newmsg;
    }

    -(void) clrMsgCounter {
	newmsg = 0;
    }

    -(void) setRFlag {
	rflag = 1;
    }

    -(void) clrRFlag {
	rflag = 0;
    }

    -(int) getRFlag {
	return rflag;
    }

@end
