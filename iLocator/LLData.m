#import "LLData.h"

@implementation LLData

- (id) initWithLat:(double) lat andLon:(double) lon andDate:(NSDate *) date
{
    self  = [super init];
    _lat = lat;
    _lon = lon;
    _date = date;
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

@end
