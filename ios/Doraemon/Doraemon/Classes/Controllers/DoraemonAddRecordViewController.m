//
//  DoraemonAddRecordViewController.m
//  King
//
//  Created by sunzj on 16/2/6.
//  Copyright © 2016年 sunzj. All rights reserved.
//

#import "DoraemonAddRecordViewController.h"
#import "DoraemonAddRecordCell.h"
#import "UIImage+Color.h"
#import "iToast.h"
#import "DoraemonPlayerManager.h"

@interface DoraemonAddRecordViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIAlertViewDelegate, DoraemonAddRecordCellDelegate>

@property (nonatomic, weak) DUITableView *tableView;
@property (nonatomic, weak) UITextField *scoreTextField;
@property (nonatomic, weak) UISwitch *announcementSwitch;

@property (nonatomic, copy) NSArray *dataSource;
@property (nonatomic) NSMutableArray *finishedPlayers;
@property (nonatomic) NSMutableArray *notFinishedPlayers;
@property (nonatomic) NSMutableArray *kingPlayers;
@property (nonatomic, copy) NSArray *playerIndexes;
@property (nonatomic, copy) NSDictionary *playerId;
@property (nonatomic) UIButton *minusButton;

@property (nonatomic, copy) NSArray *record;

@end

@implementation DoraemonAddRecordViewController

- (void)dealloc {
    [_minusButton removeFromSuperview];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    self.title = @"得分";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(cancel)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"确定" style:UIBarButtonItemStylePlain target:self action:@selector(confirm)];
    self.view.backgroundColor = [UIColor whiteColor];

    DUITableView *tableView = [[DUITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    tableView.dataSource = self;
    tableView.delegate = self;
    tableView.rowHeight = [DoraemonAddRecordCell height];
    [tableView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap)]];

    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.width, 40)];
    headerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 80, headerView.height)];
    label.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    [headerView addSubview:label];
    label.text = @"大王得分";

    UITextField *scoreTextField = [[UITextField alloc] initWithFrame:CGRectMake(100, 0, headerView.width - 220, headerView.height)];
    scoreTextField.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    scoreTextField.borderStyle = UITextBorderStyleRoundedRect;
    scoreTextField.delegate = self;
    scoreTextField.keyboardType = UIKeyboardTypeNumberPad;
    scoreTextField.textAlignment = NSTextAlignmentCenter;
    [headerView addSubview:scoreTextField];
    self.scoreTextField = scoreTextField;

    UISwitch *announcementSwitch = [[UISwitch alloc] init];
    announcementSwitch.frame = CGRectMake(headerView.width - 110, (headerView.height - announcementSwitch.height) / 2, 100, headerView.height);
    [announcementSwitch addTarget:self action:@selector(announcementSwitchValueChanged) forControlEvents:UIControlEventValueChanged];
    [headerView addSubview:announcementSwitch];
    self.announcementSwitch = announcementSwitch;

    tableView.tableHeaderView = headerView;
    tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:tableView];
    self.tableView = tableView;

    tableView.editing = YES;
    tableView.scrollEnabled = NO;

    NSMutableArray *playerIndexes = [NSMutableArray array];
    NSMutableDictionary *playerId = [NSMutableDictionary dictionary];
    for (NSInteger i = 0; i < 5; i++) {
        [playerIndexes addObject:@(i)];
        playerId[@(i)] = self.playerIds[i];
    }
    self.playerIndexes = playerIndexes;
    self.playerId = playerId;

    self.kingPlayers = [NSMutableArray array];
    self.finishedPlayers = [NSMutableArray array];
    self.notFinishedPlayers = self.playerIndexes.mutableCopy;
    self.dataSource = @[self.finishedPlayers, self.notFinishedPlayers];
    [self.tableView reloadData];

    UIButton *minusButton = [[UIButton alloc] init];
    [minusButton addTarget:self action:@selector(minusButtonDidTouchUpInside) forControlEvents:UIControlEventTouchUpInside];
    self.minusButton = minusButton;
    [minusButton setTitle:@"-" forState:UIControlStateNormal];
    [minusButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    minusButton.titleLabel.font = [UIFont systemFontOfSize:30];
    self.minusButton.backgroundColor = [UIColor clearColor];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];

    [self.scoreTextField resignFirstResponder];
    [self.minusButton removeFromSuperview];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)keyboardDidShow:(NSNotification *)notification {
    UIWindow *window = [UIApplication sharedApplication].windows.lastObject;
    NSValue *rectValue = notification.userInfo[UIKeyboardFrameEndUserInfoKey];
    CGRect frame = rectValue.CGRectValue;
    self.minusButton.width = frame.size.width / 3;
    self.minusButton.height = frame.size.height / 4;
    self.minusButton.left = 0;
    self.minusButton.bottom = window.height;
    [window addSubview:self.minusButton];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    [self.minusButton removeFromSuperview];
}

