//
//  CroppingCircleView.m
//  Dayima
//
//  Created by sunzj on 15/4/28.
//
//

#import "CroppingCircleView.h"

@interface CroppingCircleView ()

@property (nonatomic, weak) CAShapeLayer *circleLayer;

@end

@implementation CroppingCircleView

- (void)drawRect:(CGRect)rect {
    ;
}

- (void)setCroppingIndicatorRect:(CGRect)croppingIndicatorRect {
    [super setCroppingIndicatorRect:croppingIndicatorRect];

    [self setNeedsLayout];
}

- (void)renderCircle {
    [self.circleLayer removeFromSuperlayer];

    CAShapeLayer *circleLayer = [CAShapeLayer layer];
    [self.layer addSublayer:circleLayer];
    UIBezierPath *circlePath = [UIBezierPath bezierPathWithOvalInRect:self.croppingIndicatorRect];
    [circlePath setUsesEvenOddFillRule:YES];
    [circleLayer setLineWidth:1.0 / [UIScreen mainScreen].scale];
    [circleLayer setStrokeColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.5].CGColor];
    [circleLayer setPath:[circlePath CGPath]];
    [circleLayer setFillColor:[[UIColor clearColor] CGColor]];

    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:0];
    [path appendPath:circlePath];
    [path setUsesEvenOddFillRule:YES];

    CAShapeLayer *fillLayer = [CAShapeLayer layer];
    fillLayer.path = path.CGPath;
    fillLayer.fillRule = kCAFillRuleEvenOdd;
    fillLayer.fillColor = [UIColor colorWithRed:0. green:0. blue:0. alpha:0.5].CGColor;
    [self.layer addSublayer:fillLayer];
    self.circleLayer = fillLayer;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    [self renderCircle];
}

@end