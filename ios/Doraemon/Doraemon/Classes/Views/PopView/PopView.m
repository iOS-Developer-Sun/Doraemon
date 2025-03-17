//
//  PopView.m
//  Dayima
//
//  Created by sunzj on 15/9/9.
//
//

#import "PopView.h"

@interface PopView () <UIGestureRecognizerDelegate>

@property (nonatomic) UIView *maskView;

@end

@implementation PopView

- (instancetype)initWithHeight:(CGFloat)height {
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    CGRect frame = CGRectMake(0, 0, window.width, height);
    return [self initWithFrame:frame];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        UIView *maskView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        maskView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        maskView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
        maskView.hidden = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
        tap.delegate = self;
        [maskView addGestureRecognizer:tap];
        _maskView = maskView;

        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    }
    return self;
}

- (void)tap:(UITapGestureRecognizer *)tap {
    [self maskViewDidTap];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return (touch.view == gestureRecognizer.view);
}

- (void)show {
    self.maskView.hidden = NO;
    [self.maskView addSubview:self];
    [[[UIApplication sharedApplication] keyWindow] addSubview:self.maskView];
    self.center = CGPointMake(self.maskView.width / 2, self.maskView.height + self.height / 2);
    CGRect endFrame = self.frame;
    endFrame.origin.y -= self.height;
    self.maskView.alpha = 0;
    [UIView animateWithDuration:0.3 animations:^{
        self.frame = endFrame;
        self.maskView.alpha = 1;
    }];
}

- (void)hide {
    CGRect endFrame = self.frame;
    endFrame.origin.y += self.height;
    self.maskView.alpha = 1;
    [UIView animateWithDuration:0.3 animations:^{
        self.frame = endFrame;
        self.maskView.alpha = 0;
    } completion:^(BOOL finished) {
        self.maskView.hidden = YES;
        [self.maskView removeFromSuperview];
        [self removeFromSuperview];
    }];
}

- (void)maskViewDidTap {
    [self hide];
}

@end
