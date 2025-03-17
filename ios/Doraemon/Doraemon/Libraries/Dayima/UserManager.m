//
//  UserManager.m
//  Dayima
//
//  Created by sunzj on 14-12-23.
//
//

#import "UserManager.h"
#import "NSDictionary+ObjectForKey.h"
#import "AppManager.h"

NSString *const UserTokenErrorNotification = @"UserTokenErrorNotification";
NSString *const UserDidLoginNotification = @"UserDidLoginNotification";
NSString *const UserDidLogoutNotification = @"UserDidLogoutNotification";

@class DayimaUser;

@interface DayimaAPI (DayimaUser)

- (instancetype)initWithUser:(DayimaUser *)user;

@end

@interface DataManager (DayimaUser)

- (instancetype)initWithUser:(DayimaUser *)user;
- (void)fina;
- (void)applyDayimaEvents;

@end

@protocol DayimaUserDelegate <NSObject>

- (void)userTokenErrorDidGenerate:(DayimaUser *)user;

@end

@interface DayimaUser ()

@property (nonatomic) UserDatabase *database;
@property (nonatomic, weak) id <DayimaUserDelegate> delegate;

@property (nonatomic, copy) NSString *userId;
@property (nonatomic) UserGender gender;
@property (nonatomic) NSInteger tokenError;
@property (nonatomic, copy) NSString *token;
@property (nonatomic) dispatch_queue_t queue;

@end

@implementation DayimaUser

@synthesize userId = _userId;
@synthesize gender = _gender;
@synthesize tokenError = _tokenError;

@synthesize token = _token;

- (instancetype)initWithUserId:(NSString *)userId gender:(UserGender)gender {
    self = [super init];
    if (self) {
        self.userId = userId.copy;
        self.gender = gender;

        NSString *path = [self databasePathWithUserId:userId gender:gender];
        _database = [[UserDatabase alloc] initWithPath:path];

        _queue = dispatch_queue_create("DayimaUserSyncQueue", NULL);
    }
    return self;
}

- (NSString *)databasePathWithUserId:(NSString *)userId gender:(UserGender)gender {
    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath = [documentPaths objectAtIndex:0];

    NSString *genderString = (gender == UserGenderFemale) ? @"" : @"M";
    NSString *fileName = [NSString stringWithFormat:@"%@%@.db", genderString, userId];
    NSString *filePath = [documentPath stringByAppendingPathComponent:fileName];
    return filePath;
}

- (NSString *)userId {
    return _userId ?: @"";
}

- (void)setUserId:(NSString *)userId {
    _userId = userId.copy;
}

- (void)setTokenError:(NSInteger)tokenError {
    NSInteger originalTokenError = _tokenError;
    if (originalTokenError == tokenError) {
        return;
    }

    _tokenError = tokenError;

    if (originalTokenError == 0 && tokenError != 0) {
        if ([self.delegate respondsToSelector:@selector(userTokenErrorDidGenerate:)]) {
            [self.delegate userTokenErrorDidGenerate:self];
        }
    }
}

- (NSString *)token {
    @synchronized(self) {
        if (_token == nil) {
            _token = self.database.settingsDatabaseAccess[@"token"] ?: @"";
        }
        return _token;
    }
}

- (void)setToken:(NSString *)token {
    @synchronized(self) {
        if ([self.token isEqualToString:token]) {
            return;
        }

        _token = token.copy;
        self.database.settingsDatabaseAccess[@"token"] = self.token;
        self.dayimaApi.token = self.token;
    }
}

- (void)initializeUser {
    _dayimaApi = [[DayimaAPI alloc] initWithUser:self];
    _dataManager = [[DataManager alloc] initWithUser:self];
}

- (void)finalizeUser {
    [_dataManager fina];
}

- (void)sync {
    dispatch_async(self.queue, ^{
        [self syncCalendar];
    });
}

