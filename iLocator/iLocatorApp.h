#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <GraphicsServices/GraphicsServices.h>
#import <UIKit/UIKit.h>
#import <UIKit/UIApplication.h>
#import <CoreTelephony/CoreTelephony.h>
#import <stdio.h>
#import <string.h>

@interface iLocatorApp: NSObject {
    CellInfo cellinfo;
}

- (void) dealloc;
- (void) cellConnect;
- (void) getCellInfo:(int) cell;
- (void) showLocationWithMNC:(int) MNC andMCC:(int) MCC andCID:(int) CID andLAC:(int) LAC;
- (void) main;
@end
