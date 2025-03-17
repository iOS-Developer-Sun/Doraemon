//
//  DoraemonGameCell.m
//  King
//
//  Created by sunzj on 2/5/16.
//  Copyright © 2016 sunzj. All rights reserved.
//

#import "DoraemonGameCell.h"

@interface DoraemonGameCell ()

@end

@implementation DoraemonGameCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        UILabel *playersLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, self.contentView.width - 10, 25)];
        playersLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self.contentView addSubview:playersLabel];
        self.playersLabel = playersLabel;

        UILabel *dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 35, self.contentView.width - 10, 20)];
        dateLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        dateLabel.font = [UIFont systemFontOfSize:10];
        [self.contentView addSubview:dateLabel];
        self.dateLabel = dateLabel;

        UILabel *winnersLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 55, self.contentView.width - 10, 15)];
        winnersLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        winnersLabel.font = [UIFont systemFontOfSize:10];
        [self.contentView addSubview:winnersLabel];
        self.winnersLabel = winnersLabel;
    }
    return self;
}

+ (CGFloat)height {
    return 80;
}

@end
