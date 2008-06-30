#import "NSLogX.h"
#include <stdio.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>

static id TheNSLogX;

@implementation NSLogX

+(id)sharedInstance
{
    if(TheNSLogX == nil) {
	TheNSLogX = [[NSLogX alloc]init];
    }
    return TheNSLogX;
}


-(void)writeToLogFromSourcefile:(char*)sourceFile lineNumber:(int)lineNumber format:(NSString*)format, ...;
{
   va_list arglist;

   if (format) {
	va_start(arglist, format);
	NSString* outstring = [NSString stringWithFormat:@"%@ -- #%d> %@",[NSString stringWithCString:sourceFile],lineNumber,[[NSString alloc] initWithFormat:format arguments:arglist]]; 
	umask(022);
	FILE *f = fopen("/var/mobile/Library/iChabber/debug.log", "a");
	fprintf(f, "%s\n", [outstring UTF8String]);
	NSLog(outstring);
	fflush(f);
	fclose(f);
	 
        va_end(arglist);
   }
}

@end
