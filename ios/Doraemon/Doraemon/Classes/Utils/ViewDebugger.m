//
//  ViewDebugger.m
//  Dayima
//
//  Created by sunzj on 15/4/28.
//
//

#import "ViewDebugger.h"

@interface ViewDebuggerFrameDetailView : UIView

@property (nonatomic, weak) UITextView *textView;
@property (nonatomic, copy) NSString *pointString;
@property (nonatomic, copy) NSString *viewString;
@property (nonatomic, copy) NSString *viewsString;

@end

@implementation ViewDebuggerFrameDetailView

@synthesize textView;
@synthesize pointString;
@synthesize viewString;
@synthesize viewsString;

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = HEXCOLOR(0x0000007f);
        self.layer.cornerRadius = 10;

        UITextView *tv = [[UITextView alloc] initWithFrame:CGRectInset(self.bounds, 10, 10)];
        [self addSubview:tv];
        self.textView = tv;
        self.textView.font = [UIFont systemFontOfSize:12];
        self.textView.backgroundColor = [UIColor clearColor];
        self.textView.textColor = [UIColor whiteColor];
        self.textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.textView.text = @"ViewDebugger";
        self.textView.text = @"";
        self.textView.editable = NO;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap)];
        [self addGestureRecognizer:tap];
    }
    return self;
}

- (void)setPoint:(CGPoint)point
{
    NSString *text = NSStringFromCGPoint(point);
    self.pointString = text?:@"";
    [self setNeedsLayout];
}

- (void)setView:(UIView *)view
{
    NSMutableArray *views = [NSMutableArray array];
    UIView *eachView = view;
    while (eachView) {
        [views addObject:eachView];
        eachView = eachView.superview;
    }

    NSString *text = [views.copy description];
    self.viewString = text?:@"";
    [self setNeedsLayout];
}

- (void)setViews:(NSArray *)views
{
    NSString *text = views.description;
    self.viewsString = text?:@"";
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    self.textView.text = [NSString stringWithFormat:@"Point: %@\n\nRespondedView: %@\n\nViews: %@\n\n", self.pointString, self.viewString, self.viewsString];
}

- (void)tap
{
    ;
}

@end

@interface ViewDebuggerWindow : DUIWindow

@property (nonatomic, weak) UIView *contentView;
@property (nonatomic, weak) UIView *arrow;
@property (nonatomic) CGPoint beginPoint;
@property (nonatomic, weak) UIWindow *previousKeyWindow;
@property (nonatomic) UIView *frameView;
@property (nonatomic) UIView *framesView;
@property (nonatomic) ViewDebuggerFrameDetailView *frameDetailView;

@end

@implementation ViewDebuggerWindow

@synthesize arrow;
@synthesize beginPoint;
@synthesize previousKeyWindow;
@synthesize frameView;
@synthesize framesView;
@synthesize frameDetailView;

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.windowLevel = DUIWindowLevelViewDebugger;
        self.objectIdentifier = @"ViewDebugger";

        CGFloat lineWidth = 1 / [UIScreen mainScreen].scale;

        self.previousKeyWindow = [UIApplication sharedApplication].keyWindow;
        if (self.previousKeyWindow == nil) {
            self.previousKeyWindow = [UIApplication sharedApplication].windows[0];
        }

        UIView *contentView = [[UIView alloc] initWithFrame:self.bounds];
        contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:contentView];
        _contentView = contentView;

        self.framesView = [[UIView alloc] initWithFrame:contentView.bounds];
        self.framesView.backgroundColor = [UIColor clearColor];
        self.framesView.userInteractionEnabled = NO;
        [self.contentView addSubview:self.framesView];

        self.frameView = [[UIView alloc] init];
        self.frameView.backgroundColor = HEXCOLOR(0xff00003f);
        self.frameView.hidden = YES;
        [self.contentView addSubview:self.frameView];

        self.frameDetailView = [[ViewDebuggerFrameDetailView alloc] initWithFrame:CGRectMake(0, 0, 300, 240)];
        self.frameDetailView.hidden = YES;
        [self.contentView addSubview:frameDetailView];

        UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
        view.center = self.center;
        [self.contentView addSubview:view];
        self.arrow = view;
        self.arrow.clipsToBounds = NO;

        UIView *v1 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 30, lineWidth)];
        v1.backgroundColor = [UIColor redColor];
        UIView *v2 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, lineWidth, 30)];
        v2.backgroundColor = [UIColor redColor];
        [self.arrow addSubview:v1];
        [self.arrow addSubview:v2];

        CGPoint center = CGPointMake(0, 0);
        v1.center = center;
        v2.center = center;
    }
    return self;
}

