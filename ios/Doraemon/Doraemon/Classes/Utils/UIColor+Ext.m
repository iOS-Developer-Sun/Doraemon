//
//  UIColor+Ext.m
//  Dayima
//
//  Created by sunzj on 15/6/26.
//
//

#import "UIColor+Ext.h"

@implementation UIColor (Ext)

+ (instancetype)randomColor {
    CGFloat r = arc4random() % 256 / 255.0;
    CGFloat g = arc4random() % 256 / 255.0;
    CGFloat b = arc4random() % 256 / 255.0;
    return [UIColor colorWithRed:r green:g blue:b alpha:1];
}

+ (instancetype)textColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor labelColor];
    } else {
        return [UIColor blackColor];
    }
}

+ (instancetype)backgroundColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor systemBackgroundColor];
    } else {
        return [UIColor whiteColor];
    }
}


@end
