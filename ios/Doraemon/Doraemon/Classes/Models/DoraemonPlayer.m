//
//  DoraemonPlayer.m
//  Doraemon
//
//  Created by sun on 16/10/25.
//  Copyright © 2016年 sunzj. All rights reserved.
//

#import "DoraemonPlayer.h"
#import "NSJSONSerialization+Extension.h"

@implementation DoraemonPlayer

- (NSString *)name {
    return _name ?: @"";
}

- (NSArray *)aliases {
    return _aliases ?: @[];
}

- (NSString *)currentName {
    NSString *currentName = self.aliases.firstObject;
    if (currentName == nil) {
        currentName = self.name;
    }
    return currentName;
}

+ (instancetype)playerWithJsonString:(NSString *)jsonString {
    NSDictionary *dictionary = [jsonString objectFromJSONString];
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    DoraemonPlayer *player = [[self alloc] init];
    player.name = dictionary[@"name"];
    player.aliases = dictionary[@"aliases"];
    player.avatarUrlString = dictionary[@"avatarUrlString"];

    return player;
}

- (NSString *)jsonString {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    dictionary[@"name"] = self.name;
    dictionary[@"aliases"] = self.aliases;
    dictionary[@"avatarUrlString"] = self.avatarUrlString;

    NSString *jsonString = [dictionary JSONString];

    return jsonString;
}

@end
