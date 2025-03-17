//
//  DoraemonPlayerManager.m
//  Doraemon
//
//  Created by sun on 16/10/26.
//  Copyright © 2016年 sunzj. All rights reserved.
//

#import "DoraemonPlayerManager.h"
#import "UserManager.h"
#import "CalendarDay.h"
#import "NSString+Ext.h"

NSString *const DoraemonPlayerNotificationPlayerIdKey = @"DoraemonPlayerNotificationPlayerIdKey";
NSString *const DoraemonPlayerNotificationPlayerKey = @"DoraemonPlayerNotificationPlayerKey";

NSString *const DoraemonPlayerDidAddNotification = @"DoraemonPlayerDidAddNotification";
NSString *const DoraemonPlayerDidRemoveNotification = @"DoraemonPlayerDidRemoveNotification";
NSString *const DoraemonPlayerDidChangeNotification = @"DoraemonPlayerDidChangeNotification";
NSString *const DoraemonPlayersDidChangeNotification = @"DoraemonPlayersDidChangeNotification";

@interface DoraemonPlayerManager ()

@property (nonatomic) NSCache *cache;

@end

@implementation DoraemonPlayerManager

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

- (NSArray *)playerIds {
    NSArray *datelines = [[UserManager sharedInstance].doraemonPlayerUser.database.eventsDatabaseAccess datelinesOfAllNoteRecords];
    return datelines;
}

- (NSInteger)playerIdOfNewCreatedPlayer {
    NSInteger dateline = [[UserManager sharedInstance].doraemonPlayerUser.database.eventsDatabaseAccess lastDatelineOfAllNoteRecords];
    if (dateline == 0) {
        dateline = [CalendarDay dateline:19880216 byDayOffset:-1];
    }
    NSInteger playerId = [CalendarDay dateline:dateline byDayOffset:1];
    return playerId;
}

- (DoraemonPlayer *)playerForId:(NSInteger)playerId {
    NSNumber *key = @(playerId);
    DoraemonPlayer *player = [self.cache objectForKey:key];
    if (!player) {
        NSString *noteRecord = [[UserManager sharedInstance].doraemonPlayerUser.database.eventsDatabaseAccess noteRecordWithDateline:playerId];
        player = [self playerWithNoteRecord:noteRecord];
        if (player) {
            [self.cache setObject:player forKey:key];
        }
    }
    return player;
}

- (NSInteger)addPlayer:(DoraemonPlayer *)player {
    NSInteger playerId = [self playerIdOfNewCreatedPlayer];
    NSString *noteRecord = [self noteRecordWithPlayer:player];
    [[UserManager sharedInstance].doraemonPlayerUser.database.eventsDatabaseAccess setNoteRecord:noteRecord dateline:playerId];
    [[UserManager sharedInstance].doraemonPlayerUser sync];
    [self.cache setObject:player forKey:@(playerId)];
    [self postNotification:DoraemonPlayerDidAddNotification object:nil userInfo:@{DoraemonPlayerNotificationPlayerIdKey : @(playerId), DoraemonPlayerNotificationPlayerKey : player}];
    return playerId;
}

- (void)setPlayer:(DoraemonPlayer *)player forId:(NSInteger)playerId {
    NSString *noteRecord = [self noteRecordWithPlayer:player];
    [[UserManager sharedInstance].doraemonPlayerUser.database.eventsDatabaseAccess setNoteRecord:noteRecord dateline:playerId];
    [[UserManager sharedInstance].doraemonPlayerUser sync];
    [self.cache setObject:player forKey:@(playerId)];
    [self postNotification:DoraemonPlayerDidChangeNotification object:nil userInfo:@{DoraemonPlayerNotificationPlayerIdKey : @(playerId), DoraemonPlayerNotificationPlayerKey : player}];
}

- (void)removePlayerId:(NSInteger)playerId {
    DoraemonPlayer *player = [self playerForId:playerId];
    [[UserManager sharedInstance].doraemonPlayerUser.database.eventsDatabaseAccess removeNoteRecordWithDateline:playerId];
    [[UserManager sharedInstance].doraemonPlayerUser sync];
    [self postNotification:DoraemonPlayerDidRemoveNotification object:nil userInfo:@{DoraemonPlayerNotificationPlayerIdKey : @(playerId), DoraemonPlayerNotificationPlayerKey : player}];
}

- (void)clearAll {
    [[UserManager sharedInstance].doraemonPlayerUser.database.eventsDatabaseAccess removeAllNoteRecords];
    [[UserManager sharedInstance].doraemonPlayerUser sync];
    [self postNotification:DoraemonPlayersDidChangeNotification object:nil userInfo:nil];
}

- (void)sync {
    [[UserManager sharedInstance].doraemonPlayerUser sync];
}

- (DoraemonPlayer *)playerWithNoteRecord:(NSString *)noteRecord {
    NSString *base64String = [noteRecord JSDecryptedString];
    NSData *data = [[NSData alloc] initWithBase64EncodedString:base64String options:0];
    NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    DoraemonPlayer *player = [DoraemonPlayer playerWithJsonString:jsonString];
    return player;
}

- (NSString *)noteRecordWithPlayer:(DoraemonPlayer *)player {
    NSString *jsonString = player.jsonString;
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
