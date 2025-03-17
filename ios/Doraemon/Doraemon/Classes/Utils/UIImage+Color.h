//
//  UIImage+Color.h
//  Dayima
//
//  Created by sunzj on 14-9-2.
//
//

#import <UIKit/UIKit.h>

@interface UIImage (Color)

+ (UIImage *)imageWithColor:(UIColor *)color;
+ (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size;
- (UIImage *)imageWithATintColor:(UIColor *)color;

@end
