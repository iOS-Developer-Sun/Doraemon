//
//  DoraemonGame.h
//  King
//
//  Created by sunzj on 2/5/16.
//  Copyright © 2016 sunzj. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DoraemonGame : NSObject <NSCopying>

@property (nonatomic, copy) NSDate *beginDate;
@property (nonatomic, copy) NSDate *endDate;
@property (nonatomic, copy) NSArray *gameRecords;
@property (nonatomic, copy) NSArray *playerIds;
@property (nonatomic, copy) NSArray *winnerIds;

- (NSArray *)players;
- (NSArray *)winners;
- (NSArray *)playerCurrentNames;
- (NSArray *)winnerCurrentNames;

+ (instancetype)gameWithJsonString:(NSString *)jsonString;
- (NSString *)jsonString;

@end
