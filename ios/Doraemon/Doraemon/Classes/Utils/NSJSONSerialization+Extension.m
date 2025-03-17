//
//  NSJSONSerialization+Extension.m
//  Sunzj
//
//  Created by sunzj on 16/6/1.
//
//

#import "NSJSONSerialization+Extension.h"

@implementation NSString (NSJSONSerializationExtension)

- (id)objectFromJSONString {
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    id object = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
    if (error) {
        assert(0);
    }
    return object;
}

@end

@implementation NSData (NSJSONSerializationExtension)

- (id)objectFromJSONData {
    NSData *data = self;
    NSError *error = nil;
    id object = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
    if (error) {
        assert(0);
    }
    return object;
}

@end

@implementation NSArray (NSJSONSerializationExtension)

- (NSString *)JSONString {
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:self options:NSJSONWritingPrettyPrinted error:&error];
    if (error) {
        assert(0);
    }
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return string;
}

@end

@implementation NSDictionary (NSJSONSerializationExtension)

- (NSString *)JSONString {
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:self options:0 error:&error];
    if (error) {
        assert(0);
    }
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return string;
}

@end
