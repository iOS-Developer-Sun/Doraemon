//
//  CroppingView.m
//  Dayima
//
//  Created by sunzj on 15/4/28.
//
//

#import "CroppingView.h"

@implementation CroppingView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    //fill outer rect
    [[UIColor colorWithRed:0. green:0. blue:0. alpha:0.5] set];
    UIRectFill(self.bounds);

    //fill inner border
    [[UIColor colorWithRed:1. green:1. blue:1. alpha:0.5] set];
    UIRectFrame(CGRectInset(self.croppingIndicatorRect, -2, -2));

    //fill inner rect
    [[UIColor clearColor] set];
    UIRectFill(self.croppingIndicatorRect);
}

@end
