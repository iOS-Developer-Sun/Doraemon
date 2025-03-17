//
//  AppManager.h
//  Dayima
//
//  Created by sunzj on 14-7-30.
//
//

#import <Foundation/Foundation.h>

@interface AppManager : NSObject

@property (nonatomic, copy) NSString *customFont;

+ (instancetype)sharedInstance;
+ (BOOL)installFont:(NSString *)fontFileName;
+ (void)traceCrash;
+ (void)exit;
+ (void)vibrate;
+ (NSString *)deviceId;
+ (BOOL)isOpenRemoteNotification;
+ (void)openSettings;
+ (NSString *)encryptDataByUID:(int64_t)userId withString:(NSString *)string;

@end
