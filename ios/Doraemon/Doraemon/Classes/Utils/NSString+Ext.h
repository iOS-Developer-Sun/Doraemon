//
//  NSString+Ext.h
//  Dayima-Core
//
//  Created by sunzj on 15/3/17.
//  Copyright (c) 2015年 yoloho. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Ext)

- (NSString *)filteredStringWithNumber;
- (NSString *)JSEncryptedString;
- (NSString *)JSDecryptedString;

@end
