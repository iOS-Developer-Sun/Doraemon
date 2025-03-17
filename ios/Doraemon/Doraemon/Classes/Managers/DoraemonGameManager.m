//
//  DoraemonGameManager.m
//  King
//
//  Created by sunzj on 2/5/16.
//  Copyright © 2016 sunzj. All rights reserved.
//

#import "DoraemonGameManager.h"
#import "UserManager.h"
#import "CalendarDay.h"
#import "NSString+Ext.h"

NSString *const DoraemonGameRecordNotificationGameIdKey = @"DoraemonGameRecordNotificationGameIdKey";
NSString *const DoraemonGameRecordNotificationGameKey = @"DoraemonGameRecordNotificationGameKey";

NSString *const DoraemonGameRecordDidAddNotification = @"DoraemonGameRecordDidAddNotification";
NSString *const DoraemonGameRecordDidRemoveNotification = @"DoraemonGameRecordDidRemoveNotification";
NSString *const DoraemonGameRecordDidChangeNotification = @"DoraemonGameRecordDidChangeNotification";
NSString *const DoraemonGameRecordsDidChangeNotification = @"DoraemonGameRecordsDidChangeNotification";

#import "DoraemonPlayerManager.h"

@interface DoraemonGameManager ()

@property (nonatomic) NSCache *cache;

@end

@implementation DoraemonGameManager

- (instancetype)init {
    self = [super init];
    if (self) {
        _cache = [[NSCache alloc] init];
    }
    return self;
}

- (void)postNotification:(NSString *)notificationName object:(id)object userInfo:(NSDictionary *)userInfo {
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:object userInfo:userInfo];
}

- (NSArray *)gameIds {
    NSArray *datelines = [[UserManager sharedInstance].doraemonGameUser.database.eventsDatabaseAccess datelinesOfAllNoteRecords];
    return datelines;
}

- (NSInteger)gameIdOfNewCreatedGame {
    NSInteger dateline = [[UserManager sharedInstance].doraemonGameUser.database.eventsDatabaseAccess lastDatelineOfAllNoteRecords];
    if (dateline == 0) {
        dateline = [CalendarDay dateline:19880216 byDayOffset:-1];
    }
    NSInteger gameId = [CalendarDay dateline:dateline byDayOffset:1];
    return gameId;
}

- (DoraemonGame *)gameForId:(NSInteger)gameId {
    NSNumber *key = @(gameId);
    DoraemonGame *game = [self.cache objectForKey:key];
    if (!game) {
        NSString *noteRecord = [[UserManager sharedInstance].doraemonGameUser.database.eventsDatabaseAccess noteRecordWithDateline:gameId];
        game = [self gameWithNoteRecord:noteRecord];
        if (game) {
            [self.cache setObject:game forKey:key];
        }
    }
    return game;
}

- (NSInteger)addGame:(DoraemonGame *)game {
    NSInteger gameId = [self gameIdOfNewCreatedGame];
    NSString *noteRecord = [self noteRecordWithGame:game];
    [[UserManager sharedInstance].doraemonGameUser.database.eventsDatabaseAccess setNoteRecord:noteRecord dateline:gameId];
    [[UserManager sharedInstance].doraemonGameUser sync];
    [self.cache setObject:game forKey:@(gameId)];
    [self postNotification:DoraemonGameRecordDidAddNotification object:nil userInfo:@{DoraemonGameRecordNotificationGameIdKey : @(gameId), DoraemonGameRecordNotificationGameKey : game}];
    return gameId;
}

- (void)setGame:(DoraemonGame *)game forId:(NSInteger)gameId {
    NSString *noteRecord = [self noteRecordWithGame:game];
    [[UserManager sharedInstance].doraemonGameUser.database.eventsDatabaseAccess setNoteRecord:noteRecord dateline:gameId];
    [[UserManager sharedInstance].doraemonGameUser sync];
    [self.cache setObject:game forKey:@(gameId)];
    [self postNotification:DoraemonGameRecordDidChangeNotification object:nil userInfo:@{DoraemonGameRecordNotificationGameIdKey : @(gameId), DoraemonGameRecordNotificationGameKey : game}];
}

- (void)removeGameId:(NSInteger)gameId {
    DoraemonGame *game = [self gameForId:gameId];
    [[UserManager sharedInstance].doraemonGameUser.database.eventsDatabaseAccess removeNoteRecordWithDateline:gameId];
    [[UserManager sharedInstance].doraemonGameUser sync];
    [self.cache removeObjectForKey:@(gameId)];
    [self postNotification:DoraemonGameRecordDidRemoveNotification object:nil userInfo:@{DoraemonGameRecordNotificationGameIdKey : @(gameId), DoraemonGameRecordNotificationGameKey : game}];
}

- (void)clearAll {
    [[UserManager sharedInstance].doraemonGameUser.database.eventsDatabaseAccess removeAllNoteRecords];
    [[UserManager sharedInstance].doraemonGameUser sync];
    [self postNotification:DoraemonGameRecordsDidChangeNotification object:nil userInfo:nil];
}

- (void)sync {
    [[UserManager sharedInstance].doraemonGameUser sync];
}

- (DoraemonGame *)gameWithNoteRecord:(NSString *)noteRecord {
    NSString *base64String = [noteRecord JSDecryptedString];
    NSData *data = [[NSData alloc] initWithBase64EncodedString:base64String options:0];
    NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    DoraemonGame *game = [DoraemonGame gameWithJsonString:jsonString];
    return game;
}

- (NSString *)noteRecordWithGame:(DoraemonGame *)game {
    NSString *jsonString = game.jsonString;
    NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSString *base64String = [data base64EncodedStringWithOptions:0];
    NSString *noteRecord = [base64String JSEncryptedString];
    return noteRecord;
}

+ (instancetype)sharedInstance {
    static id instance;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });

    return instance;
}

// scheme://host:port/path?query
- (void)handleOpenURL:(NSURL *)url {
    ;
}

@end