- (void)makeKeyAndVisible {
    [super makeKeyAndVisible];

    [self bringSubviewToFront:self.contentView];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];

    UITouch *touch = [touches anyObject];
    self.beginPoint = [touch locationInView:self];

    [self debugPoint];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];

    UITouch *touch = [touches anyObject];
    CGPoint currentPoint = [touch locationInView:self];

    CGPoint originalPoint = self.beginPoint;
    CGRect frame = self.arrow.frame;
    frame.origin.x += (currentPoint.x - originalPoint.x);
    if (frame.origin.x < 0) {
        frame.origin.x = 0;
    }
    if (frame.origin.x > self.bounds.size.width - frame.size.width) {
        frame.origin.x = self.bounds.size.width - frame.size.width;
    }
    frame.origin.y += (currentPoint.y - originalPoint.y);
    if (frame.origin.y < 0) {
        frame.origin.y = 0;
    }
    if (frame.origin.y > self.bounds.size.height - frame.size.height) {
        frame.origin.y = self.bounds.size.height - frame.size.height;
    }
    self.arrow.frame = frame;

    self.beginPoint = currentPoint;
    [self debugPoint];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];

    UITouch *touch = [touches anyObject];
    CGPoint currentPoint = [touch locationInView:self];
    self.beginPoint = currentPoint;
    [self debugPoint];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];

    UITouch *touch = [touches anyObject];
    CGPoint currentPoint = [touch locationInView:self];
    self.beginPoint = currentPoint;
    [self debugPoint];
}

- (void)setView:(UIView *)view
{
    CGRect frame = [self.previousKeyWindow convertRect:view.frame fromView:view.superview];
    self.frameView.frame = frame;
    self.frameView.hidden = NO;
}

- (void)setViews:(NSArray *)views
{
    for (UIView *view in self.framesView.subviews) {
        [view removeFromSuperview];
    }

    for (UIView *view in views) {
        UIView *v = [[UIView alloc] init];
        v.backgroundColor = [UIColor clearColor];
        v.layer.borderWidth = 1 / [UIScreen mainScreen].scale;
        v.layer.borderColor = [UIColor blackColor].CGColor;
        [self.framesView addSubview:v];
        CGRect frame = [self.previousKeyWindow convertRect:view.frame fromView:view.superview];
        v.frame = frame;
        v.layer.cornerRadius = (v.frame.size.width < v.frame.size.height ? v.frame.size.width : v.frame.size.height) / 16;
    }
}

- (void)debugPoint
{
    CGPoint point = self.arrow.frame.origin;
    UIView *view = [self.previousKeyWindow hitTest:point withEvent:nil];
    NSArray *views = [self viewsOfPoint:point];

    self.view = view;
    self.views = views;

    self.frameDetailView.point = point;
    self.frameDetailView.view = view;
    self.frameDetailView.views = views;
    self.frameDetailView.hidden = NO;
    if (point.x < self.width / 2) {
        self.frameDetailView.right = self.right;
    } else {
        self.frameDetailView.left = self.left;
    }

    if (point.y < self.height / 2) {
        self.frameDetailView.bottom = self.bottom;
    } else {
        self.frameDetailView.top = self.top;
    }
}

- (NSArray *)viewsOfPoint:(CGPoint)point
{
    NSMutableArray *views = [NSMutableArray array];
    if (self.previousKeyWindow) {
        [views addObject:self.previousKeyWindow];
    }

    for (NSInteger i = 0; i < views.count; i++) {
        UIView *view = views[i];
        for (UIView *subview in view.subviews) {
            if ([subview isKindOfClass:NSClassFromString(@"UITableViewWrapperView")]) {
                [views addObject:subview];
                continue;
            }
            CGPoint pointInView = [view convertPoint:point fromView:self.previousKeyWindow];
            if (CGRectContainsPoint(subview.frame, pointInView)) {
                [views addObject:subview];
            }
        }
    }

    NSMutableArray *viewsOfPoint = [NSMutableArray array];
    for (UIView *view in views) {
        [viewsOfPoint insertObject:view atIndex:0];
    }

    return viewsOfPoint.copy;
}

@end

@interface ViewDebugger()

@end

@implementation ViewDebugger

static ViewDebuggerWindow *debuggerWindow;

+ (BOOL)isDebugging {
    return (debuggerWindow != nil);
}

+ (void)startDebugging
{
    if (debuggerWindow != nil) {
        return;
    }

    debuggerWindow = [[ViewDebuggerWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [debuggerWindow makeKeyAndVisible];
}

+ (void)stopDebugging
{
    if (debuggerWindow == nil) {
        return;
    }

    debuggerWindow.hidden = YES;
    debuggerWindow = nil;
    [DUIWindow switchWindow];
}

@end
