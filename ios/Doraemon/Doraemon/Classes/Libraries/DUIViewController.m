//
//  DUIViewController.m
//  Dayima
//
//  Created by sunzj on 14-9-2.
//
//

#import "DUIViewController.h"
#import "MemoryContainer.h"

@interface DUIViewController ()

@end

@implementation DUIViewController

@synthesize objectIdentifier;

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    NSLog(@"viewWillAppear: %@(%p)", NSStringFromClass(self.class), self);
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    NSLog(@"viewDidAppear: %@(%p)", NSStringFromClass(self.class), self);
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    NSLog(@"viewWillDisappear: %@(%p)", NSStringFromClass(self.class), self);
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];

    NSLog(@"viewDidDisappear: %@(%p)", NSStringFromClass(self.class), self);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

    NSLog(@"didReceiveMemoryWarning: %@(%p)", NSStringFromClass(self.class), self);
}

- (NSString *)description {
    NSString *description = [NSString stringWithFormat:@"%@, id = %@", [super description], self.objectIdentifier ?: @""];
    return description;
}

@end
