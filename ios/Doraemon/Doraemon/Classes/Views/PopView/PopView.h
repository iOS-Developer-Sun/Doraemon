//
//  PopView.h
//  Dayima
//
//  Created by sunzj on 15/9/9.
//
//

#import <UIKit/UIKit.h>

@interface PopView : UIView

- (instancetype)initWithHeight:(CGFloat)height;

- (void)show;
- (void)hide;
- (void)maskViewDidTap;

@end
