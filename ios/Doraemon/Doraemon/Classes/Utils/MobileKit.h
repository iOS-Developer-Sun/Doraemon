//
//  MobileKit.h
//  Dayima
//
//  Created by sunzj on 15/3/23.
//
//

#import <Foundation/Foundation.h>

@interface MobileKit : NSObject

extern NSString *MobileKitAuthTimeIntervalChangedNotification;

+ (NSString *)secureMobileNumber:(NSString *)mobileNumber;
+ (void)startAuthTimer;
+ (void)stopAuthTimer;
+ (NSInteger)authTimeInterval;

@end
