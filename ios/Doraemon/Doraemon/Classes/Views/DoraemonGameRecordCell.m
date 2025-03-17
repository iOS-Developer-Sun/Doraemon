//
//  DoraemonGameRecordCell.m
//  King
//
//  Created by sunzj on 2/5/16.
//  Copyright © 2016 sunzj. All rights reserved.
//

#import "DoraemonGameRecordCell.h"

@interface DoraemonGameRecordCell ()

@property (nonatomic, copy) NSArray *labels;
@property (nonatomic, copy) NSArray *scoreLabels;

@end

@implementation DoraemonGameRecordCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        NSMutableArray *labels = [NSMutableArray array];
        for (NSInteger i = 0; i < 5; i++) {
            UILabel *label = [[UILabel alloc] init];
            label.textAlignment = NSTextAlignmentCenter;
            label.font = [UIFont systemFontOfSize:12];
            label.textColor = [UIColor textColor];
            [labels addObject:label];
            [self.contentView addSubview:label];
        }
        _labels = labels.copy;
        NSMutableArray *scoreLabels = [NSMutableArray array];
        for (NSInteger i = 0; i < 5; i++) {
            UILabel *label = [[UILabel alloc] init];
            label.textAlignment = NSTextAlignmentCenter;
            label.font = [UIFont systemFontOfSize:9];
            label.textColor = [UIColor grayColor];
            [scoreLabels addObject:label];
            [self.contentView addSubview:label];
        }
        _scoreLabels = scoreLabels.copy;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat height = self.contentView.height - 2;
    CGFloat alpha = 0;
    if (self.showsScores) {
        height = height / 2;
        alpha = 1;
    }

    for (NSInteger i = 0; i < 5; i++) {
        UILabel *label = self.labels[i];
        label.frame = CGRectMake(self.contentView.width / 5 * i, self.contentView.height - height, self.contentView.width / 5, height);
    }
    for (NSInteger i = 0; i < 5; i++) {
        UILabel *label = self.scoreLabels[i];
        label.frame = CGRectMake(self.contentView.width / 5 * i, 0, self.contentView.width / 5, height);
        label.alpha = alpha;
    }
}

- (void)setShowsScores:(BOOL)showsScores {
    if (showsScores == _showsScores) {
        return;
    }
    _showsScores = showsScores;
    [UIView animateWithDuration:0.3 animations:^{
        [self setNeedsLayout];
        [self layoutIfNeeded];
    } completion:^(BOOL finished) {
        ;
    }];
}

- (void)setScores:(NSArray *)scores {
    for (NSInteger i = 0; i < 5; i++) {
        UILabel *label = self.scoreLabels[i];
        label.text = [scores[i] stringValue];
    }
    [self setNeedsLayout];
}

- (void)setGameRecord:(NSArray *)gameRecord {
    for (NSInteger i = 0; i < 5; i++) {
        UILabel *label = self.labels[i];
        label.text = [gameRecord[i] stringValue];
    }
    [self setNeedsLayout];
}

+ (CGFloat)height {
    return 44;
}

@end
