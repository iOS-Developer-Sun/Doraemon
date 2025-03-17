//
//  DoraemonPlayerListViewController.m
//  Doraemon
//
//  Created by sun on 16/10/26.
//  Copyright © 2016年 sunzj. All rights reserved.
//

#import "DoraemonPlayerListViewController.h"
#import "DoraemonPlayerManager.h"
#import "DoraemonPlayerCell.h"
#import "DoraemonPlayerViewController.h"
#import "DoraemonGameManager.h"

@interface DoraemonPlayerListViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) DUITableView *tableView;
@property (nonatomic) NSMutableArray *playerIds;

@end

@implementation DoraemonPlayerListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    self.title = @"玩家";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"新建" style:UIBarButtonItemStylePlain target:self action:@selector(gotoNewPlayer)];

    DUITableView *tableView = [[DUITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    tableView.dataSource = self;
    tableView.delegate = self;
    tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:tableView];
    self.tableView = tableView;

    [self loadPlayers];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDoraemonPlayerDidAddNotification:) name:DoraemonPlayerDidAddNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDoraemonPlayerDidRemoveNotification:) name:DoraemonPlayerDidRemoveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDoraemonPlayerDidChangeNotification:) name:DoraemonPlayerDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDoraemonPlayersDidChangeNotification:) name:DoraemonPlayersDidChangeNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [[DoraemonPlayerManager sharedInstance] sync];
}

- (void)handleDoraemonPlayerDidAddNotification:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self reload];
    });
}

- (void)handleDoraemonPlayerDidRemoveNotification:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self reload];
    });
}

- (void)handleDoraemonPlayerDidChangeNotification:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self reload];
    });
}

- (void)handleDoraemonPlayersDidChangeNotification:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self reload];
    });
}

- (void)reload {
    [self loadPlayers];
    [self.tableView reloadData];
}

- (void)loadPlayers {
    NSArray *playerIds = [DoraemonPlayerManager sharedInstance].playerIds;
    self.playerIds = playerIds.mutableCopy;
    [self.tableView reloadData];
}

- (void)removePlayerAtIndex:(NSInteger)index {
    [[DoraemonPlayerManager sharedInstance] removePlayerId:[self.playerIds[index] integerValue]];
    [self.playerIds removeObjectAtIndex:index];
}

- (void)gotoNewPlayer {
    DoraemonPlayerViewController *vc = [[DoraemonPlayerViewController alloc] init];
    DUINavigationController *nav = [[DUINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:nav animated:YES completion:nil];
}

#pragma mark - UITableViewDataSource & UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.playerIds.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger playerId = [self.playerIds[indexPath.row] integerValue];
    DoraemonPlayer *player = [[DoraemonPlayerManager sharedInstance] playerForId:playerId];
    return player ? [DoraemonPlayerCell height] : 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reuseIdentifier = @"DoraemonListViewControllerTableViewCellReuseIdentifier";
    DoraemonPlayerCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (cell == nil) {
        cell = [[DoraemonPlayerCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
        cell.separatorInset = UIEdgeInsetsZero;
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
            if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
                cell.layoutMargins = UIEdgeInsetsZero;
            }
        }
    }

    NSInteger playerId = [self.playerIds[indexPath.row] integerValue];
    DoraemonPlayer *player = [[DoraemonPlayerManager sharedInstance] playerForId:playerId];
    cell.nameLabel.text = player.name;
    [cell.avatarImageView setAvatarUrlString:player.avatarUrlString];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSInteger playerId = [self.playerIds[indexPath.row] integerValue];
    DoraemonPlayerViewController *doraemonPlayerViewController = [[DoraemonPlayerViewController alloc] initWithPlayerId:playerId];
    DUINavigationController *nav = [[DUINavigationController alloc] initWithRootViewController:doraemonPlayerViewController];
    [self presentViewController:nav animated:YES completion:nil];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    BOOL canEdit = YES;
    return canEdit;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger playerId = [self.playerIds[indexPath.row] integerValue];
    NSArray *gameIds = [[DoraemonGameManager sharedInstance] gameIds];
    for (NSNumber *gameId in gameIds) {
        DoraemonGame *game = [[DoraemonGameManager sharedInstance] gameForId:gameId.integerValue];
        for (NSNumber *playerIdNumber in game.playerIds) {
            if (playerIdNumber.integerValue == playerId) {
                return @"编辑";
            }
        }
    }
    return @"删除";
}


- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger playerId = [self.playerIds[indexPath.row] integerValue];
    NSArray *gameIds = [[DoraemonGameManager sharedInstance] gameIds];
    for (NSNumber *gameId in gameIds) {
        DoraemonGame *game = [[DoraemonGameManager sharedInstance] gameForId:gameId.integerValue];
        for (NSNumber *playerIdNumber in game.playerIds) {
            if (playerIdNumber.integerValue == playerId) {
                [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                NSInteger playerId = [self.playerIds[indexPath.row] integerValue];
                DoraemonPlayerViewController *doraemonPlayerViewController = [[DoraemonPlayerViewController alloc] initWithPlayerId:playerId];
                DUINavigationController *nav = [[DUINavigationController alloc] initWithRootViewController:doraemonPlayerViewController];
                [self presentViewController:nav animated:YES completion:nil];
                return;
            }
        }
    }
    [self removePlayerAtIndex:indexPath.row];
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

@end
