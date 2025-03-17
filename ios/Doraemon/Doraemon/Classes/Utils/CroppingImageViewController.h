//
//  CroppingImageViewController.h
//  Dayima
//
//  Created by sunzj on 15/4/28.
//
//

#import "DUIViewController.h"

@class CroppingImageViewController;

@protocol CroppingImageViewControllerDelegate <NSObject>

- (void)croppingImageViewController:(CroppingImageViewController *)croppingImageViewController didFinishCroppingWithImage:(UIImage *)image;
- (void)croppingImageViewControllerDidCancel:(CroppingImageViewController *)croppingImageViewController;

@end

@interface CroppingImageViewController : DUIViewController

@property (nonatomic) UIImage *image;
@property (nonatomic, weak) id <CroppingImageViewControllerDelegate> delegate;
@property (nonatomic) CGRect croppingRect;
@property (nonatomic) UIView *croppingView;

@end
