//
//  DUIWindow.m
//  Dayima
//
//  Created by sunzj on 14-11-11.
//
//

#import "DUIWindow.h"
#import "DUIViewController.h"
#import "MemoryContainer.h"

NSString *const DUIWindowShakeNotification = @"DUIWindowShakeNotification";
NSString *const DUIWindowKeyWindowChangedNotification = @"DUIWindowKeyWindowChangedNotification";
NSString *const DUIWindowHiddenNotification = @"DUIWindowHiddenNotification";

const UIWindowLevel DUIWindowLevelKeyboard = 10000000;

UIWindowLevel DUIWindowLevelLaunchImage;
UIWindowLevel DUIWindowLevelAd;
UIWindowLevel DUIWindowLevelPrivacyPassword;
UIWindowLevel DUIWindowLevelGuide;
UIWindowLevel DUIWindowLevelViewDebugger;
UIWindowLevel DUIWindowLevelMemoryDebugger;
UIWindowLevel DUIWindowLevelDevelopmentToolMenu;

@interface DUIWindowRootViewController : DUIViewController

@property (nonatomic, copy) void (^viewDidFirstlyAppearHandler)(void);

@end

@implementation DUIWindowRootViewController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.viewDidFirstlyAppearHandler) {
        self.viewDidFirstlyAppearHandler();
    }
}

@end

@interface DUIWindow ()

@end

@implementation DUIWindow

@synthesize objectIdentifier;

+ (void)load {
    UIWindowLevel *p;

    p = &DUIWindowLevelLaunchImage;
    *p = UIWindowLevelAlert;

    p = &DUIWindowLevelAd;
    *p = UIWindowLevelStatusBar + 1;

    p = &DUIWindowLevelPrivacyPassword;
    *p = UIWindowLevelNormal + 1;

    p = &DUIWindowLevelGuide;
    *p = UIWindowLevelStatusBar + 2;

    p = &DUIWindowLevelViewDebugger;
    *p = UIWindowLevelAlert + 1;

    p = &DUIWindowLevelMemoryDebugger;
    *p = DUIWindowLevelKeyboard;

    p = &DUIWindowLevelDevelopmentToolMenu;
    *p = DUIWindowLevelKeyboard;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        DUIWindowRootViewController *viewController = [[DUIWindowRootViewController alloc] init];
        viewController.objectIdentifier = @"WindowRootController";
        viewController.view.backgroundColor = [UIColor clearColor];
        self.rootViewController = viewController;
        LOG_MEMORY;
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        DUIWindowRootViewController *viewController = [[DUIWindowRootViewController alloc] init];
        viewController.objectIdentifier = @"WindowRootController";
        viewController.view.backgroundColor = [UIColor clearColor];
        self.rootViewController = viewController;
        LOG_MEMORY;
    }
    return self;
}

- (void)becomeKeyWindow {
    [super becomeKeyWindow];

    [self postWindowKeyWindowChangedNotification];
}

- (void)resignKeyWindow {
    [super resignKeyWindow];

    [self postWindowKeyWindowChangedNotification];
}

- (void)setHidden:(BOOL)hidden {
    [super setHidden:hidden];

    [[NSNotificationCenter defaultCenter] postNotificationName:DUIWindowHiddenNotification object:self];
}

- (void)postWindowKeyWindowChangedNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:DUIWindowKeyWindowChangedNotification object:self];
}

- (void)makeKeyAndVisible {
    [super makeKeyAndVisible];
}

- (NSString *)description {
    NSString *description = [NSString stringWithFormat:@"%@, windowLevel = %@, id = %@", [super description], @(self.windowLevel), self.objectIdentifier ?: @""];
    return description;
}

- (void)setRootViewControllerViewDidFirstlyAppear:(void (^)(void))handler {
    DUIWindowRootViewController *viewController = (DUIWindowRootViewController *)self.rootViewController;
    viewController.viewDidFirstlyAppearHandler = handler;
}

+ (void)switchWindow {
    // Dayima window
    NSArray *windows = [UIApplication sharedApplication].windows;
    UIWindow *nextWindow;
    for (DUIWindow *window in windows) {
        if (![window isKindOfClass:[DUIWindow class]]) {
            continue;
        }

        if ((window.windowLevel >= nextWindow.windowLevel) && (window.hidden == NO) && (window.inhibitsKey == NO)) {
            nextWindow = window;
        }
    }

    if (nextWindow) {
        [nextWindow makeKeyWindow];
        nextWindow.hidden = NO;
    } else {
        [[UIApplication sharedApplication].windows[0] makeKeyWindow];
    }
}

+ (BOOL)isTopWindow:(DUIWindow *)window {
    // Dayima window
    NSArray *windows = [UIApplication sharedApplication].windows;
    if (![windows containsObject:window]) {
        return NO;
    }
    if (window.hidden) {
        return NO;
    }

    BOOL hasPassed = NO;
    for (UIWindow *each in windows) {
        if (each == window) {
            hasPassed = YES;
            continue;
        }

        if (![each isKindOfClass:[DUIWindow class]]) {
            continue;
        }

        if (each.hidden) {
            continue;
        }

        if (each.windowLevel > window.windowLevel) {
            return NO;
        }

        if (each.windowLevel < window.windowLevel) {
            continue;
        }

        if (hasPassed) {
            return NO;
        }
    }
    return YES;
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if (motion == UIEventSubtypeMotionShake) {
        [self shake];
    }
}

- (void)shake {
    [[NSNotificationCenter defaultCenter] postNotificationName:DUIWindowShakeNotification object:self];
}

@end