- (void)minusButtonDidTouchUpInside {
    if (self.scoreTextField.text.length == 0 || [self.scoreTextField.text rangeOfString:@"-"].location == NSNotFound) {
        self.scoreTextField.text = [@"-" stringByAppendingString:self.scoreTextField.text ?: @""];
    } else {
        self.scoreTextField.text = [self.scoreTextField.text stringByReplacingOccurrencesOfString:@"-" withString:@""];
    }
}

- (void)confirm {
    NSString *scoreString = self.scoreTextField.text;
    if (scoreString.length == 0) {
        [[[iToast makeText:@"分数为空"] setDuration:1000] show];
        return;
    }
    NSInteger score = scoreString.integerValue;
    if (score > 240 || score < -40) {
        [[[iToast makeText:@"分数越界"] setDuration:1000] show];
        return;
    }
    if (score % 5 != 0) {
        [[[iToast makeText:@"分数错误"] setDuration:1000] show];
        return;
    }
    if (self.kingPlayers.count == 0) {
        [[[iToast makeText:@"队伍错误"] setDuration:1000] show];
        return;
    }

    NSMutableDictionary *lastRecord = [NSMutableDictionary dictionary];
    for (NSInteger i = 0; i < 5; i++) {
        lastRecord[self.playerIndexes[i]] = self.lastRecord[i];
    }
    NSMutableDictionary *scores = [NSMutableDictionary dictionary];

    NSInteger kingsScore = score;
    if (self.announcementSwitch.on) {
        kingsScore *= 2;
    }

    NSArray *kings = [self sortedPlayersWithPlayers:self.kingPlayers.copy finishedPlayers:self.finishedPlayers lastRecord:lastRecord.copy];
    NSArray *kingScores = [self dividedScoresWithScore:kingsScore count:self.kingPlayers.count];
    for (NSInteger i = 0; i < kings.count; i++) {
        scores[kings[i]] = kingScores[i];
    }

    NSMutableArray *nonKingPlayers = self.playerIndexes.mutableCopy;
    [nonKingPlayers removeObjectsInArray:self.kingPlayers];
    NSInteger nonKingsScore = 200 - score;
    NSArray *nonKings = [self sortedPlayersWithPlayers:nonKingPlayers.copy finishedPlayers:self.finishedPlayers lastRecord:lastRecord.copy];
    NSArray *nonKingScores = [self dividedScoresWithScore:nonKingsScore count:nonKingPlayers.count];
    for (NSInteger i = 0; i < nonKings.count; i++) {
        scores[nonKings[i]] = nonKingScores[i];
    }

    NSMutableArray *messages = [NSMutableArray array];
    NSMutableArray *record = [NSMutableArray array];
    for (NSInteger i = 0; i < 5; i++) {
        NSNumber *playerIndex = self.playerIndexes[i];
        NSString *playerName = [self playerCurrentNameOfIndex:playerIndex];
        NSNumber *score = scores[playerIndex];
        [messages addObject:[NSString stringWithFormat:@"%@:%@", playerName, score]];
        [record addObject:score];
    }
    self.record = record;
    NSString *message = [messages componentsJoinedByString:@"\n"];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"得分" message:message delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
    [alertView show];
}

- (NSString *)playerCurrentNameOfIndex:(NSNumber *)playerIndex {
    DoraemonPlayer *player = [[DoraemonPlayerManager sharedInstance] playerForId:[self.playerId[playerIndex] integerValue]];
    return player.currentName;
}

