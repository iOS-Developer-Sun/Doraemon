//
//  PopMenu.m
//  Dayima
//
//  Created by sunzj on 15/9/9.
//
//

#import "PopMenu.h"

@interface PopMenu ()

@property (nonatomic, weak) UIView *headerView;
@property (nonatomic, weak) UIView *contentView;
@property (nonatomic, weak) UILabel *titleLabel;
@property (nonatomic, weak) UIButton *okButton;
@property (nonatomic, weak) UIButton *cancelButton;

@end

@implementation PopMenu

- (instancetype)initWithHeight:(CGFloat)height {
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    CGRect frame = CGRectMake(0, 0, window.width, height);
    return [self initWithFrame:frame];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        if (self.height < 44) {
            self.height = 44;
        }
        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.width, 44)];
        headerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self addSubview:headerView];
        headerView.backgroundColor = HEXCOLOR(0xff8698ff);
        _headerView = headerView;

        UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 44, self.width, self.height - 44)];
        contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        contentView.backgroundColor = [UIColor whiteColor];
        [self addSubview:contentView];
        _contentView = contentView;

        [self bringSubviewToFront:self.headerView];

        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectInset(self.headerView.bounds, 10, 0)];
        titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.textColor = HEXCOLOR(0xffffffff);
        titleLabel.font = [UIFont systemFontOfSize:15.0f];
        [self.headerView addSubview:titleLabel];
        _titleLabel = titleLabel;

        UIButton *okButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 44, headerView.height)];
        okButton.right = headerView.width;
        okButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [okButton addTarget:self action:@selector(buttonDidTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
        [okButton setImage:[UIImage imageNamed:@"calendar_btn_save"] forState:UIControlStateNormal];
        [okButton setImage:[UIImage imageNamed:@"calendar_btn_save_pressed"] forState:UIControlStateHighlighted];
        [self.headerView addSubview:okButton];
        _okButton = okButton;

        UIButton *cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 44, headerView.height)];
        cancelButton.right = okButton.left - 10;
        cancelButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [cancelButton addTarget:self action:@selector(buttonDidTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
        [cancelButton setImage:[UIImage imageNamed:@"calendar_btn_cancel"] forState:UIControlStateNormal];
        [cancelButton setImage:[UIImage imageNamed:@"calendar_btn_cancel_pressed"] forState:UIControlStateHighlighted];
        [self.headerView addSubview:cancelButton];
        _cancelButton = cancelButton;
    }
    return self;
}

- (void)buttonDidTouchUpInside:(UIButton *)button {
    if (button == self.okButton) {
        if ([self.delegate respondsToSelector:@selector(popMenuDidClickOKButton:stopsHiding:)]) {
            BOOL stopsHiding = NO;
            [self.delegate popMenuDidClickOKButton:self stopsHiding:&stopsHiding];
            if (!stopsHiding) {
                [self hide];
            }
        } else {
            if ([self.delegate respondsToSelector:@selector(popMenuDidClickOKButton:)]) {
                [self.delegate popMenuDidClickOKButton:self];
            }
            [self hide];
        }
    } else if (button == self.cancelButton) {
        if ([self.delegate respondsToSelector:@selector(popMenuDidClickCancelButton:)]) {
            [self.delegate popMenuDidClickCancelButton:self];
        }
        [self hide];
    } else {
        ;
    }
}

- (void)maskViewDidTap {
    if ([self.delegate respondsToSelector:@selector(popMenuDidCancel:)]) {
        [self.delegate popMenuDidCancel:self];
    }
    [super maskViewDidTap];
}

- (NSString *)title {
    return self.titleLabel.text;
}

- (void)setTitle:(NSString *)title {
    self.titleLabel.text = title;
}

- (BOOL)cancelButtonHidden {
    return self.cancelButton.hidden;
}

- (void)setCancelButtonHidden:(BOOL)cancelButtonHidden {
    self.cancelButton.hidden = cancelButtonHidden;
}

@end
