//
//  UserDatabase.h
//  Dayima
//
//  Created by sunzj on 14-5-13.
//
//

#import <Foundation/Foundation.h>

#import "EventsDatabaseAccess.h"
#import "SettingsDatabaseAccess.h"

@interface UserDatabase : NSObject

@property (nonatomic, readonly) EventsDatabaseAccess *eventsDatabaseAccess;
@property (nonatomic, readonly) SettingsDatabaseAccess *settingsDatabaseAccess;

- (instancetype)initWithPath:(NSString *)path;
- (Database *)database;

@end
