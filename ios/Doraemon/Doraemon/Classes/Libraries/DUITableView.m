//
//  DUITableView.m
//  Dayima
//
//  Created by sunzj on 14-11-11.
//
//

#import "DUITableView.h"

@interface DUITableView ()

@end

@implementation DUITableView

- (instancetype)initWithFrame:(CGRect)frame style:(UITableViewStyle)style {
    self = [super initWithFrame:frame style:style];
    if (self) {
        self.separatorInset = UIEdgeInsetsZero;
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
            if ([self respondsToSelector:@selector(setLayoutMargins:)]) {
                self.layoutMargins = UIEdgeInsetsZero;
            }
        }
    }
    return self;
}

@end
