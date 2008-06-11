#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>

@interface LLData : NSObject
{
	double _lat;
	double _lon;
	NSDate *_date;
}

- (id) initWithLat:(double) lat andLon:(double) lon andDate:(NSDate *) date;

- (void) dealloc;

- (double) getLat;

- (double) getLon;

- (NSDate *) getDate;

@end
