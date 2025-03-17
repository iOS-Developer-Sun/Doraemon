//
//  SettingsDatabaseAccess.m
//  Dayima
//
//  Created by sunzj on 14-5-13.
//
//

#import "SettingsDatabaseAccess.h"

#define DB_TABLE_SETTINGS               @"settings"
#define DB_FIELD_SETTINGS_KEY           @"key"
#define DB_FIELD_SETTINGS_VALUE         @"value"
#define DB_SQL_CREATE_TABLE_SETTINGS    @"create table if not exists " DB_TABLE_SETTINGS @"("\
DB_FIELD_SETTINGS_KEY @" varchar(40) not null primary key default '', "\
DB_FIELD_SETTINGS_VALUE @" varchar(4000) not null default '')"

@implementation SettingsDatabaseAccess

- (BOOL)create {
    return [self.database executeUpdate:DB_SQL_CREATE_TABLE_SETTINGS];
}

- (void)setObject:(NSString *)object forKeyedSubscript:(NSString *)key {
    [self setValue:object forKey:key];
}

- (void)setValue:(NSString *)value forKey:(NSString *)key {
    if (key == nil) {
        return;
    }

    if (value) {
        BOOL ret = [self.database replace:@{DB_FIELD_SETTINGS_KEY:key, DB_FIELD_SETTINGS_VALUE:value} intoTable:DB_TABLE_SETTINGS];
        [self checkResult:ret];
    } else {
        BOOL ret = [self.database deleteFromTable:DB_TABLE_SETTINGS withCondition:[NSString stringWithFormat:@"where " DB_FIELD_SETTINGS_KEY @" = '%@'", key]];
        [self checkResult:ret];
    }
}

- (NSString *)valueForKey:(NSString *)key {
    if (key == nil) {
        return nil;
    }

    NSString *value = nil;
    NSDictionary *row = [self.database findOne:@"*" fromTable:DB_TABLE_SETTINGS withCondition:[NSString stringWithFormat:@"where " DB_FIELD_SETTINGS_KEY @" = '%@'", key]];
    if (row != nil) {
        value = [NSString stringWithFormat:@"%@", row[DB_FIELD_SETTINGS_VALUE]];
    }

    return value;
}

- (NSString *)objectForKeyedSubscript:(NSString *)key {
    return [self valueForKey:key];
}

- (void)clearInfoSettings
{
    BOOL ret = [self.database deleteFromTable:DB_TABLE_SETTINGS withCondition:@"where key like 'info_%'"];
    [self checkResult:ret];
}

- (void)clearUserSettings
{
    BOOL ret = [self.database deleteFromTable:DB_TABLE_SETTINGS withCondition:@"where key like 'user_%'"];
    [self checkResult:ret];
}

- (void)clearCacheSettings
{
    BOOL ret = [self.database deleteFromTable:DB_TABLE_SETTINGS withCondition:@"where key like 'cache_%'"];
    [self checkResult:ret];
}

- (void)clearInfoCacheSettings
{
    BOOL ret = [self.database deleteFromTable:DB_TABLE_SETTINGS withCondition:@"where key like 'infocache_%'"];
    [self checkResult:ret];
}

- (NSDictionary *)getAllValue
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    NSArray *array = [self.database findAll:@"*" fromTable:DB_TABLE_SETTINGS];
    for (NSDictionary *item in array)
    {
        [dict setValue:item[DB_FIELD_SETTINGS_VALUE] forKey:item[DB_FIELD_SETTINGS_KEY]];
    }
    return dict;
}

- (void)clearAllCache
{
    [self clearCacheSettings];
    [self clearInfoSettings];
    [self clearUserSettings];
    [self clearInfoCacheSettings];
}

@end
