#import "LLData.h"

@implementation LLData

- (id) initWithLat:(double) lat andLon:(double) lon andDate:(NSDate *) date andRX:(int) rx
{
    self  = [super init];
    _lat = lat;
    _lon = lon;
    _date = date;
    _rx = rx;

    _cid = -1;
    _lac = -1;
    _mnc = -1;
    _mcc = -1;

    return self;
}

- (id) initWithCid:(int) cid andLac:(int) lac andMNC:(int) mnc andMCC:(int) mcc andDate:(NSDate *) date andRX:(int) rx
{
    self = [super init];
    _cid = cid;
    _lac = lac;
    _mnc = mnc;
    _mcc = mcc;
    _date = date;    
    _rx = rx;
    
    _lat = -1;
    _lon = -1;
    
    return self;
}

- (void) dealloc 
{
    [_date release];
    [super dealloc];
}

- (double) getLat 
{
    return _lat;
}

- (double) getLon 
{
    return _lon;
}

- (NSDate *) getDate 
{
    return _date;
}

- (int) getCid
{
    return _cid;
}

- (int) getLac
{
    return _lac;
}

- (int) getMNC
{
    return _mnc;
}

- (int) getMCC
{
    return _mcc;
}

- (int) getRX
{
    return _rx;
}

@end
