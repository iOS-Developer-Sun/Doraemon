//
//  PopMenu.h
//  Dayima
//
//  Created by sunzj on 15/9/9.
//
//

#import "PopView.h"

@class PopMenu;

@protocol PopMenuDelegate <NSObject>

@optional
- (void)popMenuDidClickOKButton:(PopMenu *)menu;
- (void)popMenuDidClickOKButton:(PopMenu *)menu stopsHiding:(BOOL *)stopsHiding;
- (void)popMenuDidClickCancelButton:(PopMenu *)menu;
- (void)popMenuDidCancel:(PopMenu *)menu;

@end

@interface PopMenu : PopView

@property (nonatomic, weak, readonly) UIView *headerView;
@property (nonatomic, weak, readonly) UIView *contentView;
@property (nonatomic, weak) id <PopMenuDelegate> delegate;
@property NSString *title;
@property BOOL cancelButtonHidden;

@end
