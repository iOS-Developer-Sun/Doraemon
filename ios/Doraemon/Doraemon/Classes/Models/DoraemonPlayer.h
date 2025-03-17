//
//  DoraemonPlayer.h
//  Doraemon
//
//  Created by sun on 16/10/25.
//  Copyright © 2016年 sunzj. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DoraemonPlayer : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSArray *aliases;
@property (nonatomic, copy) NSString *avatarUrlString;

- (NSString *)currentName;

+ (instancetype)playerWithJsonString:(NSString *)jsonString;
- (NSString *)jsonString;

@end
