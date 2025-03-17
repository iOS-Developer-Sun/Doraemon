//
//  iToast.m
//  iToast
//
//  Created by Diallo Mamadou Bobo on 2/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "iToast.h"

static iToastSettings *sharedSettings = nil;

@interface iToast()
{
    iToastSettings *_settings;
    NSInteger offsetLeft;
    NSInteger offsetTop;

    NSString *text;
}

@property (nonatomic, strong) UIView *view;
@property (nonatomic, strong) NSTimer *timer;

@end


@implementation iToast


- (id) initWithText:(NSString *) tex{
    if (self = [super init]) {
        text = [tex copy];
    }

    return self;
}

- (void) show{

    iToastSettings *theSettings = _settings;

    if (!theSettings) {
        theSettings = [iToastSettings getSharedSettings];
    }

    UIFont *font = [UIFont systemFontOfSize:16];
    CGSize textSize = [text boundingRectWithSize:CGSizeMake(280, 60) options:0 attributes:@{NSFontAttributeName : font} context:nil].size;

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, ceil(textSize.width) + 6, ceil(textSize.height) + 6)];
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor backgroundColor];
    label.font = font;
    label.text = text;
    label.numberOfLines = 0;
    label.textAlignment = NSTextAlignmentCenter;

    UIButton *v = [UIButton buttonWithType:UIButtonTypeCustom];
    v.frame = CGRectMake(0, 0, label.frame.size.width + 12, label.frame.size.height + 12);
    label.center = CGPointMake(v.frame.size.width / 2, v.frame.size.height / 2);
    [v addSubview:label];
    v.backgroundColor = [UIColor grayColor];
    v.layer.cornerRadius = 6;

    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    CGPoint point;
    if (theSettings.gravity == iToastGravityTop) {
        point = CGPointMake(window.frame.size.width / 2, 45);
    }else if (theSettings.gravity == iToastGravityBottom) {
        point = CGPointMake(window.frame.size.width / 2, window.frame.size.height - 45);
    }else if (theSettings.gravity == iToastGravityCenter) {
        point = CGPointMake(window.frame.size.width/2, window.frame.size.height/2);
    }else{
        point = theSettings.postition;
    }

    point = CGPointMake(point.x + offsetLeft, point.y + offsetTop);
    v.center = point;

    self.timer = [NSTimer timerWithTimeInterval:((float)theSettings.duration)/1000
                                    target:self selector:@selector(hideToast)
                                  userInfo:nil repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSDefaultRunLoopMode];

    [window addSubview:v];

    self.view = v;

    [v addTarget:self action:@selector(hideToast) forControlEvents:UIControlEventTouchDown];
}

- (void)hideToast
{
    [UIView animateWithDuration:0.5 animations:^{
        self.view.alpha = 0;
    } completion:^(BOOL finished) {
        [self.view removeFromSuperview];
        [self.timer invalidate];
    }];
}

+ (iToast *) makeText:(NSString *) _text{
    iToast *toast = [[iToast alloc] initWithText:_text];

    return toast;
}


- (iToast *) setDuration:(NSInteger ) duration{
    [self theSettings].duration = duration;
    return self;
}

- (iToast *) setGravity:(iToastGravity) gravity
             offsetLeft:(NSInteger) left
              offsetTop:(NSInteger) top{
    [self theSettings].gravity = gravity;
    offsetLeft = left;
    offsetTop = top;
    return self;
}

- (iToast *) setGravity:(iToastGravity) gravity{
    [self theSettings].gravity = gravity;
    return self;
}

- (iToast *) setPostion:(CGPoint) _position{
    [self theSettings].postition = CGPointMake(_position.x, _position.y);

    return self;
}

-(iToastSettings *) theSettings{
    if (!_settings) {
        _settings = [[iToastSettings getSharedSettings] copy];
    }

    return _settings;
}

@end


@implementation iToastSettings
@synthesize duration;
@synthesize gravity;
@synthesize postition;
@synthesize images;

- (void) setImage:(UIImage *) img forType:(iToastType) type{
    if (!images) {
        images = [[NSMutableDictionary alloc] initWithCapacity:4];
    }

    if (img) {
        NSString *key = @(type).stringValue;
        [images setValue:img forKey:key];
    }
}


+ (iToastSettings *) getSharedSettings{
    if (!sharedSettings) {
        sharedSettings = [[iToastSettings alloc] init];
        sharedSettings.gravity = iToastGravityCenter;
        sharedSettings.duration = iToastDurationNormal;
    }

    return sharedSettings;
    
}

- (id) copyWithZone:(NSZone *)zone{
    iToastSettings *copy = [[iToastSettings alloc] init];
    copy.gravity = self.gravity;
    copy.duration = self.duration;
    copy.postition = self.postition;
    
    NSArray *keys = [self.images allKeys];
    
    for (NSString *key in keys){
        [copy setImage:[images valueForKey:key] forType:[key intValue]];
    }
    
    return copy;
}

@end
