//
//  DoraemonGameListViewController.m
//  King
//
//  Created by sunzj on 2/5/16.
//  Copyright © 2016 sunzj. All rights reserved.
//

#import "DoraemonGameListViewController.h"
#import "DoraemonGameManager.h"
#import "DoraemonGameCell.h"
#import "DoraemonNewGameViewController.h"
#import "DoraemonGameViewController.h"
#import "DoraemonPlayerManager.h"

@interface DoraemonGameListViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) DUITableView *tableView;
@property (nonatomic) NSMutableArray *games;
@property (nonatomic) BOOL hasScrollToBottom;

@end

@implementation DoraemonGameListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    self.title = @"游戏";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"新建" style:UIBarButtonItemStylePlain target:self action:@selector(gotoNewGame)];

    DUITableView *tableView = [[DUITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    tableView.dataSource = self;
    tableView.delegate = self;
    tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:tableView];
    self.tableView = tableView;

    [self loadGames];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDoraemonGameRecordDidAddNotification:) name:DoraemonGameRecordDidAddNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDoraemonGameRecordDidRemoveNotification:) name:DoraemonGameRecordDidRemoveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDoraemonGameRecordDidChangeNotification:) name:DoraemonGameRecordDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDoraemonGameRecordsDidChangeNotification:) name:DoraemonGameRecordsDidChangeNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [[DoraemonGameManager sharedInstance] sync];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    if (self.hasScrollToBottom == NO) {
        if (self.games.count > 0) {
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.games.count - 1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
        }
        self.hasScrollToBottom = YES;
    }
}

- (void)handleDoraemonGameRecordDidAddNotification:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self reload];
    });
}

- (void)handleDoraemonGameRecordDidRemoveNotification:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self reload];
    });
}

- (void)handleDoraemonGameRecordDidChangeNotification:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self reload];
    });
}

- (void)handleDoraemonGameRecordsDidChangeNotification:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self reload];
    });
}

- (void)reload {
    [self loadGames];
    [self.tableView reloadData];
}

- (void)loadGames {
    NSArray *gameIds = [DoraemonGameManager sharedInstance].gameIds;
    self.games = gameIds.mutableCopy;
    [self.tableView reloadData];
}

- (void)gotoNewGame {
    DoraemonNewGameViewController *vc = [[DoraemonNewGameViewController alloc] init];
    DUINavigationController *nav = [[DUINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)longPress:(UILongPressGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state != UIGestureRecognizerStateBegan) {
        return;
    }

    UITableViewCell *cell = (UITableViewCell *)gestureRecognizer.view;
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    NSInteger gameId = [self.games[indexPath.row] integerValue];
    DoraemonGame *game = [[DoraemonGameManager sharedInstance] gameForId:gameId];
    DoraemonGame *newGame = [[DoraemonGame alloc] init];
    newGame.beginDate = [NSDate date];
    newGame.playerIds = game.playerIds;
    NSInteger newGameId = [[DoraemonGameManager sharedInstance] addGame:newGame];
    [self.games addObject:@(newGameId)];
    [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.games.count - 1 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.games.count - 1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}

- (NSString *)stringFromDate:(NSDate *)date {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *string = [dateFormatter stringFromDate:date];
    return string;
    
}

#pragma mark - UITableViewDataSource & UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.games.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger gameId = [self.games[indexPath.row] integerValue];
    DoraemonGame *game = [[DoraemonGameManager sharedInstance] gameForId:gameId];
    return game ? [DoraemonGameCell height] : 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reuseIdentifier = @"DoraemonListViewControllerTableViewCellReuseIdentifier";
    DoraemonGameCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (cell == nil) {
        cell = [[DoraemonGameCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
        cell.separatorInset = UIEdgeInsetsZero;
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
            if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
                cell.layoutMargins = UIEdgeInsetsZero;
            }
        }
        UILongPressGestureRecognizer *gr = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
        gr.cancelsTouchesInView = YES;
        gr.minimumPressDuration = 1;
        [cell addGestureRecognizer:gr];
    }

    NSInteger gameId = [self.games[indexPath.row] integerValue];
    DoraemonGame *game = [[DoraemonGameManager sharedInstance] gameForId:gameId];
    cell.playersLabel.text = [game.playerCurrentNames componentsJoinedByString:@", "];
    NSString *beginDateString = game.beginDate ? [self stringFromDate:game.beginDate] : @"";
    NSString *endDateString = game.endDate ? [self stringFromDate:game.endDate] : @"";
    cell.dateLabel.text = [NSString stringWithFormat:@"%@ -- %@", beginDateString, endDateString];
    cell.winnersLabel.text = [NSString stringWithFormat:@"呆子: %@", game.winnerIds.count > 0 ? [game.winnerCurrentNames componentsJoinedByString:@", "] : @"--"];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSInteger gameId = [self.games[indexPath.row] integerValue];
    DoraemonGameViewController *doraemonGameViewController = [[DoraemonGameViewController alloc] initWithGameId:gameId];
    [self.navigationController pushViewController:doraemonGameViewController animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger gameId = [self.games[indexPath.row] integerValue];
    DoraemonGame *game = [[DoraemonGameManager sharedInstance] gameForId:gameId];
    BOOL canEdit = (game.winnerIds.count == 0);
    return canEdit;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    [[DoraemonGameManager sharedInstance] removeGameId:[self.games[indexPath.row] integerValue]];
    [self.games removeObjectAtIndex:indexPath.row];
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

@end
