//
//  DoraemonAddRecordCell.m
//  King
//
//  Created by sunzj on 2/5/16.
//  Copyright © 2016 sunzj. All rights reserved.
//

#import "DoraemonAddRecordCell.h"
#import "AvatarView.h"

@interface DoraemonAddRecordCell ()

@property (nonatomic, weak) UILabel *playerLabel;
@property (nonatomic, weak) UIImageView *jokerImageView;
@property (nonatomic, weak) AvatarView *avatarView;

@end

@implementation DoraemonAddRecordCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.separatorInset = UIEdgeInsetsZero;
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
            if ([self respondsToSelector:@selector(setLayoutMargins:)]) {
                self.layoutMargins = UIEdgeInsetsZero;
            }
        }

        UILabel *playerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.contentView.width, self.contentView.height)];
        playerLabel.font = [UIFont systemFontOfSize:12];
        playerLabel.textColor = [UIColor textColor];
        [self.contentView addSubview:playerLabel];
        self.playerLabel = playerLabel;

        AvatarView *avatarView = [[AvatarView alloc] initWithFrame:CGRectMake(0, 0, self.contentView.width, self.contentView.height)];
        [self.contentView addSubview:avatarView];
        self.avatarView = avatarView;

        UIImageView *jokerImageView = [[UIImageView alloc] initWithFrame:CGRectMake(150, 0, 30, self.contentView.height)];
        jokerImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        jokerImageView.contentMode = UIViewContentModeCenter;
        jokerImageView.image = [UIImage imageNamed:@"joker"];
        [self.contentView addSubview:jokerImageView];
        jokerImageView.hidden = YES;
        self.jokerImageView = jokerImageView;

        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap)];
        tap.cancelsTouchesInView = YES;
        [self.contentView addGestureRecognizer:tap];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    self.avatarView.frame = CGRectInset(self.contentView.bounds, 5, 5);
    self.avatarView.width = self.avatarView.height;
    self.playerLabel.frame = CGRectMake(self.avatarView.right + 5, 0, self.contentView.width - (self.avatarView.right + 5), self.contentView.height);
}

- (void)tap {
    if ([self.delegate respondsToSelector:@selector(doraemonAddRecordCellDidTap:)]) {
        [self.delegate doraemonAddRecordCellDidTap:self];
    }
}

- (void)setPlayerAvatarUrlString:(NSString *)avatarUrlString {
    [self.avatarView setAvatarUrlString:avatarUrlString];
}

- (void)setPlayerName:(NSString *)playerName {
    self.playerLabel.text = playerName;
}

- (void)setJoker:(BOOL)isJoker {
    self.jokerImageView.hidden = !isJoker;
}

+ (CGFloat)height {
    return 50;
}

@end
