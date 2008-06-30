#import <Foundation/Foundation.h>

#define NSLogX(s,...) \
    [[NSLogX sharedInstance] writeToLogFromSourcefile:__FILE__ lineNumber:__LINE__ \
			      format:(s),##__VA_ARGS__]

@interface NSLogX : NSObject 
{
}

+(id)sharedInstance;
-(void)writeToLogFromSourcefile:(char*)sourceFile lineNumber:(int)lineNumber format:(NSString*)format, ...;

@end