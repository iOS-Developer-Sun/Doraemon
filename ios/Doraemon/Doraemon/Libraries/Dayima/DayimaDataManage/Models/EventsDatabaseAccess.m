//
//  EventsDatabaseAccess.m
//  Dayima
//
//  Created by sunzj on 14-5-13.
//
//

#import "EventsDatabaseAccess.h"
#import "Event.h"

#import "DailyRecord.h"

#define DB_TABLE_EVENTS                 @"events"
#define DB_FIELD_EVENTS_EVENT           @"event"
#define DB_FIELD_EVENTS_DATA            @"data"
#define DB_FIELD_EVENTS_DATELINE        @"dateline"
#define DB_FIELD_EVENTS_UPDATETIME      @"updatetime"
#define DB_FIELD_EVENTS_MTIME           @"mtime"
#define DB_SQL_CREATE_TABLE_EVENTS      @"create table if not exists " DB_TABLE_EVENTS @"("\
DB_FIELD_EVENTS_EVENT @" integer not null default '0', "\
DB_FIELD_EVENTS_DATA @" varchar(2000) not null default '', "\
DB_FIELD_EVENTS_DATELINE @" integer not null default '0', "\
DB_FIELD_EVENTS_UPDATETIME @" integer not null default '0', "\
DB_FIELD_EVENTS_MTIME @" integer not null default '0', "\
@"primary key (" DB_FIELD_EVENTS_DATELINE @", " DB_FIELD_EVENTS_EVENT @"))"

@implementation Event

@end

@implementation EventsDatabaseAccess

- (BOOL)create {
    return [self.database executeUpdate:DB_SQL_CREATE_TABLE_EVENTS];
}

- (NSArray *)nonPeriodEventsWithEvent:(NSInteger)event from:(NSInteger)from to:(NSInteger)to
{
    NSArray *list = [self.database findAll:@"*" fromTable:DB_TABLE_EVENTS withOrder:@"order by " DB_FIELD_EVENTS_DATELINE withCondition:[NSString stringWithFormat:@"where " DB_FIELD_EVENTS_DATELINE @" >= '%@' and " DB_FIELD_EVENTS_DATELINE @" <= '%@' and " DB_FIELD_EVENTS_DATA @" != '' and " DB_FIELD_EVENTS_EVENT @" = '%@'", @(from), @(to), @(event)]];
    return [self eventsWithList:list];
}

- (void)insertEvent:(Event *)event
{
    if (event.dateline == 0) {
        NSLog(@"insert dateline 0: %@", event);
        return;
    }

    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[DB_FIELD_EVENTS_UPDATETIME] = @(event.updateTime);
    dict[DB_FIELD_EVENTS_MTIME] = @(event.mtime);
    dict[DB_FIELD_EVENTS_DATELINE] = @(event.dateline);
    dict[DB_FIELD_EVENTS_DATA] = event.data ?: @"";
    dict[DB_FIELD_EVENTS_EVENT] = @(event.type);

    BOOL ret = [self.database replace:dict intoTable:DB_TABLE_EVENTS];
    [self checkResult:ret];
}

- (void)removeEventsWithDateline:(NSInteger)dateline
{
    BOOL ret = [self.database deleteFromTable:DB_TABLE_EVENTS withCondition:[NSString stringWithFormat:@"where " DB_FIELD_EVENTS_DATELINE @" = '%@'", @(dateline)]];
    [self checkResult:ret];
}

- (void)clearAllUpdateTimes
{
    BOOL ret = [self.database update:@{DB_FIELD_EVENTS_UPDATETIME : @(0)} inTable:DB_TABLE_EVENTS withCondition:nil];
    [self checkResult:ret];
}

- (void)clearAllEvents
{
    BOOL ret = [self.database deleteFromTable:DB_TABLE_EVENTS];
    [self checkResult:ret];
}

- (Event *)eventWithEvent:(NSInteger)event dateline:(NSInteger)dateline
{
    NSDictionary *dict = [self.database findOne:@"*" fromTable:DB_TABLE_EVENTS withCondition:[NSString stringWithFormat:@"where " DB_FIELD_EVENTS_DATELINE @" = '%@' and " DB_FIELD_EVENTS_EVENT @" = '%@'", @(dateline), @(event)]];
    Event *e = [[Event alloc] init];
    e.type = [dict[DB_FIELD_EVENTS_EVENT] integerValue];
    e.dateline = [dict[DB_FIELD_EVENTS_DATELINE] integerValue];
    e.updateTime = [dict[DB_FIELD_EVENTS_UPDATETIME] longLongValue];
    e.mtime = [dict[DB_FIELD_EVENTS_MTIME] longLongValue];
    e.data = dict[DB_FIELD_EVENTS_DATA];
    return e;
}

