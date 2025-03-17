//
//  PopActionSheet.h
//  Dayima
//
//  Created by sunzj on 15/9/9.
//
//

#import "PopView.h"

@class PopActionSheet;

@protocol PopActionSheetDelegate <NSObject>

- (void)popActionSheet:(PopActionSheet *)actionSheet didSelectAtIndex:(NSInteger)index;

@optional
- (void)popActionSheetDidCancel:(PopActionSheet *)actionSheet;

@end

@interface PopActionSheet : PopView

@property (nonatomic, weak) id <PopActionSheetDelegate> delegate;
@property (nonatomic, copy, readonly) NSArray *itemStrings;

- (instancetype)initWithTitle:(NSString *)title itemStrings:(NSArray *)itemStrings;
- (void)addItemString:(NSString *)itemString action:(void (^)(void))action;

+ (void)showWithTitle:(NSString *)title itemStrings:(NSArray *)itemStrings action:(void (^)(NSInteger index))action;

@end

