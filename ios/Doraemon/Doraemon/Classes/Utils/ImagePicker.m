//
//  ImagePicker.m
//  Dayima
//
//  Created by sunzj on 15/4/28.
//
//

#import "ImagePicker.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "ImagePickerGroupListController.h"
#import "ImagePickerAssetListController.h"
#import "CroppingImageViewController.h"
#import "DUINavigationController.h"

static NSMutableArray *imagePickers;

@interface ImagePicker () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIAlertViewDelegate, ImagePickerGroupListControllerDelegate, ImagePickerAssetListControllerDelegate, CroppingImageViewControllerDelegate>

@property (nonatomic, weak) UIImagePickerController *imagePickerController;
@property (nonatomic) BOOL animated;

@property (nonatomic, weak) ImagePickerGroupListController *groupListController;
@property (nonatomic, weak) ImagePickerAssetListController *assetListController;

@property (nonatomic, copy) NSArray *groups;
@property (nonatomic) NSMutableDictionary *groupsDictionary;

@property (nonatomic) ALAssetsLibrary *library;
@property (nonatomic, copy) void (^completion)(ImagePickerResult result, NSArray *assets, UIImage *image);

@property (nonatomic) NSInteger currentGroupIndex;
@property (nonatomic) NSMutableArray *selectedAssets;

@end

@implementation ImagePicker

+ (void)initialize {
    imagePickers = [NSMutableArray array];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _animated = YES;
        _selectedAssets = [NSMutableArray array];
        _groupsDictionary = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)dealloc {
    _imagePickerController.delegate = nil;
}

- (NSInteger)count {
    if (_count < 1) {
        _count = 1;
    }
    return _count;
}

- (void)setGroups:(NSArray *)groups {
    _groups = groups.copy;
    [self.groupListController reload];

    NSInteger index = -1;
    for (NSInteger i = 0; i < self.groups.count; i++) {
        ALAssetsGroup *group = self.groups[i];
        NSInteger type = [[group valueForProperty:ALAssetsGroupPropertyType] integerValue];
        if (type == ALAssetsGroupSavedPhotos) {
            index = i;
        }
    }
    if (index >= 0) {
        ALAssetsGroup *tempGroup = self.groups[index];
        NSArray *assets = self.groupsDictionary[@(index)];
        if (assets == nil) {
            [self loadAssetsWithGroup:tempGroup index:index];
        }
        self.assetListController.title = [tempGroup valueForProperty:ALAssetsGroupPropertyName];
    }

    self.currentGroupIndex = index;
}

- (void)showWithController:(UIViewController *)viewController completion:(void (^)(ImagePickerResult, NSArray *, UIImage *))completion {
    self.completion = completion;
    switch (self.sourceType) {
        case ImagePickerSourceTypeCamera: {
            [self showCameraWithController:viewController];
            break;
        }
        case ImagePickerSourceTypePhotoLibrary: {
            [self showPhotoLibraryWithController:viewController];
            break;
        }
        default:
            break;
    }
}

- (void)showCameraWithController:(UIViewController *)viewController {
    [imagePickers addObject:self];
    if ([AVCaptureDevice respondsToSelector:@selector(authorizationStatusForMediaType:)]) {
        AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        if (authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied) {
            [[[UIAlertView alloc] initWithTitle:@"提示"
                                        message:@"相机未开启，请在“设置-隐私-相机”中允许访问"
                                       delegate:nil
                              cancelButtonTitle:@"确定"
                              otherButtonTitles:nil] show];
            return;
        }
    }

    UIImagePickerControllerSourceType sourceType = UIImagePickerControllerSourceTypeCamera;
    if(![UIImagePickerController isSourceTypeAvailable:sourceType]) {
        [self showPhotoLibraryWithController:viewController];
        return;
    }

    self.animated = YES;

    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.delegate = self;
    imagePickerController.sourceType = sourceType;
    imagePickerController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    self.imagePickerController = imagePickerController;

    [viewController presentViewController:imagePickerController animated:self.animated completion:nil];
}

