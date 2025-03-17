//
//  DoraemonGameViewController.m
//  King
//
//  Created by sunzj on 16/2/6.
//  Copyright © 2016年 sunzj. All rights reserved.
//

#import "DoraemonGameViewController.h"
#import "DoraemonGameRecordCell.h"
#import "DoraemonAddRecordViewController.h"
#import "DoraemonGameManager.h"
#import "DoraemonPlayerManager.h"
#import <AVFoundation/AVFoundation.h>

@interface DoraemonGameViewController () <UITableViewDataSource, UITableViewDelegate, DoraemonAddRecordViewControllerDelegate>

@property (nonatomic) NSInteger gameId;
@property (nonatomic) DoraemonGame *game;

@property (nonatomic, copy) NSArray *playerLabels;
@property (nonatomic, weak) UIView *playerLabelsView;
@property (nonatomic, weak) DUITableView *tableView;
@property (nonatomic, weak) UIBarButtonItem *addRecordBarButtonItem;
@property (nonatomic) BOOL forbidEdit;
@property (nonatomic) NSMutableDictionary *showsScore;
@property (nonatomic) AVSpeechSynthesizer *speechSynthesizer;

@end

@implementation DoraemonGameViewController

- (instancetype)initWithGameId:(NSInteger)gameId {
    self = [super init];
    if (self) {
        _gameId = gameId;
        _game = [[DoraemonGameManager sharedInstance] gameForId:gameId];

    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    self.title = @"计分板";

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"计分" style:UIBarButtonItemStylePlain target:self action:@selector(gotoAddRecord)];
    self.addRecordBarButtonItem = self.navigationItem.rightBarButtonItem;
    self.view.backgroundColor = [UIColor backgroundColor];

    UIView *playerLabelsView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 44)];
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, playerLabelsView.height - 1 / [UIScreen mainScreen].scale, playerLabelsView.width, 1 / [UIScreen mainScreen].scale)];
    lineView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    lineView.backgroundColor = [UIColor grayColor];
    [playerLabelsView addSubview:lineView];

    [playerLabelsView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapPlayerLabelsView)]];

    NSMutableArray *playerLabels = [NSMutableArray array];
    NSArray *playerCurrentNames = self.game.playerCurrentNames;
    for (NSInteger i = 0; i < 5; i ++) {
        UILabel *playerLabel = [[UILabel alloc] init];
        playerLabel.textAlignment = NSTextAlignmentCenter;
        playerLabel.font = [UIFont boldSystemFontOfSize:12];
        playerLabel.textColor = [UIColor textColor];
        [playerLabelsView addSubview:playerLabel];
        [playerLabels addObject:playerLabel];
        playerLabel.text = playerCurrentNames[i];
    }
    self.playerLabels = playerLabels;
    playerLabelsView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:playerLabelsView];
    self.playerLabelsView = playerLabelsView;
    DUITableView *tableView = [[DUITableView alloc] initWithFrame:CGRectMake(0, playerLabelsView.bottom, self.view.width, self.view.height - playerLabelsView.bottom) style:UITableViewStylePlain];
    tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    tableView.dataSource = self;
    tableView.delegate = self;
    tableView.rowHeight = [DoraemonGameRecordCell height];
    tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:tableView];
    self.tableView = tableView;

    self.forbidEdit = (self.game.winnerIds.count > 0);
    [self refreshAddRecordBarButtonItemStatus];
    self.showsScore = [NSMutableDictionary dictionary];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    for (NSInteger i = 0; i < 5; i++) {
        UILabel *playerLabel = self.playerLabels[i];
        playerLabel.frame = CGRectMake(self.playerLabelsView.width / 5 * i, 0, self.playerLabelsView.width / 5, self.playerLabelsView.height);
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [self speak:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (AVSpeechSynthesizer *)speechSynthesizer {
    if (_speechSynthesizer == nil) {
        _speechSynthesizer = [[AVSpeechSynthesizer alloc] init];
    }

    return _speechSynthesizer;
}

- (void)tapPlayerLabelsView {
    [self speakRecordAtIndex:self.game.gameRecords.count - 1];
}

- (void)refreshAddRecordBarButtonItemStatus {
    self.addRecordBarButtonItem.enabled = (self.game.winnerIds.count == 0);
}

- (void)gotoAddRecord {
    DoraemonAddRecordViewController *vc = [[DoraemonAddRecordViewController alloc] init];
    vc.delegate = self;
    vc.playerIds = self.game.playerIds;
    vc.lastRecord = self.game.gameRecords.lastObject;
    DUINavigationController *nav = [[DUINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)gameDidChange {
    [self refreshAddRecordBarButtonItemStatus];
    [[DoraemonGameManager sharedInstance] setGame:self.game forId:self.gameId];
}

- (void)speakRecordAtIndex:(NSInteger)index {
    if (index < 0 || index >= self.game.gameRecords.count) {
        return;
    }

    NSMutableString *recordString = [NSMutableString string];
    NSArray *record = self.game.gameRecords[index];
    NSArray *playerCurrentNames = self.game.playerCurrentNames;
    for (NSInteger i = 0; i < 5; i++) {
        [recordString appendFormat:@"%@: %@分.\n", playerCurrentNames[i], record[i]];
    }
    [self speak:recordString];
}

- (void)speak:(NSString *)string {
    if (string.length == 0 || self.speechSynthesizer.isSpeaking) {
        [self.speechSynthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
        return;
    }

    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:string];

    AVSpeechSynthesisVoice *voiceType = [AVSpeechSynthesisVoice voiceWithLanguage:@"zh-CN"];
    utterance.voice = voiceType;
    utterance.rate *= 1.2;

    [self.speechSynthesizer speakUtterance:utterance];
}

- (void)doraemonAddRecordViewController:(DoraemonAddRecordViewController *)doraemonAddRecordViewController didAddRecord:(NSArray *)record {
    [doraemonAddRecordViewController dismissViewControllerAnimated:YES completion:^{
        NSArray *lastRecord = self.game.gameRecords.lastObject;
        NSMutableArray *newRecord = [NSMutableArray array];
        for (NSInteger i = 0; i < 5; i++) {
            NSNumber *lastScore = lastRecord[i];
            NSInteger newScore = lastScore.integerValue + [record[i] integerValue];
            [newRecord addObject:@(newScore)];
            if (newScore >= 1000) {
                self.game.winnerIds = [(self.game.winnerIds ?: @[]) arrayByAddingObject:self.game.playerIds[i]];
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"出呆！" message:[NSString stringWithFormat:@"呆子: %@", [self.game.winnerCurrentNames componentsJoinedByString:@", "]] delegate:nil cancelButtonTitle:@"恭喜" otherButtonTitles:nil];
                [alert show];
            }
        }
        self.game.gameRecords = [(self.game.gameRecords ?: @[]) arrayByAddingObject:newRecord.copy];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.game.gameRecords.count - 1 inSection:0];
        [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        self.game.endDate = [NSDate date];
        [self gameDidChange];

        [self speakRecordAtIndex:indexPath.row];
    }];
}

- (void)doraemonAddRecordViewControllerDidCancel:(DoraemonAddRecordViewController *)doraemonAddRecordViewController {
    [doraemonAddRecordViewController dismissViewControllerAnimated:YES completion:nil];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.game.gameRecords.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reuseIdentifier = @"DoraemonGameViewControllerTableViewCellReuseIdentifier";
    DoraemonGameRecordCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (cell == nil) {
        cell = [[DoraemonGameRecordCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
        cell.separatorInset = UIEdgeInsetsZero;
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
            if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
                cell.layoutMargins = UIEdgeInsetsZero;
            }
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }

    NSArray *gameRecord = self.game.gameRecords[indexPath.row];
    [cell setGameRecord:gameRecord];
    NSArray *previousGameRecord = nil;
    if (indexPath.row > 0) {
        previousGameRecord = self.game.gameRecords[indexPath.row - 1];
    }
    NSMutableArray *scores = [NSMutableArray array];
    for (NSInteger i = 0; i < 5; i ++) {
        [scores addObject:@([gameRecord[i] integerValue] - [previousGameRecord[i] integerValue])];
    }
    [cell setScores:scores.copy];
    cell.showsScores = [self.showsScore[@(indexPath.row)] boolValue];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    BOOL showsScore = [self.showsScore[@(indexPath.row)] boolValue];
    self.showsScore[@(indexPath.row)] = @(!showsScore);
    DoraemonGameRecordCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.showsScores = !showsScore;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    BOOL canEdit = ((self.game.gameRecords.count - 1 == indexPath.row) && !self.forbidEdit);
    return canEdit;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableArray *gameRecords = self.game.gameRecords.mutableCopy;
    [gameRecords removeLastObject];
    self.game.gameRecords = gameRecords;
    self.game.winnerIds = nil;
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    self.game.endDate = [NSDate date];
    [self gameDidChange];
    self.showsScore[@(indexPath.row)] = nil;
}

@end
