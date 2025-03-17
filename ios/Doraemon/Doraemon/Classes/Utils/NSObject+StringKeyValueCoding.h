//
//  NSObject+StringKeyValueCoding.h
//  Dayima
//
//  Created by sunzj on 14-12-26.
//
//

#import <Foundation/Foundation.h>

@protocol StringKeyValueCoding <NSObject>

- (NSArray *)stringKeyValueItems;

@optional
//为兼容老版本，症状错误，如果新旧版本没有发生变化，不需要实现该方法
- (NSArray *)stringKeyValueReplaceItems;

@end

@interface NSObject (StringKeyValueCoding)

- (NSArray *)stringsOfProperties;
- (NSArray *)strings;
- (void)setPropertiesOfString:(NSString *)string;
- (void)setPropertiesOfStrings:(NSArray *)strings;

- (void)setPropertiesOfString:(NSString *)string withNewValue:(id)value;

@end
