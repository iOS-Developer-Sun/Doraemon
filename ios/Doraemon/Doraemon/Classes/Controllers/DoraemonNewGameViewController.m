//
//  DoraemonNewGameViewController.m
//  King
//
//  Created by sunzj on 16/2/6.
//  Copyright © 2016年 sunzj. All rights reserved.
//

#import "DoraemonNewGameViewController.h"
#import "DoraemonGameManager.h"
#import "iToast.h"
#import "DoraemonPlayerManager.h"
#import "DoraemonAddRecordCell.h"

@interface DoraemonNewGameViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, DoraemonAddRecordCellDelegate>

@property (nonatomic, weak) DUITableView *tableView;
@property (nonatomic, copy) NSArray *playerLists;

@end

@implementation DoraemonNewGameViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    self.title = @"新游戏";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(cancel)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"确定" style:UIBarButtonItemStylePlain target:self action:@selector(confirm)];
    self.view.backgroundColor = [UIColor whiteColor];

    DUITableView *tableView = [[DUITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    tableView.dataSource = self;
    tableView.delegate = self;
    tableView.rowHeight = 50;
    tableView.editing = YES;
    tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:tableView];
    self.tableView = tableView;

    NSMutableArray *playersToPlay = [NSMutableArray array];
    NSMutableArray *playersNotToPlay = [[DoraemonPlayerManager sharedInstance] playerIds].mutableCopy;
    self.playerLists = @[playersToPlay, playersNotToPlay];
    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)keyboardDidShow:(NSNotification *)notification {
    CGRect keyRect= [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat height = keyRect.size.height;
    self.tableView.height = self.view.height - height;
}

- (void)keyboardWillHide:(NSNotification *)notification {
    self.tableView.frame = self.tableView.superview.bounds;
}

- (void)confirm {
    NSArray *playerIds = self.playerLists[0];
    if (playerIds.count != 5) {
        [[[iToast makeText:@"玩家数量不足"] setDuration:1000] show];
        return;
    }
    DoraemonGame *game = [[DoraemonGame alloc] init];
    game.beginDate = [NSDate date];
    game.playerIds = playerIds;
    [[DoraemonGameManager sharedInstance] addGame:game];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)cancel {
    [self.view endEditing:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)doraemonAddRecordCellDidTap:(DoraemonAddRecordCell *)doraemonAddRecordCell {
    NSIndexPath *sourceIndexPath = [self.tableView indexPathForCell:doraemonAddRecordCell];
    NSIndexPath *destinationIndexPath = [NSIndexPath indexPathForRow:0 inSection:((sourceIndexPath.section == 0) ? 1 : 0)];
    if ((destinationIndexPath.section == 0) && ([self.playerLists[destinationIndexPath.section] count] >= 5)) {
        return;
    }
    NSNumber *playerId = self.playerLists[sourceIndexPath.section][sourceIndexPath.row];
    [self.playerLists[sourceIndexPath.section] removeObjectAtIndex:sourceIndexPath.row];
    [self.playerLists[destinationIndexPath.section] insertObject:playerId atIndex:destinationIndexPath.row];
    [self.tableView moveRowAtIndexPath:sourceIndexPath toIndexPath:destinationIndexPath];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.playerLists.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger number = [self.playerLists[section] count];
    return number;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"已选玩家";
    } else {
        return @"待选玩家";
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reuseIdentifier = @"DoraemonNewGameViewControllerTableViewCellReuseIdentifier";
    DoraemonAddRecordCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (cell == nil) {
        cell = [[DoraemonAddRecordCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    }

    NSNumber *playerIndex = self.playerLists[indexPath.section][indexPath.row];
    DoraemonPlayer *player = [[DoraemonPlayerManager sharedInstance] playerForId:playerIndex.integerValue];
    [cell setPlayerAvatarUrlString:player.avatarUrlString];
    [cell setPlayerName:player.currentName];
    [cell setJoker:NO];
    cell.delegate = self;

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSInteger destinationSection = (indexPath.section == 0) ? 1 : 0;
    NSIndexPath *destinationIndexPath = [NSIndexPath indexPathForRow:0 inSection:destinationSection];
    NSNumber *playerId = self.playerLists[indexPath.section][indexPath.row];
    [self.playerLists[indexPath.section] removeObjectAtIndex:indexPath.row];
    [self.playerLists[destinationIndexPath.section] insertObject:playerId atIndex:destinationIndexPath.row];
    [tableView moveRowAtIndexPath:indexPath toIndexPath:destinationIndexPath];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    BOOL canEdit = YES;
    return canEdit;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    if ((sourceIndexPath.section == destinationIndexPath.section) && (sourceIndexPath.row == destinationIndexPath.row)) {
        return;
    }
    NSNumber *playerId = self.playerLists[sourceIndexPath.section][sourceIndexPath.row];
    [self.playerLists[sourceIndexPath.section] removeObjectAtIndex:sourceIndexPath.row];
    [self.playerLists[destinationIndexPath.section] insertObject:playerId atIndex:destinationIndexPath.row];
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
    if ((sourceIndexPath.section != 0) && (proposedDestinationIndexPath.section == 0) && ([self.playerLists[0] count] >= 5)) {
        return sourceIndexPath;
    }
    return proposedDestinationIndexPath;
}

@end
