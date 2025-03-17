//
//  DUINavigationController.m
//  Dayima
//
//  Created by sunzj on 14-6-11.
//
//

#import "DUINavigationController.h"
#import "UIImage+Color.h"
#import "MemoryContainer.h"

@interface DUINavigationController () <UIGestureRecognizerDelegate, UINavigationControllerDelegate>

@property (nonatomic, strong) id navigationBarAppearance;

@end

@implementation DUINavigationController

@synthesize objectIdentifier;

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        LOG_MEMORY;

        [self commonInit];
    }
    return self;
}

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController
{
    self = [super initWithRootViewController:rootViewController];
    if (self) {
        // Custom initialization
        LOG_MEMORY;

        [self commonInit];
    }
    return self;

}

- (void)commonInit
{
    self.modalPresentationStyle = UIModalPresentationFullScreen;

    self.navigationBar.translucent = NO;
    self.navigationBar.barStyle = UIBarStyleDefault;
    self.navigationBar.tintColor = [UIColor textColor];

    if (@available(iOS 15.0, *)) {
        UINavigationBarAppearance *navigationBarAppearance = [[UINavigationBarAppearance alloc] init];
        [navigationBarAppearance configureWithDefaultBackground];
        self.navigationBarAppearance = navigationBarAppearance;
    }

    [self refreshBarBackgroundImage];
}

- (void)refreshBarBackgroundImage
{
    UIImage *backgroundImage = [[UIImage imageNamed:@"navBar"] resizableImageWithCapInsets:UIEdgeInsetsZero resizingMode:UIImageResizingModeStretch];
    [self.navigationBar setBackgroundImage:backgroundImage forBarMetrics:UIBarMetricsDefault];
    if (@available(iOS 15.0, *)) {
        UINavigationBarAppearance *navigationBarAppearance = self.navigationBarAppearance;
        navigationBarAppearance.backgroundImage = backgroundImage;
        self.navigationBar.standardAppearance = navigationBarAppearance;
        self.navigationBar.scrollEdgeAppearance = navigationBarAppearance;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Do any additional setup after loading the view.

    NSLog(@"viewDidLoad: %@(%p)", NSStringFromClass(self.class), self);
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    // Do any additional setup after loading the view.

    NSLog(@"viewDidLayoutSubviews: %@(%p)", NSStringFromClass(self.class), self);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    NSLog(@"viewWillAppear: %@(%p)", NSStringFromClass(self.class), self);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    NSLog(@"viewDidAppear: %@(%p)", NSStringFromClass(self.class), self);
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    NSLog(@"viewWillDisappear: %@(%p)", NSStringFromClass(self.class), self);
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    NSLog(@"viewDidDisappear: %@(%p)", NSStringFromClass(self.class), self);
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];

    [self refreshBarBackgroundImage];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];

    NSLog(@"didReceiveMemoryWarning: %@(%p)", NSStringFromClass(self.class), self);
}

- (BOOL)shouldAutorotate {
//    NSLog(@"shouldAutorotate: %@(%p)", NSStringFromClass(self.class), self);
    BOOL shouldAutorotate = [self.topViewController shouldAutorotate];
//    NSLog(@"return: %@", @(shouldAutorotate));
    return shouldAutorotate;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
//    NSLog(@"supportedInterfaceOrientations: %@(%p)", NSStringFromClass(self.class), self);
    NSUInteger orientations = [self.topViewController supportedInterfaceOrientations];
//    NSLog(@"return: %@", @(orientations));
    return orientations;
}

- (NSString *)description {
    NSString *description = [NSString stringWithFormat:@"%@, view controllers count = %@, id = %@", [super description], @(self.viewControllers.count), self.objectIdentifier ?: @""];
    return description;
}

@end
