//
//  NSDictionary+ObjectForKey.m
//  Sunzj
//
//  Created by sunzj on 14-7-25.
//
//

#import "NSDictionary+ObjectForKey.h"

@implementation NSDictionary (ObjectForKey)

- (id)__NSDictionary_ObjectForKey_ClassObjectForKey:(id)key class:(Class)class {
    id object = [self objectForKey:key];
    if ([object isKindOfClass:class]) {
        return object;
    } else {
        return nil;
    }
}

- (NSNumber *)boolNumberForKey:(id)key {
    id object = [self objectForKey:key];
    if ([object respondsToSelector:@selector(boolValue)]) {
        return @([object boolValue]);
    } else {
        return nil;
    }
}

- (NSNumber *)integerNumberForKey:(id)key {
    id object = [self objectForKey:key];
    if ([object respondsToSelector:@selector(integerValue)]) {
        return @([object integerValue]);
    } else {
        return nil;
    }
}

- (NSNumber *)longLongNumberForKey:(id)key {
    id object = [self objectForKey:key];
    if ([object respondsToSelector:@selector(longLongValue)]) {
        return @([object longLongValue]);
    } else {
        return nil;
    }
}

- (NSNumber *)doubleNumberForKey:(id)key {
    id object = [self objectForKey:key];
    if ([object respondsToSelector:@selector(doubleValue)]) {
        return @([object doubleValue]);
    } else {
        return nil;
    }
}

- (NSString *)stringObjectForKey:(id)key {
    return [self __NSDictionary_ObjectForKey_ClassObjectForKey:key class:[NSString class]];
}

- (NSDictionary *)dictionaryObjectForKey:(id)key {
    return [self __NSDictionary_ObjectForKey_ClassObjectForKey:key class:[NSDictionary class]];
}

- (NSArray *)arrayObjectForKey:(id)key {
    return [self __NSDictionary_ObjectForKey_ClassObjectForKey:key class:[NSArray class]];
}

- (NSData *)dataObjectForKey:(id)key {
    return [self __NSDictionary_ObjectForKey_ClassObjectForKey:key class:[NSData class]];
}

@end
