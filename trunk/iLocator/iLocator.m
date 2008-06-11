#import "iLocatorApp.h"

int main(int argc, char **argv)
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    //return UIApplicationMain(argc, argv, [iLocatorApp class]);

    [[iLocatorApp alloc] main];

    [pool release];
    return 0;
}
