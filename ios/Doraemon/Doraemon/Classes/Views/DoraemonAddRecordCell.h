//
//  DoraemonAddRecordCell.h
//  King
//
//  Created by sunzj on 2/5/16.
//  Copyright © 2016 sunzj. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DoraemonAddRecordCell;

@protocol DoraemonAddRecordCellDelegate <NSObject>

- (void)doraemonAddRecordCellDidTap:(DoraemonAddRecordCell *)doraemonAddRecordCell;

@end

@interface DoraemonAddRecordCell : UITableViewCell

@property (nonatomic, weak) id <DoraemonAddRecordCellDelegate> delegate;

- (void)setPlayerAvatarUrlString:(NSString *)avatarUrlString;
- (void)setPlayerName:(NSString *)playerName;
- (void)setJoker:(BOOL)isJoker;

+ (CGFloat)height;

@end
