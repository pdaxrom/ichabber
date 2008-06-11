#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>

@interface LLData : NSObject
{
	double _lat;
	double _lon;
	int _cid;
	int _lac;
	int _mnc;
	int _mcc;
	NSDate *_date;
	int _rx;
}

- (id) initWithLat:(double) lat andLon:(double) lon andDate:(NSDate *) date andRX:(int) rx;

- (id) initWithCid:(int) cid andLac:(int) lac andMNC:(int) mnc andMCC:(int) mcc andDate:(NSDate *) date andRX:(int) rx;

- (void) dealloc;

- (double) getLat;

- (double) getLon;

- (NSDate *) getDate;

- (int) getCid;

- (int) getLac;

- (int) getMNC;

- (int) getMCC;

- (int) getRX;

@end
