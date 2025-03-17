//
//  MobileKit.m
//  Dayima
//
//  Created by sunzj on 15/3/23.
//
//

#import "MobileKit.h"

NSString *MobileKitAuthTimeIntervalChangedNotification = @"MobileKitAuthTimeIntervalChangedNotification";

@interface MobileKit()

@property (nonatomic) NSInteger authTimeInterval;
@property (nonatomic) NSTimer *authTimer;

@end

@implementation MobileKit

+ (MobileKit *)sharedInstance
{
    static id instance;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });

    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _authTimeInterval = 0;
    }
    return self;
}

- (void)setAuthTimeInterval:(NSInteger)authTimeInterval
{
    if (authTimeInterval == _authTimeInterval) {
        return;
    }
    _authTimeInterval = authTimeInterval;
    [self postAuthTimeIntervalChangedNotification];
}

- (void)startAuthTimer
{
    @synchronized (self) {
        if (self.authTimer) {
            return;
        }

        self.authTimeInterval = 60;
        self.authTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(authTimerExpires:) userInfo:nil repeats:YES];
    }
}

- (void)stopAuthTimer
{
    @synchronized (self) {
        if (self.authTimer == nil) {
            return;
        }
        self.authTimeInterval = 0;
        [self.authTimer invalidate];
        self.authTimer = nil;
    }
}

- (void)authTimerExpires:(NSTimer *)timer
{
    @synchronized (self) {
        if (self.authTimeInterval == 0) {
            [self.authTimer invalidate];
            self.authTimer = nil;
        } else {
            self.authTimeInterval = self.authTimeInterval - 1;
        }
    }
}

- (void)postAuthTimeIntervalChangedNotification
{
    [[NSNotificationCenter defaultCenter] postNotificationName:MobileKitAuthTimeIntervalChangedNotification object:nil];
}

+ (NSString *)secureMobileNumber:(NSString *)mobileNumber
{
    NSString *secureMobileNumber = mobileNumber.copy;
    if (mobileNumber.length == 11) {
        secureMobileNumber = [mobileNumber stringByReplacingCharactersInRange:NSMakeRange(3, 4) withString:@"****"];
    }
    return secureMobileNumber;
}

+ (void)startAuthTimer
{
    [[MobileKit sharedInstance] startAuthTimer];
}

+ (void)stopAuthTimer
{
    [[MobileKit sharedInstance] stopAuthTimer];
}


+ (NSInteger)authTimeInterval
{
    return [MobileKit sharedInstance].authTimeInterval;
}

@end
