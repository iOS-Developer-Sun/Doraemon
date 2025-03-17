//
//  DoraemonGameCell.h
//  King
//
//  Created by sunzj on 2/5/16.
//  Copyright © 2016 sunzj. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DoraemonGameCell : UITableViewCell

@property (nonatomic, weak) UILabel *playersLabel;
@property (nonatomic, weak) UILabel *dateLabel;
@property (nonatomic, weak) UILabel *winnersLabel;

+ (CGFloat)height;

@end