- (void)showPhotoLibraryWithController:(UIViewController *)viewController {
    [imagePickers addObject:self];

    ALAuthorizationStatus status = [ALAssetsLibrary authorizationStatus];
    if (status == ALAuthorizationStatusRestricted || status == ALAuthorizationStatusDenied) {
        [[[UIAlertView alloc] initWithTitle:(@"提示")
                                    message:(@"图片无法显示，请在系统设置-隐私-照片项目里开启的访问权限！")
                                   delegate:self
                          cancelButtonTitle:(@"确定")
                          otherButtonTitles:nil] show];
        return;
    }

    ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
    self.library = assetsLibrary;
    NSMutableArray *groups = [NSMutableArray array];
    [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {//获取所有group
        if (group == nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.groups = groups;
            });
            return;
        }
        [groups addObject:group];

    } failureBlock:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.groups = groups.copy;
        });
    }];

    ImagePickerGroupListController *groupListController = [[ImagePickerGroupListController alloc] init];
    groupListController.delegate = self;
    DUINavigationController *nav = [[DUINavigationController alloc] initWithRootViewController:groupListController];
    nav.objectIdentifier = @"ImagePickerNavigationController";

    ImagePickerAssetListController *assetListController = [[ImagePickerAssetListController alloc] init];
    assetListController.delegate = self;
    self.assetListController = assetListController;

    [self setupAssetListController];

    [nav pushViewController:assetListController animated:YES];

    [viewController presentViewController:nav animated:self.animated completion:nil];
    self.groupListController = groupListController;
}

- (void)setupAssetListController {
    self.assetListController.selectedCount = self.selectedAssets.count;
    self.assetListController.countViewHidden = (self.selectionType == ImagePickerSelectionTypeNone);
    self.assetListController.countLabelHidden = (self.selectionType == ImagePickerSelectionTypeRadio || self.selectedAssets.count == 0);
    self.assetListController.selectionOnIndicatorHidden = (self.selectionType == ImagePickerSelectionTypeNone);
    self.assetListController.selectionOffIndicatorHidden = (self.selectionType != ImagePickerSelectionTypeCheckBox);
}

- (ALAsset *)assetSelectedAndSameWith:(ALAsset *)asset {
    ALAsset *assetFound = nil;
    NSURL *url = [asset valueForProperty:ALAssetPropertyAssetURL];
    for (ALAsset *each in self.selectedAssets) {
        NSURL *eachUrl = [each valueForProperty:ALAssetPropertyAssetURL];
        if ([url isEqual:eachUrl]) {
            assetFound = each;
            break;
        }
    };
    return assetFound;
}

- (void)loadAssetsWithGroup:(ALAssetsGroup *)group index:(NSInteger)currentIndex {
    NSMutableArray *assets = [NSMutableArray array];
    [group enumerateAssetsUsingBlock:^(ALAsset *asset, NSUInteger index, BOOL *stop) {//从group里面
        if (asset == nil) {
            *stop = YES;
            dispatch_async(dispatch_get_main_queue(), ^{
                self.groupsDictionary[@(currentIndex)] = assets.copy;
                if (assets.count) {
                    [self.assetListController reload];
                    [self.assetListController scrollToIndex:assets.count - 1 animated:NO];
                }
            });
            return;
        }

        [group setAssetsFilter:[ALAssetsFilter allPhotos]];
        [assets addObject:asset];
    }];
}

#pragma mark - ImagePickerGroupListControllerDelegate

- (NSInteger)groupListControllerNumberOfAlbums:(ImagePickerGroupListController *)groupListController {
    return self.groups.count;
}

- (ALAssetsGroup *)groupListController:(ImagePickerGroupListController *)groupListController groupAtIndex:(NSInteger)index {
    ALAssetsGroup *group = self.groups[index];
    return group;
}

