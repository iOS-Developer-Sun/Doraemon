//
//  SettingsDatabaseAccess.h
//  Dayima
//
//  Created by sunzj on 14-5-13.
//
//

#import "DatabaseAccess.h"

@interface SettingsDatabaseAccess : DatabaseAccess

- (BOOL)create;
- (void)setValue:(NSString *)value forKey:(NSString *)key;
- (void)setObject:(NSString *)object forKeyedSubscript:(NSString *)key;
- (NSString *)valueForKey:(NSString *)key;
- (NSString *)objectForKeyedSubscript:(NSString *)key;

- (void)clearAllCache;

- (NSDictionary *)getAllValue;

@end
