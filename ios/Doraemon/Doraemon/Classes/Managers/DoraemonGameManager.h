//
//  DoraemonGameManager.h
//  King
//
//  Created by sunzj on 2/5/16.
//  Copyright © 2016 sunzj. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DoraemonGame.h"

extern NSString *const DoraemonGameRecordNotificationGameIdKey;
extern NSString *const DoraemonGameRecordNotificationGameKey;

extern NSString *const DoraemonGameRecordDidAddNotification;
extern NSString *const DoraemonGameRecordDidRemoveNotification;
extern NSString *const DoraemonGameRecordDidChangeNotification;
extern NSString *const DoraemonGameRecordsDidChangeNotification;

@interface DoraemonGameManager : NSObject

+ (instancetype)sharedInstance;

- (NSArray *)gameIds;
- (DoraemonGame *)gameForId:(NSInteger)gameId;
- (NSInteger)addGame:(DoraemonGame *)game;
- (void)setGame:(DoraemonGame *)game forId:(NSInteger)gameId;
- (void)removeGameId:(NSInteger)gameId;
- (void)clearAll;
- (void)sync;

@end
