//
//  DUILabel.m
//  Dayima
//
//  Created by sunzj on 15-7-24.
//
//

#import "DUILabel.h"

@interface DUILabel ()

@end

@implementation DUILabel

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)setText:(NSString *)text {
    if (self.labelLineSpacing == 0) {
        self.attributedText = nil;
        super.text = text;
    } else {
        if (text) {
            NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
            paragraph.lineSpacing = self.labelLineSpacing;
            self.attributedText = [[NSAttributedString alloc] initWithString:text attributes:@{NSFontAttributeName:self.font, NSParagraphStyleAttributeName:paragraph}];
        } else {
            self.attributedText = nil;
            super.text = nil;
        }
    }
}

@end
