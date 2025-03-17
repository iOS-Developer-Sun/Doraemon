//
//  NSObject+FullDescription.m
//  Dayima-Core
//
//  Created by sunzj on 14-6-26.
//
//

#import "NSObject+FullDescription.h"
#import <objc/runtime.h>

@implementation NSObject (Description)

- (NSString *)fullDescription
{
    NSMutableDictionary *fullDescriptionDictionary = [NSMutableDictionary dictionary];
    NSString *debugDescription = [NSString stringWithFormat:@"<%@>: %p", NSStringFromClass(self.class), self];
    [fullDescriptionDictionary setObject:debugDescription forKey:@"__Object"];
    unsigned int propertiesCount;
    unsigned int i;
    objc_property_t *properties = class_copyPropertyList([self class], &propertiesCount);
    if (properties) {
        for (i=0; i<propertiesCount; i++) {
            objc_property_t property = properties[i];
            NSString * key = [[NSString alloc] initWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
            if ([key isEqualToString:@"description"] || [key isEqualToString:@"debugDescription"] || [key isEqualToString:@"fullDescription"]) {
                continue;
            }
            id value = [self valueForKey:key];
            [fullDescriptionDictionary setObject:value?:@"nil" forKey:key];
        }
        free(properties);
    }

    return fullDescriptionDictionary.description;
}

@end
