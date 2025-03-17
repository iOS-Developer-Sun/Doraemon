//
//  DataManager.m
//  Dayima
//
//  Created by sunzj on 14-5-13.
//
//

#import "DataManager.h"
#import "Event.h"
#import "UserManager.h"
#import "EventsDatabaseAccess.h"
#import "CalendarDay.h"
#import "NSJSONSerialization+Extension.h"
#import "NSDictionary+ObjectForKey.h"

NSString *const DailyRecordChangedNotification = @"DailyRecordChangedNotification";
NSString *const NonUpdatedCountChangedNotification = @"NonUpdatedCountChangedNotification";

@interface DataManager ()

@property (nonatomic, weak) DayimaUser *user;
@property (nonatomic) UserDatabase *database;

@property (nonatomic, copy) DailyRecord *todayRecord;
@property (nonatomic) int64_t lastUpdate;

@end

@implementation DataManager

@synthesize todayRecord = _todayRecord;

- (instancetype)initWithUser:(DayimaUser *)user {
    if (self = [super init]) {
        _user = user;
        _database = user.database;
        _lastUpdate = [self.database.eventsDatabaseAccess lastUpdateTime];
        [self reload];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(timeChanged:) name:UIApplicationSignificantTimeChangeNotification object:nil];
    }
    return self;
}

- (void)fina {
    self.user = nil;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)reload {
    [self reloadTodayRecord];
}

- (void)timeChanged:(NSNotification *)notification {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self reload];
    });
}

- (void)postNonUpdatedCountChangedNotification {
    if (self.user) {
        [[NSNotificationCenter defaultCenter] postNotificationName:NonUpdatedCountChangedNotification object:nil];
    }
}

- (void)postDailyRecordChangedNotification:(NSInteger)dateline {
    if (self.user) {
        [[NSNotificationCenter defaultCenter] postNotificationName:DailyRecordChangedNotification object:@(dateline)];
    }
}

- (void)reloadTodayRecord {
    self.todayRecord = nil;
}

- (void)uploadData {
    if (self.user.gender == UserGenderFemale) {
        [self.user sync];
    }
}

#pragma mark - public methods

//- (int64_t)lastUpdate {
//    int64_t lastUpdate = [self.database.eventsDatabaseAccess lastUpdateTime];
//    if (_lastUpdate < lastUpdate) {
//        _lastUpdate = lastUpdate;
//    }
//
//    return _lastUpdate;
//}

- (DailyRecord *)todayRecord {
    @synchronized (self) {
        NSInteger today = [CalendarDay datelineToday];
        if (_todayRecord == nil || (_todayRecord.dateline != today)) {
            NSArray *dailyRecords = [self.database.eventsDatabaseAccess dailyRecordsFrom:today to:today];
            if (dailyRecords.count > 0) {
                _todayRecord = dailyRecords[0];
            }
            else
            {
                _todayRecord = [[DailyRecord alloc] init];
                _todayRecord.dateline = today;
            }
        }
        return _todayRecord.copy;
    }
}

- (void)setTodayRecord:(DailyRecord *)todayRecord {
    @synchronized (self) {
        _todayRecord = todayRecord;
    }
}

- (DailyRecord *)dailyRecordOfDateline:(NSInteger)dateline {
    NSInteger today = [CalendarDay datelineToday];
    if (dateline == today) {
        return self.todayRecord;
    }
    
    NSArray *dailyRecords = [self.database.eventsDatabaseAccess dailyRecordsFrom:dateline to:dateline];
    DailyRecord *dailyRecord = nil;
    if (dailyRecords.count > 0) {
        dailyRecord = dailyRecords[0];
    } else {
        dailyRecord = [[DailyRecord alloc] init];
        dailyRecord.dateline = dateline;
    }
    
    return dailyRecord;
}

- (NSArray *)dailyRecordsFrom:(NSInteger)from to:(NSInteger)to {
    NSArray *dailyRecords = [self.database.eventsDatabaseAccess dailyRecordsFrom:from to:to];
    return dailyRecords;
}

- (NSInteger)nonUpdatedCount {
    NSInteger nonUpdatedCount = [self.database.eventsDatabaseAccess nonUpdatedCount];
    if (nonUpdatedCount != 0) {
        NSInteger zeroDatelineCount = [self.database.eventsDatabaseAccess zeroDatelineCount];
        if (zeroDatelineCount != 0) {
            NSLog(@"dateline is 0!");
        }
    }
    return nonUpdatedCount;
}

