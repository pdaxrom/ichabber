#import <UIKit/UIKit.h>

#import "iCabberApp.h"

int main(int argc, char **argv)
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    int ret = UIApplicationMain(argc, argv, [iCabberApp class]);
    [pool release];
    return ret;
}
