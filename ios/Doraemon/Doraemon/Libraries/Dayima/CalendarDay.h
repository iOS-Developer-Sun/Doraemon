//
//  DayimaCalendarDay
//
//  Created by lt on 14/12/16.
//  Copyright (c) 2014年 lt. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CalendarDay : NSObject

+ (NSInteger)datelineToday;
+ (NSInteger)datelineWithYear:(NSInteger)year month:(NSInteger)month day:(NSInteger)day;
+ (NSInteger)dateline:(NSInteger)dateline byDayOffset:(NSInteger)offset;

@end