- (void)setDailyRecord:(DailyRecord *)dailyRecord {
    Event *event = [[Event alloc] init];
    event.mtime = [[NSDate date] timeIntervalSince1970];
    event.updateTime = 0;
    event.dateline = dailyRecord.dateline;

    DailyRecord *originalDailyRecord = [self dailyRecordOfDateline:dailyRecord.dateline];
    BOOL dataChanged = NO;
    BOOL isToday = (dailyRecord.dateline == [CalendarDay datelineToday]);
    
    if (![dailyRecord.notes isEqualToString:originalDailyRecord.notes]) {
        event.type = CALENDAR_EVENT_MEMO;
        event.data = dailyRecord.notes;
        [self.database.eventsDatabaseAccess insertEvent:event];
        dataChanged = YES;
    }

    // 日历数据发生变化，相关页面刷新
    if (dataChanged) {
        if (isToday) {
            [self reloadTodayRecord];
        }
        [self uploadData];
        [self postDailyRecordChangedNotification:dailyRecord.dateline];
    }
}

- (void)clearAllData {
    [self.database.eventsDatabaseAccess clearAllEvents];
    self.lastUpdate = 0;
    
    [self reload];
}

- (void)addEvents:(NSArray *)listToAdd {
    __block BOOL hasChanged = NO;
    NSInteger nonUpdatedCount = [self nonUpdatedCount];
    [self.database.database executeTransaction:^BOOL{
        for (Event *each in listToAdd.copy) {
            Event *event = [self.database.eventsDatabaseAccess eventWithEvent:each.type dateline:each.dateline];
            [self.database.eventsDatabaseAccess insertEvent:each];
            if (![event.data isEqualToString:each.data]) {
                hasChanged = YES;
            }
        }
        return YES;
    }];

    NSInteger newNonUpdatedCount = [self nonUpdatedCount];

    if (hasChanged) {
        [self reload];
    }

    if (nonUpdatedCount != newNonUpdatedCount) {
        [self postNonUpdatedCountChangedNotification];
    }
}

- (BOOL)uploadCalendar {
    BOOL ret = YES;
    NSInteger page = 0;
    NSInteger countPerPage = 100;
    while (YES) {
        NSArray *list = [self.database.eventsDatabaseAccess nonUpdatedEventsWithPage:page countPerPage:countPerPage];
        if (list.count == 0) {
            break;
        }

        NSMutableArray *data = [NSMutableArray array];
        for (Event *event in list) {
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            dict[@"dateline"] = @(event.dateline);
            dict[@"eventtype"] = @(event.type);
            dict[@"data"] = event.data;
            dict[@"mtime"] = @(event.mtime);
            [data addObject:dict];
        }

        NSDictionary *param = [[NSDictionary alloc] initWithObjectsAndKeys:[data JSONString], @"data", nil];
        NSDictionary *json = [self.user.dayimaApi api:@"update" withModule:@"calendar" withParam:param];
        if (json == nil || [[json objectForKey:@"errno"] integerValue] != 0) {
            ret = NO;
            break;
        }
        page++;
    }

    return ret;
}

- (int64_t)lastUpdate {
    return self.user.database.eventsDatabaseAccess.lastUpdateTime;
}

- (BOOL)downloadCalendar {
    BOOL ret = YES;
    int64_t lastUpdate = self.lastUpdate;
    NSDictionary *param = nil;
    NSDictionary *json = nil;

    NSMutableArray *listToAdd = [NSMutableArray array];
    while (YES) {
        param = [[NSDictionary alloc] initWithObjectsAndKeys:@(lastUpdate), @"lastupdate", nil];
        json = [self.user.dayimaApi api:@"getdata" withModule:@"calendar" withParam:param];
        if (json == nil || [[json objectForKey:@"errno"] integerValue] != 0) {
            ret = NO;
            break;
        }

        NSArray *list = [json arrayObjectForKey:@"data"];
        if (list.count == 0) {
            break;
        }

        NSInteger count = 0;

        for (NSInteger i = 0; i < [list count]; i++) {
            NSDictionary *item = [list objectAtIndex:i];
            if (![item isKindOfClass:[NSDictionary class]]) {
                continue;
            }

            NSInteger dateline = [[item objectForKey:@"dateline"] integerValue];
            NSNumber *typeNumber = [item integerNumberForKey:@"eventtype"];
            if (typeNumber == nil) {
                continue;
            }

            Event *event = [[Event alloc] init];
            event.dateline = dateline;
            event.type = [item[@"eventtype"] integerValue];
            event.data = item[@"data"];
            event.updateTime = [[item objectForKey:@"updatetime"] longLongValue];
            event.mtime = [item[@"mtime"] longLongValue];
            if (dateline > 0) {
                [listToAdd addObject:event];
            }
            if (dateline > 0) {
                int64_t curLastupdate = [[item objectForKey:@"updatetime"] longLongValue];
                if (curLastupdate > lastUpdate) {
                    lastUpdate = curLastupdate;
                }
                count ++;
            }
        }

        if (count < 1) {
            break;
        }
    }

    //刷新首页和日历
    if (listToAdd.count > 0) {
        [self addEvents:listToAdd];
    }

    return ret;
}

@end