- (NSArray *)eventsWithDateline:(NSInteger)dateline
{
    NSArray *list = [self.database findAll:@"*" fromTable:DB_TABLE_EVENTS withCondition:[NSString stringWithFormat:@"where " DB_FIELD_EVENTS_DATELINE @" = '%@'", @(dateline)]];
    return [self eventsWithList:list];
}

- (NSArray *)nonUpdatedEventsWithPage:(NSInteger)page countPerPage:(NSInteger)countPerPage
{
    NSInteger start = page * countPerPage;
    NSInteger offset = countPerPage;
    NSArray *list = [self.database findAll:@"*" fromTable:DB_TABLE_EVENTS withStart:start withOffset:offset withOrder:@"order by " DB_FIELD_EVENTS_DATELINE @", " DB_FIELD_EVENTS_EVENT withCondition:[NSString stringWithFormat:@"where " DB_FIELD_EVENTS_UPDATETIME @" = '0' and " DB_FIELD_EVENTS_DATELINE @" != '0'"]];
    return [self eventsWithList:list];
}

- (NSArray *)findAllEvents
{
    NSArray *list = [self.database findAll:@"*" fromTable:DB_TABLE_EVENTS withCondition:[NSString stringWithFormat:@"order by " DB_FIELD_EVENTS_DATELINE]];
    return [self eventsWithList:list];
}

- (NSArray *)eventsWithList:(NSArray *)list {
    NSMutableArray *array = [NSMutableArray array];
    for (NSDictionary *item in list) {
        Event *event = [[Event alloc] init];
        event.data = item[DB_FIELD_EVENTS_DATA];
        event.dateline = [item[DB_FIELD_EVENTS_DATELINE] integerValue];
        event.updateTime = [item[DB_FIELD_EVENTS_UPDATETIME] longLongValue];
        event.type = [item[DB_FIELD_EVENTS_EVENT] integerValue];
        event.mtime = [item[DB_FIELD_EVENTS_MTIME] longLongValue];

        [array addObject:event];
    }
    return array.copy;
}

#pragma inline method

- (NSArray *)dailyRecordsOfDictionaries:(NSArray *)list
{
    NSMutableArray *dailyRecords = [NSMutableArray array];
    for (NSDictionary *dict in list) {
        NSInteger dateline = [dict[DB_FIELD_EVENTS_DATELINE] integerValue];
        NSInteger type = [dict[DB_FIELD_EVENTS_EVENT] integerValue];
        NSString *data = dict[DB_FIELD_EVENTS_DATA];

        DailyRecord *dailyRecord = nil;
        for (DailyRecord *each in dailyRecords.copy) {
            if (each.dateline == dateline) {
                dailyRecord = each;
                break;
            }
        }

        if (dailyRecord == nil) {
            dailyRecord = [[DailyRecord alloc] init];
            dailyRecord.dateline = dateline;
            [dailyRecords addObject:dailyRecord];
        }

        switch (type) {
            case CALENDAR_EVENT_MEMO:
            {
                dailyRecord.notes = data;
                break;
            }
            default:
                break;
        }
    }

    [dailyRecords sortWithOptions:NSSortStable usingComparator:^NSComparisonResult(id obj1, id obj2) {
        DailyRecord *dailyRecord1 = obj1;
        DailyRecord *dailyRecord2 = obj2;
        if (dailyRecord1.dateline < dailyRecord2.dateline) {
            return NSOrderedAscending;
        }
        return NSOrderedDescending;
    }];

    return dailyRecords.copy;
}

- (NSArray *)dailyRecordsFrom:(NSInteger)from to:(NSInteger)to
{
    NSArray *list = [self.database findAll:@"*" fromTable:DB_TABLE_EVENTS withCondition:[NSString stringWithFormat:@"where " DB_FIELD_EVENTS_DATELINE @" >= '%@' and " DB_FIELD_EVENTS_DATELINE @" <= '%@' and " DB_FIELD_EVENTS_DATA @" != ''", @(from), @(to)]];

    return [self dailyRecordsOfDictionaries:list];
}

