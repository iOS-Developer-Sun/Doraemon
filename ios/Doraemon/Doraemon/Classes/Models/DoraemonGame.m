//
//  DoraemonGame.m
//  King
//
//  Created by sunzj on 2/5/16.
//  Copyright © 2016 sunzj. All rights reserved.
//

#import "DoraemonGame.h"
#import "NSJSONSerialization+Extension.h"
#import "DoraemonPlayerManager.h"

@implementation DoraemonGame

- (id)copyWithZone:(NSZone *)zone {
    typeof(self) copy = [[self.class alloc] init];
    copy.beginDate = self.beginDate;
    copy.endDate = self.endDate;
    copy.gameRecords = self.gameRecords;
    copy.playerIds = self.playerIds;
    copy.winnerIds = self.winnerIds;

    return copy;
}

- (NSArray *)players {
    NSMutableArray *players = [NSMutableArray array];
    for (NSNumber *playerId in self.playerIds) {
        DoraemonPlayer *player = [[DoraemonPlayerManager sharedInstance] playerForId:playerId.integerValue];
        [players addObject:player];
    }
    return players;
}

- (NSArray *)winners {
    NSMutableArray *winners = [NSMutableArray array];
    for (NSNumber *winnerId in self.winnerIds) {
        DoraemonPlayer *winner = [[DoraemonPlayerManager sharedInstance] playerForId:winnerId.integerValue];
        [winners addObject:winner];
    }
    return winners.copy;
}

- (NSArray *)playerCurrentNames {
    NSMutableArray *playerNames = [NSMutableArray array];
    for (NSNumber *playerId in self.playerIds) {
        DoraemonPlayer *player = [[DoraemonPlayerManager sharedInstance] playerForId:playerId.integerValue];
        [playerNames addObject:player.currentName];
    }
    return playerNames.copy;
}

- (NSArray *)winnerCurrentNames {
    NSMutableArray *winnerNames = [NSMutableArray array];
    for (NSNumber *winnerId in self.winnerIds) {
        DoraemonPlayer *winner = [[DoraemonPlayerManager sharedInstance] playerForId:winnerId.integerValue];
        [winnerNames addObject:winner.currentName];
    }
    return winnerNames.copy;
}

+ (instancetype)gameWithJsonString:(NSString *)jsonString {
    NSDictionary *dictionary = [jsonString objectFromJSONString];
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    DoraemonGame *game = [[self alloc] init];
    game.beginDate = [NSDate dateWithTimeIntervalSince1970:[dictionary[@"beginDate"] doubleValue]];
    NSTimeInterval endDateTimeInterval = [dictionary[@"endDate"] doubleValue];
    if (endDateTimeInterval == 0) {
        game.endDate = nil;
    } else {
        game.endDate = [NSDate dateWithTimeIntervalSince1970:endDateTimeInterval];
    }
    game.gameRecords = dictionary[@"gameRecords"];
    game.playerIds = dictionary[@"playerIds"];
    game.winnerIds = dictionary[@"winnerIds"];

    return game;
}

- (NSString *)jsonString {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    dictionary[@"beginDate"] = @([self.beginDate timeIntervalSince1970]);
    dictionary[@"endDate"] = @([self.endDate timeIntervalSince1970]);
    dictionary[@"gameRecords"] = self.gameRecords ?: @[];
    dictionary[@"playerIds"] = self.playerIds ?: @[];
    dictionary[@"winnerIds"] = self.winnerIds ?: @[];

    NSString *jsonString = [dictionary JSONString];

    return jsonString;
}

@end
