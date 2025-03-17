//
//  ImagePicker.h
//  Dayima
//
//  Created by sunzj on 15/4/28.
//
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

typedef NS_ENUM (NSInteger, ImagePickerResult) {
    ImagePickerResultSuccess,
    ImagePickerResultDenied,
    ImagePickerResultCancelled
};

typedef NS_ENUM (NSInteger, ImagePickerSourceType) {
    ImagePickerSourceTypePhotoLibrary,
    ImagePickerSourceTypeCamera,
};

typedef NS_ENUM (NSInteger, ImagePickerSelectionType) {
    ImagePickerSelectionTypeNone,
    ImagePickerSelectionTypeRadio,
    ImagePickerSelectionTypeCheckBox,
};

@interface ImagePicker : NSObject

@property (nonatomic) ImagePickerSourceType sourceType;
@property (nonatomic) BOOL allowsEditing;
@property (nonatomic) ImagePickerSelectionType selectionType;
@property (nonatomic) NSInteger count;

@property (nonatomic) CGRect croppingRect;
@property (nonatomic) UIView *croppingView;

- (void)showWithController:(UIViewController *)viewController completion:(void (^)(ImagePickerResult result, NSArray *assets, UIImage *image))completion;

@end
