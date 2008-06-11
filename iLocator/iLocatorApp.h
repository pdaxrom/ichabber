#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <GraphicsServices/GraphicsServices.h>
#import <UIKit/UIKit.h>
#import <UIKit/UIApplication.h>
#import <CoreTelephony/CoreTelephony.h>
#import <stdio.h>
#import <string.h>
#import <unistd.h>

#import "LLData.h"

@interface iLocatorApp: NSObject {
    CellInfo cellinfo;
    NSMutableArray *theDataArray;
    int update_delay;
}

- (void) dealloc;
- (void)addLocationFromPacket:(NSMutableArray *) packet;
- (void) cellConnect;
- (void) getCellInfo:(int) cell;
- (LLData *) showLocationWithMNC:(int) MNC andMCC:(int) MCC andCID:(int) CID andLAC:(int) LAC andRX:(int) rxl;
- (void) setUpdateDelay:(int) delay;
- (void) main;
@end
