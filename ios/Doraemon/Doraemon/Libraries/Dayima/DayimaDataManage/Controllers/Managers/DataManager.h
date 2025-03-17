//
//  DataManager.h
//  Dayima
//
//  Created by sunzj on 14-5-13.
//
//

#import <Foundation/Foundation.h>
#import "DailyRecord.h"

extern NSString *const DailyRecordChangedNotification;
extern NSString *const NonUpdatedCountChangedNotification;

@interface DataManager : NSObject

@property (nonatomic, copy, readonly) DailyRecord *todayRecord;
@property (nonatomic, readonly) int64_t lastUpdate;

- (DailyRecord *)dailyRecordOfDateline:(NSInteger)dateline;
- (NSArray *)dailyRecordsFrom:(NSInteger)from to:(NSInteger)to;
- (void)setDailyRecord:(DailyRecord *)dailyRecord;

- (NSInteger)nonUpdatedCount;
- (void)reload;
- (void)clearAllData;
- (BOOL)uploadCalendar;
- (BOOL)downloadCalendar;

@end
