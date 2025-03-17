//
//  DailyRecord.h
//  Dayima
//
//  Created by sunzj on 14-5-21.
//
//

#import <Foundation/Foundation.h>

@interface DailyRecord : NSObject <NSCopying>

@property (nonatomic) NSInteger dateline; // 时间
@property (nonatomic) NSInteger updateTime; // 更新时间

@property (nonatomic, copy) NSString *notes; // 备注

@end
