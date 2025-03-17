//
//  DoraemonPlayerCell.m
//  Doraemon
//
//  Created by sun on 16/10/26.
//  Copyright © 2016年 sunzj. All rights reserved.
//

#import "DoraemonPlayerCell.h"

@interface DoraemonPlayerCell ()

@end

@implementation DoraemonPlayerCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        AvatarView *avatarImageView = [[AvatarView alloc] init];
        [self.contentView addSubview:avatarImageView];
        _avatarImageView = avatarImageView;

        UILabel *nameLabel = [[UILabel alloc] init];
        [self.contentView addSubview:nameLabel];
        _nameLabel = nameLabel;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat avatarImageViewLength = self.contentView.height - 20;
    self.avatarImageView.frame = CGRectMake(10, 10, avatarImageViewLength, avatarImageViewLength);
    self.nameLabel.frame = CGRectMake(self.avatarImageView.right + 10, 0, self.contentView.width - (self.avatarImageView.right + 10) - 10, self.contentView.height);
}

+ (CGFloat)height {
    return 80;
}

@end
