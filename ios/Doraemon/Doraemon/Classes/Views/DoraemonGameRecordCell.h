//
//  DoraemonGameRecordCell.h
//  King
//
//  Created by sunzj on 2/5/16.
//  Copyright © 2016 sunzj. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DoraemonGameRecordCell : UITableViewCell

@property (nonatomic) BOOL showsScores;

- (void)setScores:(NSArray *)scores;
- (void)setGameRecord:(NSArray *)gameRecord;

+ (CGFloat)height;

@end
