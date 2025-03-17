//
//  NSJSONSerialization+Extension.h
//  Sunzj
//
//  Created by sunzj on 16/6/1.
//
//

#import <Foundation/Foundation.h>

@interface NSString (NSJSONSerializationExtension)

- (id)objectFromJSONString;

@end

@interface NSData (NSJSONSerializationExtension)

- (id)objectFromJSONData;

@end

@interface NSArray (NSJSONSerializationExtension)

- (NSString *)JSONString;

@end

@interface NSDictionary (NSJSONSerializationExtension)

- (NSString *)JSONString;

@end
