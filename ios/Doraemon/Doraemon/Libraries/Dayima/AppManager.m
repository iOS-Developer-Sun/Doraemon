//
//  AppManager.m
//  Dayima
//
//  Created by sunzj on 14-7-30.
//
//

#import "AppManager.h"
#import <execinfo.h>
#import <CoreText/CoreText.h>
#import <AudioToolbox/AudioToolbox.h>
#import "dayima_crypt_crypt.h"
#import "UserManager.h"
#import <AVFoundation/AVFoundation.h>

#define LOG_LEVEL_SETTING @"LOG_LEVEL_SETTING"
#define LOG_MODE_SETTING @"LOG_MODE_SETTING"

#define APP_LAUNCHING_TIMES @"APP_LAUNCHING_TIMES"
#define LAST_CACHE_CLEAR_DATE @"LAST_CACHE_CLEAR_DATE"

#define CUSTOM_FONT_STRING @"CUSTOM_FONT_STRING"

#define AppEnterBackground @"AppEnterBackgroud"

#define APP_VERSION 4

NSString *const AppFontChangedNotification = @"AppFontChangedNotification";

static NSString *AppHasDoneTodayKey = @"AppHasDoneToday";
static NSString *AppVersionKey = @"DayimaAppVersionKey";

@interface UIApplication (AppManager)

- (void)workspaceShouldExit:(BOOL)shouldExit;

@end

@interface AppManager()

@end

@implementation AppManager

- (instancetype)init {
    self = [super init];
    if (self) {
        [UserManager sharedInstance];

        (void)[[AVSpeechSynthesizer alloc] init];
    }
    return self;
}


+ (instancetype)sharedInstance {
    static id instance;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });

    return instance;
}

+ (BOOL)installFont:(NSString *)fontFileName {
    if (fontFileName.length == 0) {
        return NO;
    }

    NSString *pathname = fontFileName;
    if (![[NSFileManager defaultManager] fileExistsAtPath:pathname]) {
        return NO;
    }
    CGFontRef customFont;
    @try {
        CGDataProviderRef fontDataProvider = CGDataProviderCreateWithFilename([pathname UTF8String]);
        customFont = CGFontCreateWithDataProvider(fontDataProvider);
        CGDataProviderRelease(fontDataProvider);
        CTFontManagerRegisterGraphicsFont(customFont, nil);
        CGFontRelease(customFont);
    } @catch (NSException* e) {
        CGFontRelease(customFont);
        return NO;
    }
    return YES;
}

static void appManagerExceptionHandler(NSException *exception) {
    NSMutableString *exceptionString = [NSMutableString string];
    [exceptionString appendFormat:@"Exception!\n"];
    [exceptionString appendFormat:@"name : %@\n", exception.name];
    [exceptionString appendFormat:@"reason : %@\n", exception.reason];
    [exceptionString appendFormat:@"userInfo : %@\n", exception.userInfo];
    [exceptionString appendFormat:@"callStackSymbols : %@\n", exception.callStackSymbols];
    [exceptionString appendFormat:@"callStackReturnAddresses : %@\n", exception.callStackReturnAddresses];

    NSLog(@"%@", exceptionString);

    if (originalExceptionHandler) {
        originalExceptionHandler(exception);
    }
}

static NSUncaughtExceptionHandler *originalExceptionHandler = NULL;

+ (void)traceCrash {
    NSUncaughtExceptionHandler *handler = NSGetUncaughtExceptionHandler();
    originalExceptionHandler = handler;
    NSSetUncaughtExceptionHandler(&appManagerExceptionHandler);
}

+ (void)exit {
    [UIView animateWithDuration:0.5 animations:^{
        [UIApplication sharedApplication].delegate.window.alpha = 0;
    } completion:^(BOOL finished) {
        [UIApplication sharedApplication].statusBarHidden = YES;
    }];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self exitApplication];
    });
}

+ (void)exitApplication {
#if DEBUG
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(workspaceShouldExit:)]) {
        [[UIApplication sharedApplication] workspaceShouldExit:YES];
    } else {
        abort();
    }
#endif
}

+ (void)vibrate {
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}

+ (NSString *)deviceId {
    return @"a8ed7ba8fc07881cff0c1161dec57bad";
}

+ (BOOL)isOpenRemoteNotification {
    UIUserNotificationSettings *settings = [UIApplication sharedApplication].currentUserNotificationSettings;
    if (settings.types != UIUserNotificationTypeNone) {
        return YES;
    } else {
        return NO;
    }
}

+ (void)openSettings {
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }
}

+ (NSString *)encryptDataByUID:(int64_t)userId withString:(NSString *)string {
    char buf[33] = {0};
    const char *data = [string UTF8String];
    long long data_len = strlen((const char *)data);
    dayima_crypt_encrypt_data(userId, (const unsigned char *)data, data_len, buf);
    return [NSString stringWithFormat:@"%s", buf];
}

@end
