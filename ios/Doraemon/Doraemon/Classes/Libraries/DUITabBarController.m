//
//  DUITabBarController.m
//  Dayima
//
//  Created by sunzj on 15/8/7.
//
//

#import "DUITabBarController.h"
#import "MemoryContainer.h"

@interface DUITabBarController ()

@end

@implementation DUITabBarController

@synthesize objectIdentifier;

- (instancetype)init {
    self = [super init];
    if (self) {
        LOG_MEMORY;
    }
    return self;
}

- (void)viewDidLoad {
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];

    NSLog(@"didReceiveMemoryWarning: %@(%p)", NSStringFromClass(self.class), self);
}

- (BOOL)shouldAutorotate {
//    NSLog(@"shouldAutorotate: %@(%p)", NSStringFromClass(self.class), self);
    BOOL shouldAutorotate = [self.selectedViewController shouldAutorotate];
//    NSLog(@"return: %@", @(shouldAutorotate));
    return shouldAutorotate;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
//    NSLog(@"supportedInterfaceOrientations: %@(%p)", NSStringFromClass(self.class), self);
    NSUInteger orientations = [self.selectedViewController supportedInterfaceOrientations];
//    NSLog(@"return: %@", @(orientations));
    return orientations;
}

- (NSString *)description {
    NSString *description = [NSString stringWithFormat:@"%@, view controllers count = %@, id = %@", [super description], @(self.viewControllers.count), self.objectIdentifier ?: @""];
    return description;
}

@end
