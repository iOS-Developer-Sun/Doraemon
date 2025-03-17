//
//  UIColor+Ext.h
//  Dayima
//
//  Created by sunzj on 15/6/26.
//
//

#import <UIKit/UIKit.h>

#define HEXCOLOR(c) [UIColor colorWithRed:(CGFloat)(((c>>24)&0xFF)/255.0) green:(CGFloat)(((c>>16)&0xFF)/255.0) blue:(CGFloat)(((c>>8)&0xFF)/255.0) alpha:(CGFloat)(((c)&0xFF)/255.0)]

@interface UIColor (Ext)

+ (instancetype)randomColor;

+ (instancetype)textColor;
+ (instancetype)backgroundColor;

@end
