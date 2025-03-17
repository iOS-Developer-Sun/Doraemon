//
//  UIImage+Ext.h
//  Dayima-Forum-Demo
//
//  Created by John on 13-12-23.
//  Copyright (c) 2013年 fiky. All rights reserved.
//

#import <UIKit/UIKit.h>

#ifndef imageNamed
#define imageNamed imageWithName
#endif

@interface UIImage (Ext)

+ (UIImage *)imageWithFile:(NSString *)path;
- (instancetype)initWithFile:(NSString *)path;
+ (UIImage *)imageFromView:(UIView *)view;
- (UIImage *)imageRotateOrientation:(UIImageOrientation)orientation;
+ (UIImage *)imageWithName:(NSString *)name;

+ (UIImage *)compressedImageWithImage:(UIImage *)image maxSize:(CGSize)maxSize;
+ (UIImage *)compressedImageWithImage:(UIImage *)image maxLength:(CGFloat)maxLength;
+ (UIImage *)compressedImageWithImage:(UIImage *)image maxSize:(CGSize)maxSize maxLength:(CGFloat)maxLength;
- (UIImage *)scaledImage:(CGFloat)scale;
- (UIImage *)resizedImage:(CGSize)size;
- (UIImage *)imageByRotatingClockwise;
- (UIImage *)imageByRotatingAnticlockwise;

@end
