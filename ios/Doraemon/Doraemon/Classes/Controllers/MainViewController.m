//
//  MainViewController.m
//  King
//
//  Created by sunzj on 2/5/16.
//  Copyright © 2016 sunzj. All rights reserved.
//

#import "MainViewController.h"
#import "DoraemonGameListViewController.h"
#import "DoraemonPlayerListViewController.h"

@interface MainViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) DUITableView *tableView;

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    self.title = @"哆啦A梦";

    DUITableView *tableView = [[DUITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    tableView.dataSource = self;
    tableView.delegate = self;
    tableView.rowHeight = 60;
    tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:tableView];
    self.tableView = tableView;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reuseIdentifier = @"MainViewControllerTableViewCellReuseIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
        cell.separatorInset = UIEdgeInsetsZero;
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
            if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
                cell.layoutMargins = UIEdgeInsetsZero;
            }
        }
    }

    NSString *title = @"";
    switch (indexPath.row) {
        case 0:
            title = @"游戏";
            break;
        case 1:
            title = @"玩家";
        default:
            break;
    }

    cell.textLabel.text = title;

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    switch (indexPath.row) {
        case 0:
            [self gotoDoraemonGameList];
            break;
        case 1:
            [self gotoDoraemonPlayerList];
            break;

        default:
            break;
    }
}

- (void)gotoDoraemonGameList {
    DoraemonGameListViewController *vc = [[DoraemonGameListViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)gotoDoraemonPlayerList {
    DoraemonPlayerListViewController *vc = [[DoraemonPlayerListViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

@end