- (void)groupListController:(ImagePickerGroupListController *)groupListController didSelectGroupAtIndex:(NSInteger)index {
    self.currentGroupIndex = index;

    ImagePickerAssetListController *assetListController = [[ImagePickerAssetListController alloc] init];
    assetListController.delegate = self;
    ALAssetsGroup *group = self.groups[index];
    NSArray *assets = self.groupsDictionary[@(index)];
    if (assets == nil) {
        [self loadAssetsWithGroup:group index:index];
    }
    self.assetListController = assetListController;
    self.assetListController.title = [group valueForProperty:ALAssetsGroupPropertyName];

    [self setupAssetListController];

    if (assets.count) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.assetListController reload];
            if ([[UIDevice currentDevice].systemVersion floatValue] < 7.0) {
                [self.assetListController setScrollToIndex:assets.count - 1 animated:NO];
            } else {
                [self.assetListController scrollToIndex:assets.count - 1 animated:NO];
            }
        });
    }

    [groupListController.navigationController pushViewController:assetListController animated:YES];
}

- (void)groupListControllerDidCancel:(ImagePickerGroupListController *)groupListController {
    [groupListController.navigationController dismissViewControllerAnimated:self.animated completion:nil];
    if (self.completion) {
        self.completion(ImagePickerResultCancelled, nil, nil);
    }

    [imagePickers removeObject:self];
}

#pragma mark - ImagePickerAssetListControllerDelegate

- (NSInteger)assetListControllerNumberOfAssets:(ImagePickerAssetListController *)assetListController {
    NSArray *assets = self.groupsDictionary[@(self.currentGroupIndex)];
    return assets.count;
}

- (ALAsset *)assetListController:(ImagePickerAssetListController *)assetListController assetAtIndex:(NSInteger)index {
    NSArray *assets = self.groupsDictionary[@(self.currentGroupIndex)];
    ALAsset *asset = assets[index];
    return asset;
}

- (BOOL)assetListController:(ImagePickerAssetListController *)assetListController isAssetSelectedAtIndex:(NSInteger)index {
    NSArray *assets = self.groupsDictionary[@(self.currentGroupIndex)];
    ALAsset *asset = assets[index];
    BOOL isSelected = ([self assetSelectedAndSameWith:asset] != nil);
    return isSelected;
}

