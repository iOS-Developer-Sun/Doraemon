//
//  DoraemonAddRecordViewController.h
//  King
//
//  Created by sunzj on 16/2/6.
//  Copyright © 2016年 sunzj. All rights reserved.
//

#import "DUIViewController.h"

@class DoraemonAddRecordViewController;

@protocol DoraemonAddRecordViewControllerDelegate <NSObject>

- (void)doraemonAddRecordViewController:(DoraemonAddRecordViewController *)doraemonAddRecordViewController didAddRecord:(NSArray *)record;
- (void)doraemonAddRecordViewControllerDidCancel:(DoraemonAddRecordViewController *)doraemonAddRecordViewController;

@end

@interface DoraemonAddRecordViewController : DUIViewController

@property (nonatomic, weak) id <DoraemonAddRecordViewControllerDelegate> delegate;
@property (nonatomic, copy) NSArray *playerIds;
@property (nonatomic, copy) NSArray *lastRecord;

@end
