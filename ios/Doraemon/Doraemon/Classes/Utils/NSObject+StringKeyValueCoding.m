//
//  NSObject+StringKeyValueCoding.m
//  Dayima
//
//  Created by sunzj on 14-12-26.
//
//

#import "NSObject+StringKeyValueCoding.h"

@implementation NSObject (StringKeyValueCoding)

- (NSArray *)stringsOfProperties
{
    NSMutableArray *strings = [NSMutableArray array];
    if (![self conformsToProtocol:@protocol(StringKeyValueCoding)]) {
        return nil;
    }

    NSArray *items = [(id <StringKeyValueCoding>)self stringKeyValueItems];
    for (NSArray *item in items) {
        NSString *s = item[0];
        if (![s isKindOfClass:[NSString class]]) {
            continue;
        }
        id k = item[1];
        id v = item[2];
        id value = [self valueForKeyPath:k];

        if ([value respondsToSelector:@selector(isEqualToNumber:)] && [value isEqualToNumber:v]) {
            [strings addObject:s];
            continue;
        }

        if ([value respondsToSelector:@selector(isEqualToValue:)] && [value isEqualToValue:v]) {
            [strings addObject:s];
            continue;
        }

        if ([value respondsToSelector:@selector(isEqualToString:)] && [value isEqualToString:v]) {
            [strings addObject:s];
            continue;
        }

        if ([value respondsToSelector:@selector(isEqualToArray:)] && [value isEqualToArray:v]) {
            [strings addObject:s];
            continue;
        }

        if ([value respondsToSelector:@selector(isEqualToDictionary:)] && [value isEqualToDictionary:v]) {
            [strings addObject:s];
            continue;
        }

        if ([value respondsToSelector:@selector(isEqualToData:)] && [value isEqualToData:v]) {
            [strings addObject:s];
            continue;
        }
    }
    return strings.copy;
}

- (NSArray *)strings
{
    NSMutableArray *strings = [NSMutableArray array];
    if (![self conformsToProtocol:@protocol(StringKeyValueCoding)]) {
        return nil;
    }

    NSArray *items = [(id <StringKeyValueCoding>)self stringKeyValueItems];
    for (NSArray *item in items) {
        NSString *s = item[0];
        if (![s isKindOfClass:[NSString class]]) {
            continue;
        }
        [strings addObject:s];
    }
    return strings.copy;
}

- (void)setPropertiesOfString:(NSString *)string
{
    if (![self conformsToProtocol:@protocol(StringKeyValueCoding)]) {
        return;
    }
    if ([(id <StringKeyValueCoding>)self respondsToSelector:@selector(stringKeyValueReplaceItems)]) {        
        NSArray * tmpItems = [(id <StringKeyValueCoding>)self stringKeyValueReplaceItems];
        if (tmpItems && tmpItems.count > 0) {
            for (NSArray *item in tmpItems) {
                NSString *s = item[0];
                if (![s isKindOfClass:[NSString class]]) {
                    continue;
                }
                if (![s isEqualToString:string]) {
                    continue;
                }
                string = item[1];
                break;
            }
        }
    }
    
    NSArray *items = [(id <StringKeyValueCoding>)self stringKeyValueItems];
    for (NSArray *item in items) {
        NSString *s = item[0];
        if (![s isKindOfClass:[NSString class]]) {
            continue;
        }
        if (![s isEqualToString:string]) {
            continue;
        }
        id k = item[1];
        id v = item[2];
        [self setValue:v forKeyPath:k];
    }
}

- (void)setPropertiesOfStrings:(NSArray *)strings
{
    for (NSString *string in strings) {
        [self setPropertiesOfString:string];
    }
}

- (void)setPropertiesOfString:(NSString *)string withNewValue:(id)value
{
    if (![self conformsToProtocol:@protocol(StringKeyValueCoding)]) {
        return;
    }

    NSArray *items = [(id <StringKeyValueCoding>)self stringKeyValueItems];
    for (NSArray *item in items) {
        NSString *s = item[0];
        if (![s isKindOfClass:[NSString class]]) {
            continue;
        }
        if (![s isEqualToString:string]) {
            continue;
        }
        id k = item[1];
        id v = value;
        [self setValue:v forKeyPath:k];
    }
}


@end