- (NSArray *)dividedScoresWithScore:(NSInteger)score count:(NSInteger)count {
    NSInteger s = score;
    BOOL isNegative = NO;
    if (score < 0) {
        s = -score;
        isNegative = YES;
    }
    NSInteger a = s / 5;
    NSInteger b = a / count;
    NSInteger c = a % count;
    NSInteger d = b * 5;
    NSMutableArray *array = [NSMutableArray array];
    for (NSInteger i = 0, j = c; i < count; i++) {
        NSInteger k = d;
        if (j > 0) {
            k += 5;
            j--;
        }

        if (isNegative) {
            [array insertObject:@(-k) atIndex:0];
        } else {
            [array addObject:@(k)];
        }
    }
    return array.copy;
}

- (NSArray *)sortedPlayersWithPlayers:(NSArray *)players finishedPlayers:(NSArray *)finishedPlayers lastRecord:(NSDictionary *)lastRecord {
    NSArray *sortedPlayers = [players sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSString *player1 = obj1;
        NSString *player2 = obj2;
        NSInteger finishedIndex1 = [finishedPlayers indexOfObject:player1];
        NSInteger finishedIndex2 = [finishedPlayers indexOfObject:player2];
        if (finishedIndex1 > finishedIndex2) {
            return NSOrderedDescending;
        }
        if (finishedIndex1 < finishedIndex2) {
            return NSOrderedAscending;
        }
        NSInteger lastScore1 = [lastRecord[player1] integerValue];
        NSInteger lastScore2 = [lastRecord[player2] integerValue];
        if (lastScore1 > lastScore2) {
            return NSOrderedDescending;
        }
        if (lastScore1 < lastScore2) {
            return NSOrderedAscending;
        }
        NSInteger index1 = [players indexOfObject:player1];
        NSInteger index2 = [players indexOfObject:player2];
        if (index1 > index2) {
            return NSOrderedDescending;
        }
        if (index1 < index2) {
            return NSOrderedAscending;
        }
        return NSOrderedSame;
    }];
    return sortedPlayers;
}

- (void)cancel {
    if ([self.delegate respondsToSelector:@selector(doraemonAddRecordViewControllerDidCancel:)]) {
        [self.delegate doraemonAddRecordViewControllerDidCancel:self];
    }
}

- (void)announcementSwitchValueChanged {
    [self.scoreTextField resignFirstResponder];
}

- (void)tap {
    [self.scoreTextField resignFirstResponder];
}

- (void)doraemonAddRecordCellDidTap:(DoraemonAddRecordCell *)doraemonAddRecordCell {
    [self.scoreTextField resignFirstResponder];

    NSIndexPath *indexPath = [self.tableView indexPathForCell:doraemonAddRecordCell];
    NSString *player = self.dataSource[indexPath.section][indexPath.row];
    if ([self.kingPlayers containsObject:player]) {
        [self.kingPlayers removeObject:player];
    } else {
        if (self.kingPlayers.count >= 2) {
            return;
        }
        [self.kingPlayers addObject:player];
    }
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.dataSource[section] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"已出完牌玩家";
    } else {
        return @"未出完牌玩家";
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reuseIdentifier = @"DoraemonAddRecordViewControllerTableViewCellReuseIdentifier";
    DoraemonAddRecordCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (cell == nil) {
        cell = [[DoraemonAddRecordCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
        cell.delegate = self;
    }

    NSNumber *playerIndex = self.dataSource[indexPath.section][indexPath.row];
    DoraemonPlayer *player = [[DoraemonPlayerManager sharedInstance] playerForId:[self.playerId[playerIndex] integerValue]];
    [cell setPlayerAvatarUrlString:player.avatarUrlString];
    [cell setPlayerName:player.currentName];
    [cell setJoker:[self.kingPlayers containsObject:playerIndex]];

    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    BOOL canEdit = YES;
    return canEdit;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    if ((sourceIndexPath.section == destinationIndexPath.section) && (sourceIndexPath.row == destinationIndexPath.row)) {
        return;
    }
    NSString *player = self.dataSource[sourceIndexPath.section][sourceIndexPath.row];
    [self.dataSource[sourceIndexPath.section] removeObjectAtIndex:sourceIndexPath.row];
    [self.dataSource[destinationIndexPath.section] insertObject:player atIndex:destinationIndexPath.row];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex != 0) {
        if ([self.delegate respondsToSelector:@selector(doraemonAddRecordViewController:didAddRecord:)]) {
            [self.delegate doraemonAddRecordViewController:self didAddRecord:self.record];
        }
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

@end
