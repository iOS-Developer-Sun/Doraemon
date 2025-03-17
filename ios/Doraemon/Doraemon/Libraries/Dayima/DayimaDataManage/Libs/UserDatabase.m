//
//  UserDatabase.m
//  Dayima
//
//  Created by sunzj on 14-5-13.
//
//

#import "UserDatabase.h"

#define DB_VERSION 1

@interface UserDatabase ()

@property (nonatomic) Database *db;

@end

@implementation UserDatabase

- (instancetype)initWithPath:(NSString *)path {
    self = [super init];
    if (self) {
        _eventsDatabaseAccess = [[EventsDatabaseAccess alloc] init];
        _settingsDatabaseAccess = [[SettingsDatabaseAccess alloc] init];
        self.db = [Database databaseWithPath:path];
        [self checkVersion];
    }
    return self;
}

- (void)setDb:(Database *)db {
    _db = db;
    self.eventsDatabaseAccess.database = self.db;
    self.settingsDatabaseAccess.database = self.db;
}

- (void)checkVersion {
    NSInteger oldVersion = [self.db version];
    NSInteger newVersion = DB_VERSION;

    if (newVersion > oldVersion) {
        [self upgradeTo:newVersion oldVersion:oldVersion];
    } else if (newVersion < oldVersion) {
        [self downgradeTo:newVersion oldVersion:oldVersion];
    }
}

- (void)create {
    [self createTables];
}

- (void)createTables {
    [self.eventsDatabaseAccess create];
    [self.settingsDatabaseAccess create];
}

- (void)upgradeTo:(NSInteger)newVersion oldVersion:(NSInteger)oldVersion {
    switch (oldVersion) {
        case 0: {
            [self upgradeFrom0];
        }
        case DB_VERSION: {
            break;
        }
        default: {
            break;
        }
    }
    [self.db setVersion:DB_VERSION];
}

- (void)downgradeTo:(NSInteger)newVersion oldVersion:(NSInteger)oldVersion {
    switch (oldVersion) {
        default: {
            break;
        }
    }
    [self.db setVersion:newVersion];
}

- (Database *)database {
    return self.db;
}

- (void)upgradeFrom0 {
    [self create];
}

@end