- (BOOL)syncCalendar {
    if (![self.dataManager uploadCalendar]) {
        return NO;
    }

    if (![self.dataManager downloadCalendar]) {
        return NO;
    }

    NSInteger count = self.dataManager.nonUpdatedCount;
    if (count > 0) {
        return NO;
    }

    return YES;
}

- (NSDictionary *)tokenError:(DayimaAPI *)api domain:(NSString *)domain withAction:(NSString *)action withModule:(NSString *)module withParamFull:(DayimaAPIParams *)params url:(NSString *)url json:(NSDictionary *)json token:(NSString *)originalToken {
    if (![originalToken isEqualToString:self.token]) {
        return nil;
    }

    NSLog(@"originalToken:%@\nnewToken:%@", originalToken, self.token);
    NSLog(@"url:%@\njson:%@", url, json);

    NSMutableDictionary *dict = json.mutableCopy;
    [dict setValue:DTEXT(@"加载失败") forKey:@"errdesc"];
    self.tokenError = [[json objectForKey:@"errno"] integerValue];

    return dict;
}

@end

@interface UserManager () <DayimaUserDelegate>

@property (nonatomic) DayimaUser *doraemonGameUser;
@property (nonatomic) DayimaUser *doraemonPlayerUser;

+ (NSString *)userId;
+ (void)setUserId:(NSString *)userId;

+ (UserGender)gender;
+ (void)setGender:(UserGender)gender;

@end

@implementation UserManager

@synthesize doraemonGameUser = _doraemonGameUser;
@synthesize doraemonPlayerUser = _doraemonPlayerUser;

#define DORAEMON_GAME_SERVER_USER_NICKNAME @"DoraemonGame"
#define DORAEMON_GAME_SERVER_USER_PASSWORD @"Doraemon123456"
#define DORAEMON_GAME_SERVER_USER_ID @"227998153"
#define DORAEMON_GAME_SERVER_USER_TOKEN @"227998153-fcff5918e1da89a8175306dd66a5c865"

#define DORAEMON_PLAYER_SERVER_USER_NICKNAME @"DoraemonPlayer"
#define DORAEMON_PLAYER_SERVER_USER_PASSWORD @"Doraemon123456"
#define DORAEMON_PLAYER_SERVER_USER_ID @"228960489"
#define DORAEMON_PLAYER_SERVER_USER_TOKEN @"228960489-f8184d49ef942857b61dd74bc1d59b49"

- (instancetype)init {
    self = [super init];
    if (self) {
        _doraemonGameUser = [self userWithUserId:DORAEMON_GAME_SERVER_USER_ID gender:UserGenderFemale token:DORAEMON_GAME_SERVER_USER_TOKEN];
        _doraemonPlayerUser = [self userWithUserId:DORAEMON_PLAYER_SERVER_USER_ID gender:UserGenderFemale token:DORAEMON_PLAYER_SERVER_USER_TOKEN];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (NSString *)userId {
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"UserManagerCurrentUserId"];
    return userId;
}

+ (void)setUserId:(NSString *)userId {
    [[NSUserDefaults standardUserDefaults] setObject:userId forKey:@"UserManagerCurrentUserId"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (UserGender)gender {
    NSNumber *gender = [[NSUserDefaults standardUserDefaults] objectForKey:@"UserManagerCurrentUserGender"];
    return gender.integerValue;
}

+ (void)setGender:(UserGender)gender {
    [[NSUserDefaults standardUserDefaults] setObject:@(gender) forKey:@"UserManagerCurrentUserGender"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (DayimaUser *)userWithUserId:(NSString *)userId gender:(UserGender)gender token:(NSString *)token {
    @synchronized (self) {
        DayimaUser *user = [[DayimaUser alloc] initWithUserId:userId gender:gender];
        if (token) {
            user.token = token;
        }
        [user initializeUser];
        [user sync];

        return user;
    }
}

#pragma mark - public methods

+ (instancetype)sharedInstance {
    static id instance;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });

    return instance;
}

#pragma mark - DayimaUserDelegate

- (void)userTokenErrorDidGenerate:(DayimaUser *)user {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"TOKEN ERROR" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
    });
}

@end