- (int64_t)lastUpdateTime
{
    NSDictionary *dict = [self.database findOne:DB_FIELD_EVENTS_UPDATETIME fromTable:DB_TABLE_EVENTS withOrder:@"order by updatetime desc"];
    int64_t lastUpdateTime = 0;
    if (dict != nil) {
        lastUpdateTime = [dict[DB_FIELD_EVENTS_UPDATETIME] longLongValue];
    }
    return lastUpdateTime;
}

- (NSInteger)nonUpdatedCount
{
    NSInteger nonUpdatedCount = [self.database countFromTable:DB_TABLE_EVENTS withCondition:[NSString stringWithFormat:@"where " DB_FIELD_EVENTS_UPDATETIME @" = '0' and " DB_FIELD_EVENTS_DATELINE @" != '0'"]];
    return nonUpdatedCount;
}

- (NSInteger)zeroDatelineCount
{
    NSInteger zeroDatelineCount = [self.database countFromTable:DB_TABLE_EVENTS withCondition:[NSString stringWithFormat:@"where " DB_FIELD_EVENTS_DATELINE @" = '0'"]];
    return zeroDatelineCount;
}

- (NSArray *)datelinesOfAllNoteRecords {
    NSArray *list = [self.database findAll:DB_FIELD_EVENTS_DATELINE fromTable:DB_TABLE_EVENTS withOrder: @"order by " DB_FIELD_EVENTS_DATELINE @" asc" withCondition:[NSString stringWithFormat:@"where " DB_FIELD_EVENTS_DATA @" != '' and " DB_FIELD_EVENTS_EVENT @" = '%@'", @(CALENDAR_EVENT_MEMO)]];

    NSMutableArray *datelines = [NSMutableArray array];
    for (NSDictionary *dictionary in list) {
        [datelines addObject:dictionary[DB_FIELD_EVENTS_DATELINE]];
    }

    return datelines.copy;
}

- (NSInteger)lastDatelineOfAllNoteRecords {
    NSDictionary *dictionary = [self.database findOne:DB_FIELD_EVENTS_DATELINE fromTable:DB_TABLE_EVENTS withOrder: @"order by " DB_FIELD_EVENTS_DATELINE @" desc" withCondition:[NSString stringWithFormat:@"where " DB_FIELD_EVENTS_DATA @" != '' and " DB_FIELD_EVENTS_EVENT @" = '%@'", @(CALENDAR_EVENT_MEMO)]];

    return [dictionary[DB_FIELD_EVENTS_DATELINE] integerValue];
}

- (void)setNoteRecord:(NSString *)noteRecord dateline:(NSInteger)dateline {
    if (dateline == 0) {
        NSLog(@"insert dateline 0");
        return;
    }

    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[DB_FIELD_EVENTS_UPDATETIME] = @(0);
    dict[DB_FIELD_EVENTS_MTIME] = @([[NSDate date] timeIntervalSince1970]);
    dict[DB_FIELD_EVENTS_DATELINE] = @(dateline);
    dict[DB_FIELD_EVENTS_DATA] = noteRecord ?: @"";
    dict[DB_FIELD_EVENTS_EVENT] = @(CALENDAR_EVENT_MEMO);

    BOOL ret = [self.database replace:dict intoTable:DB_TABLE_EVENTS];
    [self checkResult:ret];
}

- (void)removeNoteRecordWithDateline:(NSInteger)dateline {
    [self setNoteRecord:nil dateline:dateline];
}

- (NSString *)noteRecordWithDateline:(NSInteger)dateline {
    NSDictionary *dictionary = [self.database findOne:DB_FIELD_EVENTS_DATA fromTable:DB_TABLE_EVENTS withCondition:[NSString stringWithFormat:@"where " DB_FIELD_EVENTS_DATELINE @" = '%@' and " DB_FIELD_EVENTS_EVENT @" = '%@'", @(dateline), @(CALENDAR_EVENT_MEMO)]];

    return dictionary[DB_FIELD_EVENTS_DATA];
}

- (void)removeAllNoteRecords {
    BOOL ret = [self.database update:@{DB_FIELD_EVENTS_UPDATETIME : @(0), DB_FIELD_EVENTS_DATA : @"" } inTable:DB_TABLE_EVENTS withCondition:[NSString stringWithFormat:@"where " DB_FIELD_EVENTS_EVENT @" = '%@'", @(CALENDAR_EVENT_MEMO)]];
    [self checkResult:ret];
}


@end
