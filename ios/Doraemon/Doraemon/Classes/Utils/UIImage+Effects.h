//
//  UIImage+Effects.h
//  Dayima
//
//  Created by 谭斌 on 15/8/15.
//
//

#import <UIKit/UIKit.h>

@interface UIImage (Effects)

- (UIImage *)applySubtleEffect;
- (UIImage *)applyLightEffect;
- (UIImage *)applyExtraLightEffect;
- (UIImage *)applyDarkEffect;
- (UIImage *)applyTintEffectWithColor:(UIColor *)tintColor;
- (UIImage *)applyBlurWithRadius:(CGFloat)blurRadius tintColor:(UIColor *)tintColor saturationDeltaFactor:(CGFloat)saturationDeltaFactor maskImage:(UIImage *)maskImage;

@end
