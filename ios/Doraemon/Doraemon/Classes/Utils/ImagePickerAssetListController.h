//
//  ImagePickerAssetListController.h
//  Dayima
//
//  Created by sunzj on 15/4/28.
//
//

#import "DUIViewController.h"
#import "ImagePicker.h"

@class ImagePickerAssetListController;

@protocol ImagePickerAssetListControllerDelegate <NSObject>

- (ALAsset *)assetListController:(ImagePickerAssetListController *)assetListController assetAtIndex:(NSInteger)index;
- (BOOL)assetListController:(ImagePickerAssetListController *)assetListController isAssetSelectedAtIndex:(NSInteger)index;
- (NSInteger)assetListControllerNumberOfAssets:(ImagePickerAssetListController *)assetListController;

- (void)assetListController:(ImagePickerAssetListController *)assetListController didSelectAssetAtIndex:(NSInteger)index;
- (void)assetListControllerDidConfirm:(ImagePickerAssetListController *)assetListController;
- (void)assetListControllerDidCancel:(ImagePickerAssetListController *)assetListController;

@end

@interface ImagePickerAssetListController : DUIViewController

@property (nonatomic, weak) id <ImagePickerAssetListControllerDelegate> delegate;
@property (nonatomic) BOOL countViewHidden;
@property (nonatomic) BOOL countLabelHidden;
@property (nonatomic) NSInteger selectedCount;
@property (nonatomic) BOOL selectionOnIndicatorHidden;
@property (nonatomic) BOOL selectionOffIndicatorHidden;

- (void)reload;
- (void)scrollToIndex:(NSInteger)index animated:(BOOL)animated;
- (void)reloadItemAtIndex:(NSInteger)index;
// Used for iOS6
- (void)setScrollToIndex:(NSInteger)index animated:(BOOL)animated;
@end

