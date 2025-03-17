//
//  AvatarView.m
//  Doraemon
//
//  Created by sunzj on 17/1/7.
//  Copyright © 2017年 sunzj. All rights reserved.
//

#import "AvatarView.h"
#import "UIImageView+AFNetworking.h"

@interface AvatarView ()

@property (nonatomic, weak) UIImageView *imageView;

@end

@implementation AvatarView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        imageView.layer.masksToBounds = YES;
        imageView.image = [UIImage imageNamed:@"avatarPlaceholder"];
        imageView.backgroundColor = [UIColor lightGrayColor];
        [self addSubview:imageView];
        _imageView = imageView;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    self.imageView.layer.cornerRadius = (MIN(self.imageView.width, self.imageView.height)) / 2;
}

- (void)setAvatarImage:(UIImage *)image {
    if (image) {
        self.imageView.image = image;
    } else {
        self.imageView.image = [UIImage imageNamed:@"avatarPlaceholder"];
    }
}

- (void)setAvatarUrlString:(NSString *)avatarUrlString {
    if (avatarUrlString.length > 0) {
        [self.imageView setImageWithURL:[NSURL URLWithString:avatarUrlString]];
    } else {
        self.imageView.image = [UIImage imageNamed:@"avatarPlaceholder"];
    }
}


@end
