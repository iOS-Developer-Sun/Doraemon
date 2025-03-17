//
//  EventsDatabaseAccess.h
//  Dayima
//
//  Created by sunzj on 14-5-13.
//
//

#import "DatabaseAccess.h"

#define CALENDAR_EVENT_MEMO 7 //备注

@interface Event : NSObject

@property (nonatomic) NSInteger type;
@property (nonatomic) NSInteger dateline;
@property (nonatomic) int64_t updateTime;
@property (nonatomic) int64_t mtime;
@property (nonatomic) id data;

@end


@interface EventsDatabaseAccess : DatabaseAccess

- (BOOL)create;

#pragma mark - DailyRecord

- (NSArray *)dailyRecordsFrom:(NSInteger)from to:(NSInteger)to;

#pragma mark - Common

- (Event *)eventWithEvent:(NSInteger)event dateline:(NSInteger)dateline;
- (NSArray *)eventsWithDateline:(NSInteger)dateline;
- (NSArray *)nonUpdatedEventsWithPage:(NSInteger)page countPerPage:(NSInteger)countPerPage;
- (int64_t)lastUpdateTime;
- (NSInteger)nonUpdatedCount;
- (NSInteger)zeroDatelineCount;
- (void)insertEvent:(Event *)event;
- (void)removeEventsWithDateline:(NSInteger)dateline;
- (void)clearAllUpdateTimes;
- (void)clearAllEvents;

- (NSArray *)datelinesOfAllNoteRecords;
- (NSInteger)lastDatelineOfAllNoteRecords;
- (void)setNoteRecord:(NSString *)noteRecord dateline:(NSInteger)dateline;
- (void)removeNoteRecordWithDateline:(NSInteger)dateline;
- (NSString *)noteRecordWithDateline:(NSInteger)dateline;
- (void)removeAllNoteRecords;

@end
