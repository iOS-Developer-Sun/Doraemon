//
//  DailyRecord.m
//  Dayima
//
//  Created by sunzj on 14-5-21.
//
//

#import "DailyRecord.h"

@interface DailyRecord()

@end

@implementation DailyRecord

@synthesize notes = _notes; // 备注

- (id)init {
    if (self = [super init]) {
        ;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    DailyRecord *recordDay = [self.class allocWithZone:zone];
    recordDay.notes = self.notes;

    return recordDay;
}

- (NSString *)notes
{
    return (_notes?:@"").copy;
}

@end
