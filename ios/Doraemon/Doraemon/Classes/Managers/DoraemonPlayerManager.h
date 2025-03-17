//
//  DoraemonPlayerManager.h
//  Doraemon
//
//  Created by sun on 16/10/26.
//  Copyright © 2016年 sunzj. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DoraemonPlayer.h"

extern NSString *const DoraemonPlayerNotificationPlayerIdKey;
extern NSString *const DoraemonPlayerNotificationPlayerKey;

extern NSString *const DoraemonPlayerDidAddNotification;
extern NSString *const DoraemonPlayerDidRemoveNotification;
extern NSString *const DoraemonPlayerDidChangeNotification;
extern NSString *const DoraemonPlayersDidChangeNotification;

@interface DoraemonPlayerManager : NSObject

+ (instancetype)sharedInstance;

- (NSArray *)playerIds;
- (DoraemonPlayer *)playerForId:(NSInteger)playerId;
- (NSInteger)addPlayer:(DoraemonPlayer *)player;
- (void)setPlayer:(DoraemonPlayer *)player forId:(NSInteger)playerId;
- (void)removePlayerId:(NSInteger)playerId;
- (void)clearAll;
- (void)sync;

@end
