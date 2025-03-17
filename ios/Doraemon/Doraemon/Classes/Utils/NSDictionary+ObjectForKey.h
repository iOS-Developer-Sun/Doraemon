//
//  NSDictionary+ObjectForKey.h
//  Sunzj
//
//  Created by sunzj on 14-7-25.
//
//

#import <Foundation/Foundation.h>

@interface NSDictionary (ObjectForKey)

- (NSNumber *)boolNumberForKey:(id)key;
- (NSNumber *)integerNumberForKey:(id)key;
- (NSNumber *)longLongNumberForKey:(id)key;
- (NSNumber *)doubleNumberForKey:(id)key;
- (NSString *)stringObjectForKey:(id)key;
- (NSDictionary *)dictionaryObjectForKey:(id)key;
- (NSArray *)arrayObjectForKey:(id)key;
- (NSData *)dataObjectForKey:(id)key;

@end
