//
//  NSString+Ext.m
//  Dayima-Core
//
//  Created by sunzj on 15/3/17.
//  Copyright (c) 2015年 yoloho. All rights reserved.
//

#import "NSString+Ext.h"

@implementation NSString (Ext)

- (NSString *)filteredStringWithNumber
{
    NSMutableString *numberString = [NSMutableString string];
    NSString *tempStr = @"";
    NSScanner *scanner = [NSScanner scannerWithString:self];
    NSCharacterSet *numbers = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
    while (![scanner isAtEnd]) {
        [scanner scanUpToCharactersFromSet:numbers intoString:NULL];
        [scanner scanCharactersFromSet:numbers intoString:&tempStr];
        [numberString appendString:tempStr?:@""];
        tempStr = @"";
    }
    return numberString.copy;
}

- (NSString *)JSEncryptedString {
    NSMutableString *string = [NSMutableString string];
    NSString *letters = @"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
    for(NSInteger i = 0; i < self.length; i++) {
        NSString *character = [self substringWithRange:NSMakeRange(i, 1)];
        NSRange range = [letters rangeOfString:character];
        NSInteger location = range.location;
        if (location != NSNotFound) {
            NSInteger newLocation;
            if (location < 13) {
                newLocation = location + 39;
            } else if (location < 26) {
                newLocation = location + 13;
            } else if (location < 39) {
                newLocation = location - 13;
            } else {
                newLocation = location - 39;
            }

            character = [letters substringWithRange:NSMakeRange(newLocation, range.length)];
        }
        [string appendString:character];
    }
    return string.copy;
}

- (NSString *)JSDecryptedString {
    return [self JSEncryptedString];
}


@end
