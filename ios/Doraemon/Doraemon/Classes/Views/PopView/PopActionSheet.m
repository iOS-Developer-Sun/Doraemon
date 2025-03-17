//
//  PopActionSheet.m
//  Dayima
//
//  Created by sunzj on 15/9/9.
//
//

#import "PopActionSheet.h"

@interface PopActionSheetItem : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) void (^action)(void);

@end

@implementation PopActionSheetItem

@end

#define kPopActionSheetHeaderViewHeight 44
#define kPopActionSheetHeaderViewNoTitleHeight 4
#define kPopActionSheetItemHeight 44
#define kPopActionSheetLineHeight (1 / [UIScreen mainScreen].scale)
#define kPopActionSheetSelectReasonDelay 0.5

@interface PopActionSheet () <PopActionSheetDelegate>

@property (nonatomic, weak) UIView *headerView;
@property (nonatomic, weak) UIView *contentView;
@property (nonatomic, weak) UILabel *titleLabel;
@property (nonatomic) NSMutableArray *items;
@property (nonatomic, copy) NSArray *itemStrings;
@property (nonatomic, copy) void (^action)(NSInteger index);
//@property (nonatomic, weak) UIButton *selectedButton;
//@property (nonatomic, strong) UIImageView *checkmarkImageView;

@end

@implementation PopActionSheet

- (instancetype)initWithTitle:(NSString *)title itemStrings:(NSArray *)itemStrings {
    self = [super initWithFrame:[UIScreen mainScreen].bounds];
    if (self) {
        
        _items = [NSMutableArray array];

        self.height = kPopActionSheetHeaderViewHeight + kPopActionSheetItemHeight * itemStrings.count;
        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.width, kPopActionSheetHeaderViewHeight)];
        headerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self addSubview:headerView];
        headerView.backgroundColor = HEXCOLOR(0xff8698ff);
        _headerView = headerView;

        UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake(0, kPopActionSheetHeaderViewHeight, self.width, self.height - kPopActionSheetHeaderViewHeight)];
        contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        contentView.backgroundColor = HEXCOLOR(0xf2f2f2ff);
        [self addSubview:contentView];
        _contentView = contentView;

        [self bringSubviewToFront:self.headerView];

        UILabel *titleLabel = [[UILabel alloc] initWithFrame:self.headerView.bounds];
        titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.font = [UIFont systemFontOfSize:16];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        [self.headerView addSubview:titleLabel];
        _titleLabel = titleLabel;
        self.titleLabel.text = title;

        for (NSString *itemString in itemStrings) {
            PopActionSheetItem *item = [[PopActionSheetItem alloc] init];
            item.title = itemString;
            item.action = nil;
            [self addItem:item];
        }

        if (title.length == 0) {
//            self.headerView.hidden = YES;
            CGFloat bottom = self.headerView.bottom;
            self.headerView.height = kPopActionSheetHeaderViewNoTitleHeight;
            self.headerView.bottom = bottom;
        }
//        _checkmarkImageView = [[UIImageView alloc] initWithImage:[UIImage imageWithFile:[NSString stringWithFormat:@"%@/%@/img/popDialog/forum_btn_right.png", [[NSBundle mainBundle] bundlePath], @"Dayima-Forum.bundle"]]];
    }

    return self;
}

- (void)addItem:(PopActionSheetItem *)item {
    NSInteger index = self.items.count;
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0, kPopActionSheetItemHeight * index, self.contentView.width, kPopActionSheetItemHeight);
    button.backgroundColor = [UIColor clearColor];
    button.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [button setTitle:item.title forState:UIControlStateNormal];
    [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [button setTitleColor:HEXCOLOR(0xff8698ff) forState:UIControlStateHighlighted];
    button.titleLabel.font = [UIFont systemFontOfSize:16];
    [button addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    button.tag = index;
    [self.contentView addSubview:button];

    UIView *line = [[UIView alloc] init];
    line.frame = CGRectMake(0, button.bottom, self.contentView.width, kPopActionSheetLineHeight);
    line.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    line.backgroundColor = HEXCOLOR(0xcbcbcbff);
    [self.contentView addSubview:line];

    [self.items addObject:item];
    self.itemStrings = [(self.itemStrings ?: @[]) arrayByAddingObject:item.title];
}

- (void)maskViewDidTap {
    if (self.delegate && [self.delegate respondsToSelector:@selector(popActionSheetDidCancel:)]) {
        [self.delegate popActionSheetDidCancel:self];
    }
    [super maskViewDidTap];
}

- (void)buttonTapped:(UIButton *)sender {
//    self.selectedButton = sender;
//    self.checkmarkImageView.center = CGPointMake(sender.width / 2.0 + 70, sender.height / 2.0);
//    [sender addSubview:self.checkmarkImageView];
//    [sender setTitleColor:[[SkinManager sharedInstance].currentSkin dialogTitleBg] forState:UIControlStateNormal];
    NSInteger index = sender.tag;
//    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kPopActionSheetSelectReasonDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
        PopActionSheetItem *item = self.items[index];
        if (item.action) {
            item.action();
        }

        if (self.delegate && [self.delegate respondsToSelector:@selector(popActionSheet:didSelectAtIndex:)]) {
            [self.delegate popActionSheet:self didSelectAtIndex:index];
        }
        [self hide];
//    });
}

- (void)addItemString:(NSString *)itemString action:(void (^)(void))action {
    PopActionSheetItem *item = [[PopActionSheetItem alloc] init];
    item.title = itemString;
    item.action = action;
    [self addItem:item];

    [self adjustHeight];
}

- (void)adjustHeight {
    CGFloat contentViewHeight = kPopActionSheetItemHeight * self.items.count;
    self.height = kPopActionSheetHeaderViewHeight + contentViewHeight;
    self.contentView.height = contentViewHeight;
}

+ (void)showWithTitle:(NSString *)title itemStrings:(NSArray *)itemStrings action:(void (^)(NSInteger index))action {
    PopActionSheet *actionSheet = [[self alloc] initWithTitle:title itemStrings:itemStrings];
    actionSheet.delegate = actionSheet;
    actionSheet.action = action;
    [actionSheet show];
}

- (void)popActionSheet:(PopActionSheet *)actionSheet didSelectAtIndex:(NSInteger)index {
    if (self.action) {
        self.action(index);
    }
}

@end
