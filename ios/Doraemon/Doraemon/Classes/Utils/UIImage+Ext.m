//
//  UIImage+Ext.m
//  Dayima-Forum-Demo
//
//  Created by John on 13-12-23.
//  Copyright (c) 2013年 fiky. All rights reserved.
//

#import "UIImage+Ext.h"
#import <objc/runtime.h>

static NSArray *imageExtensions;

@implementation UIImage (Ext)

+ (NSArray *) __UIImage_Ext_imageExtensions
{
    if (imageExtensions == nil) {
        imageExtensions = @[@"", @".png", @".jpg", @".jpeg"];
    }

    return imageExtensions;
}

+ (UIImage *)imageWithFile:(NSString *)path
{
    NSString *dir = [path stringByDeletingLastPathComponent];
    NSString *file = [path lastPathComponent];
    NSString *basename = [file stringByDeletingPathExtension];
    NSString *extension = [file pathExtension];

    NSArray *extensions = [UIImage __UIImage_Ext_imageExtensions];
    if ((extension != nil) && ![extension isEqualToString:@""]) {
        extensions = @[[NSString stringWithFormat:@".%@", extension]];
    }

    NSArray *deviceSuffixes = @[@""];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        deviceSuffixes = @[@"~ipad", @""];
    }

    UIImage *image = nil;
    for (NSString *ext in extensions) {
        for (NSString *deviceSuffix in deviceSuffixes) {
            CGFloat scale = [[UIScreen mainScreen] scale];
            while (scale <= 3) {
                NSString *scaleString = @"";
                if (scale == 2.0) {
                    scaleString = @"@2x";
                } else if (scale == 3.0) {
                    scaleString = @"@3x";
                }

                NSString *fullPath = [dir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@%@%@%@", basename, scaleString, deviceSuffix, ext]];
                if ([[NSFileManager defaultManager] fileExistsAtPath:fullPath]) {
                    image = [self imageWithCGImage:[[UIImage imageWithData:[NSData dataWithContentsOfFile:fullPath]] CGImage] scale:scale orientation:UIImageOrientationUp];
                    if (image) {
                        break;
                    }
                }
                scale += 1.0;
            }
            if (image) {
                break;
            }
        }
        if (image) {
            break;
        }
    }
    
    if (image == nil) {
        image = [self imageWithContentsOfFile:path];
    }

    return image;
}

- (instancetype)initWithFile:(NSString *)path
{
    NSString *dir = [path stringByDeletingLastPathComponent];
    NSString *file = [path lastPathComponent];
    NSString *basename = [file stringByDeletingPathExtension];
    NSString *extension = [file pathExtension];
    
    NSArray *extensions = [UIImage __UIImage_Ext_imageExtensions];
    if ((extension != nil) && ![extension isEqualToString:@""]) {
        extensions = @[[NSString stringWithFormat:@".%@", extension]];
    }
    
    NSArray *deviceSuffixes = @[@""];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        deviceSuffixes = @[@"~ipad", @""];
    }
    
    UIImage *image = nil;
    for (NSString *ext in extensions) {
        for (NSString *deviceSuffix in deviceSuffixes) {
            CGFloat scale = [[UIScreen mainScreen] scale];
            while (scale <= 3) {
                NSString *scaleString = @"";
                if (scale == 2.0) {
                    scaleString = @"@2x";
                } else if (scale == 3.0) {
                    scaleString = @"@3x";
                }
                
                NSString *fullPath = [dir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@%@%@%@", basename, scaleString, deviceSuffix, ext]];
                if ([[NSFileManager defaultManager] fileExistsAtPath:fullPath]) {
                    image = [self initWithCGImage:[[UIImage imageWithData:[NSData dataWithContentsOfFile:fullPath]] CGImage] scale:scale orientation:UIImageOrientationUp];
                    if (image) {
                        break;
                    }
                }
                scale += 1.0;
            }
            if (image) {
                break;
            }
        }
        if (image) {
            break;
        }
    }
    
    if (image == nil) {
        image = [self initWithContentsOfFile:path];
    }
    
    return image;
}

+ (UIImage *)imageFromView:(UIView *)view
{
    CGFloat scale = [UIScreen mainScreen].scale;
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(view.bounds.size.width, view.bounds.size.height), NO, scale);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)imageRotateOrientation:(UIImageOrientation)orientation {
    UIImage *image = [UIImage imageWithCGImage:self.CGImage scale:self.scale orientation:orientation];
    return image;
}

+ (UIImage *)imageWithName:(NSString *)name {
#ifdef imageNamed
#undef imageNamed
    UIImage *image = [self imageNamed:name];
#define imageNamed imageWithName
#else
    UIImage *image = [self imageNamed:name];
#endif
    if (name == nil) {
        NSLog(@"UIImage imageNamed:nil");
    } else {
        if (image == nil) {
            NSLog(@"UIImage imageNamed:%@ returns nil", name);
        }
    }
    return image;
}

