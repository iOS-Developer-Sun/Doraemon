//
//  ImagePickerGroupListController.h
//  Dayima
//
//  Created by sunzj on 15/4/28.
//
//

#import "DUIViewController.h"
#import "ImagePicker.h"

@class ImagePickerGroupListController;

@protocol ImagePickerGroupListControllerDelegate <NSObject>

- (ALAssetsGroup *)groupListController:(ImagePickerGroupListController *)groupListController groupAtIndex:(NSInteger)index;
- (NSInteger)groupListControllerNumberOfAlbums:(ImagePickerGroupListController *)groupListController;


- (void)groupListController:(ImagePickerGroupListController *)groupListController didSelectGroupAtIndex:(NSInteger)index;
- (void)groupListControllerDidCancel:(ImagePickerGroupListController *)groupListController;

@end

@interface ImagePickerGroupListController : DUIViewController

@property (nonatomic, weak) id <ImagePickerGroupListControllerDelegate> delegate;

- (void)reload;

@end