- (void)assetListController:(ImagePickerAssetListController *)assetListController didSelectAssetAtIndex:(NSInteger)index {
    NSArray *assets = self.groupsDictionary[@(self.currentGroupIndex)];
    ALAsset *asset = assets[index];
    switch (self.selectionType) {
        case ImagePickerSelectionTypeNone: {
            if (self.allowsEditing) {
                ALAssetRepresentation *representation = asset.defaultRepresentation;
                UIImage *image = [UIImage imageWithCGImage:representation.fullScreenImage];
                CroppingImageViewController *croppingImageViewController = [[CroppingImageViewController alloc] init];
                croppingImageViewController.image = image;
                croppingImageViewController.delegate = self;
                croppingImageViewController.croppingView = self.croppingView;
                croppingImageViewController.croppingRect = self.croppingRect;
                [assetListController.navigationController pushViewController:croppingImageViewController animated:YES];
            } else {
                [assetListController.navigationController dismissViewControllerAnimated:self.animated completion:nil];
                if (self.completion) {
                    self.completion(ImagePickerResultSuccess, @[asset], nil);
                }
                [imagePickers removeObject:self];
            }
            break;
        }
        case ImagePickerSelectionTypeRadio: {
            ALAsset *oldAsset = self.selectedAssets.lastObject;
            [self.selectedAssets removeAllObjects];
            [self.selectedAssets addObject:asset];

            [self setupAssetListController];
            if (oldAsset) {
                NSInteger oldIndex = [assets indexOfObject:oldAsset];
                [self.assetListController reloadItemAtIndex:oldIndex];
                [self.assetListController reloadItemAtIndex:index];
            } else {
                [self.assetListController reload];
            }

            break;
        }
        case ImagePickerSelectionTypeCheckBox: {
            ALAsset *selectedAsset = [self assetSelectedAndSameWith:asset];
            if (selectedAsset) {
                [self.selectedAssets removeObject:selectedAsset];
            } else {
                if (self.selectedAssets.count >= self.count) {
                    [[[UIAlertView alloc] initWithTitle:@"" message:[NSString stringWithFormat:@"您此次最多可选择%@张图片", @(self.count)] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                } else {
                    [self.selectedAssets addObject:asset];
                }
            }

            [self setupAssetListController];
            [self.assetListController reloadItemAtIndex:index];
            break;
        }
        default:
            break;
    }
}

- (void)assetListControllerDidConfirm:(ImagePickerAssetListController *)assetListController {
    [assetListController.navigationController dismissViewControllerAnimated:self.animated completion:nil];
    if (self.completion) {
        NSMutableArray *assets = [NSMutableArray array];
        for (ALAsset *each in self.selectedAssets) {
            [assets addObject:each];
        }
        self.completion(ImagePickerResultSuccess, assets.copy, nil);
    }
    [imagePickers removeObject:self];
}

- (void)assetListControllerDidCancel:(ImagePickerAssetListController *)assetListController {
    [assetListController.navigationController dismissViewControllerAnimated:self.animated completion:nil];
    if (self.completion) {
        self.completion(ImagePickerResultCancelled, nil, nil);
    }

    [imagePickers removeObject:self];
}

#pragma mark - UIImagePickerViewControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    if (self.allowsEditing) {
        UIImage *image = info[UIImagePickerControllerOriginalImage];
        CroppingImageViewController *croppingImageViewController = [[CroppingImageViewController alloc] init];
        croppingImageViewController.image = image;
        croppingImageViewController.delegate = self;
        croppingImageViewController.croppingView = self.croppingView;
        croppingImageViewController.croppingRect = self.croppingRect;
        [picker pushViewController:croppingImageViewController animated:YES];
    } else {
        UIImage *image = info[UIImagePickerControllerOriginalImage];
        [picker dismissViewControllerAnimated:self.animated completion:nil];
        if (self.completion) {
            self.completion(ImagePickerResultSuccess, nil, image);
        }
        [imagePickers removeObject:self];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:self.animated completion:nil];
    if (self.completion) {
        self.completion(ImagePickerResultCancelled, nil, nil);
    }

    [imagePickers removeObject:self];
}

#pragma mark - CroppingImageViewControllerDelegate

- (void)croppingImageViewController:(CroppingImageViewController *)croppingImageViewController didFinishCroppingWithImage:(UIImage *)image {
    [croppingImageViewController.navigationController dismissViewControllerAnimated:YES completion:nil];
    if (self.completion) {
        self.completion(ImagePickerResultSuccess, nil, image);
    }

    [imagePickers removeObject:self];
}

- (void)croppingImageViewControllerDidCancel:(CroppingImageViewController *)croppingImageViewController {
    if (self.sourceType == ImagePickerSourceTypeCamera) {
        [croppingImageViewController.navigationController dismissViewControllerAnimated:YES completion:nil];
        if (self.completion) {
            self.completion(ImagePickerResultCancelled, nil, nil);
        }

        [imagePickers removeObject:self];
    } else {
        [croppingImageViewController.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (self.completion) {
        self.completion(ImagePickerResultDenied, nil, nil);
    }

    [imagePickers removeObject:self];
}

- (void)alertViewCancel:(UIAlertView *)alertView {
    if (self.completion) {
        self.completion(ImagePickerResultDenied, nil, nil);
    }

    [imagePickers removeObject:self];
}

@end