+ (UIImage *)compressedImageWithImage:(UIImage *)image maxSize:(CGSize)maxSize
{
    UIImage *compressedImage = image;
    if (image) {
        if ((image.size.width > maxSize.width) || (image.size.height > maxSize.height)) {
            CGFloat scale = MAX(image.size.width/maxSize.width, image.size.height/maxSize.height);
            CGSize newSize = CGSizeMake(image.size.width / scale, image.size.height / scale);
            UIGraphicsBeginImageContext(newSize);
            [image drawInRect:CGRectMake(0, 0, newSize.width,newSize.height)];
            compressedImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
        }
    }
    return compressedImage;
}

+ (UIImage *)compressedImageWithImage:(UIImage *)image maxLength:(CGFloat)maxLength;
{
    UIImage *compressedImage = image;
    if (image) {
        CGFloat compression = 1.0;
        while (YES) {
            @autoreleasepool {
                compressedImage = [UIImage imageWithData:UIImageJPEGRepresentation(image, compression)];
                NSData *data = UIImageJPEGRepresentation(compressedImage, 1.0);
                if (data == nil) {
                    return nil;
                }
                CGFloat dataLength = data.length;
                if (dataLength > maxLength) {
                    if (compression > 0.3) {
                        compression -= 0.3;
                    } else {
                        if (compression > 0.03) {
                            compression -= 0.03;
                        } else {
                            break;
                        }
                    }
                } else {
                    break;
                }

            }
        }
    }
    return compressedImage;
}

+ (UIImage *)compressedImageWithImage:(UIImage *)image maxSize:(CGSize)maxSize maxLength:(CGFloat)maxLength
{
    UIImage *scaledImage = [UIImage imageWithCGImage:image.CGImage scale:1 orientation:image.imageOrientation];
    UIImage *compressedImage = scaledImage;
    CGFloat scale = MAX(scaledImage.size.width / maxSize.width, scaledImage.size.height / maxSize.height);
    if (scale > 1) {
        scale = 1;
    }

    while (YES) {
        @autoreleasepool {
            CGSize size = CGSizeMake(maxSize.width * scale, maxSize.height * scale);
            compressedImage = [self compressedImageWithImage:scaledImage maxSize:size];
            compressedImage = [self compressedImageWithImage:compressedImage maxLength:maxLength];
            if (compressedImage == nil) {
                return nil;
            }
            NSData *data = UIImageJPEGRepresentation(compressedImage, 1.0);
            if (data == nil) {
                return nil;
            }
            if (data.length > maxLength) {
                scale *= maxLength / data.length;
            } else {
                break;
            }
        }
    }

    return compressedImage;
}

- (UIImage *)scaledImage:(CGFloat)scale {
    CGSize newSize = CGSizeMake(self.size.width * scale, self.size.height * scale);
    UIGraphicsBeginImageContext(newSize);
    [self drawInRect:CGRectMake(0, 0, newSize.width,newSize.height)];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return scaledImage;
}

- (UIImage *)resizedImage:(CGSize)size {
    UIGraphicsBeginImageContext(size);
    [self drawInRect:CGRectMake(0, 0, size.width,size.height)];
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return resizedImage;
}

- (UIImage *)imageByRotatingClockwise {
    UIImageOrientation orientation = self.imageOrientation;
    UIImageOrientation newOrientation = orientation;
    switch (orientation) {
        case UIImageOrientationUp:
            newOrientation = UIImageOrientationRight;
            break;
        case UIImageOrientationRight:
            newOrientation = UIImageOrientationDown;
            break;
        case UIImageOrientationDown:
            newOrientation = UIImageOrientationLeft;
            break;
        case UIImageOrientationLeft:
            newOrientation = UIImageOrientationUp;
            break;

        case UIImageOrientationUpMirrored:
            newOrientation = UIImageOrientationRightMirrored;
            break;
        case UIImageOrientationRightMirrored:
            newOrientation = UIImageOrientationDownMirrored;
            break;
        case UIImageOrientationDownMirrored:
            newOrientation = UIImageOrientationLeftMirrored;
            break;
        case UIImageOrientationLeftMirrored:
            newOrientation = UIImageOrientationUpMirrored;
            break;

        default:
            break;
    }
    UIImage *newImage = [[UIImage alloc] initWithCGImage:self.CGImage scale:1.0 orientation:newOrientation];
    return newImage;
}

- (UIImage *)imageByRotatingAnticlockwise {
    UIImageOrientation orientation = self.imageOrientation;
    UIImageOrientation newOrientation = orientation;
    switch (orientation) {
        case UIImageOrientationUp:
            newOrientation = UIImageOrientationLeft;
            break;
        case UIImageOrientationLeft:
            newOrientation = UIImageOrientationDown;
            break;
        case UIImageOrientationDown:
            newOrientation = UIImageOrientationRight;
            break;
        case UIImageOrientationRight:
            newOrientation = UIImageOrientationUp;
            break;

        case UIImageOrientationUpMirrored:
            newOrientation = UIImageOrientationLeftMirrored;
            break;
        case UIImageOrientationLeftMirrored:
            newOrientation = UIImageOrientationDownMirrored;
            break;
        case UIImageOrientationDownMirrored:
            newOrientation = UIImageOrientationRightMirrored;
            break;
        case UIImageOrientationRightMirrored:
            newOrientation = UIImageOrientationUpMirrored;
            break;

        default:
            break;
    }
    UIImage *newImage = [[UIImage alloc] initWithCGImage:self.CGImage scale:1.0 orientation:newOrientation];
    return newImage;
}

@end
