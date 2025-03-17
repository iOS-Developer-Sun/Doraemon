//
//  DoraemonPlayerCell.h
//  Doraemon
//
//  Created by sun on 16/10/26.
//  Copyright © 2016年 sunzj. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AvatarView.h"

@interface DoraemonPlayerCell : UITableViewCell

@property (nonatomic, weak) UILabel *nameLabel;
@property (nonatomic, weak) AvatarView *avatarImageView;

+ (CGFloat)height;

@end
