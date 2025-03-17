//
//  UserManager.h
//  Dayima
//
//  Created by sunzj on 14-12-23.
//
//

#import <Foundation/Foundation.h>
#import "UserDatabase.h"
#import "DataManager.h"
#import "DayimaAPI.h"

extern NSString *const UserTokenErrorNotification;
extern NSString *const UserDidLoginNotification;
extern NSString *const UserDidLogoutNotification;

typedef NS_ENUM(NSInteger, UserGender) {
    UserGenderFemale,
    UserGenderMale,
};

@interface DayimaUser : NSObject <DayimaAPIDelegate>

// 结构相关的属性
@property (nonatomic, readonly) DayimaAPI *dayimaApi;
@property (nonatomic, readonly) UserDatabase *database;
@property (nonatomic, readonly) DataManager *dataManager;

// 基础属性
@property (nonatomic, copy, readonly) NSString *userId;
@property (nonatomic, readonly) UserGender gender;
@property (nonatomic, readonly) NSInteger tokenError;
@property (nonatomic, copy, readonly) NSString *token;

- (void)sync;

@end

@interface UserManager : NSObject

@property (nonatomic, readonly) DayimaUser *doraemonGameUser;
@property (nonatomic, readonly) DayimaUser *doraemonPlayerUser;

+ (instancetype)sharedInstance;

@end
