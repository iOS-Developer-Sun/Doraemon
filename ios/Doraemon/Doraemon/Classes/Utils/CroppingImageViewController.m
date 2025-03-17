//
//  CroppingImageViewController.m
//  Dayima
//
//  Created by sunzj on 15/4/28.
//
//

#import "CroppingImageViewController.h"
#import "CroppingView.h"
#import "UIImage+Ext.h"

@interface CroppingImageViewController () <UIScrollViewDelegate>

@property (nonatomic) UIImage *imageToOperate;
@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, weak) UIImageView *imageView;

@property (nonatomic) CGPoint originalContentOffset;
@property (nonatomic) CGFloat originalZoomScale;

@end

@implementation CroppingImageViewController

- (CGRect)croppingRect {
    if (_croppingRect.size.width == 0 || _croppingRect.size.height == 0) {
        CGFloat length = MIN(self.scrollView.width, self.scrollView.height);
        CGRect rect = CGRectMake((self.view.width - length) / 2, (self.view.height - length) / 2, length, length);
        _croppingRect = CGRectInset(rect, 5, 5);
    }
    return _croppingRect;
}

- (UIView *)croppingView {
    UIView *croppingView = _croppingView;
    if (croppingView == nil) {
        CroppingView *newCroppingView = [[CroppingView alloc] initWithFrame:self.view.bounds];
        newCroppingView.croppingIndicatorRect = self.croppingRect;
        croppingView = newCroppingView;
        _croppingView = croppingView;
    }
    croppingView.userInteractionEnabled = NO;
    return croppingView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBarHidden = YES;
    self.view.backgroundColor = [UIColor blackColor];

    self.imageToOperate = self.image;

    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    scrollView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:scrollView];
    self.scrollView = scrollView;

    UIImageView *imageView = [[UIImageView alloc] init];
    [scrollView addSubview:imageView];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView = imageView;

    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.maximumZoomScale = 10;
    scrollView.minimumZoomScale = 1;
    scrollView.delegate = self;

    UITapGestureRecognizer *tapTwiceGestureRecognizer = [[UITapGestureRecognizer alloc] init];
    tapTwiceGestureRecognizer.numberOfTapsRequired = 2;
    [tapTwiceGestureRecognizer addTarget:self action:@selector(tapTwice:)];
    [scrollView addGestureRecognizer:tapTwiceGestureRecognizer];

    [self.view addSubview:self.croppingView];

    UIView *bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.height - 60, self.view.width, 60)];
    bottomView.backgroundColor = HEXCOLOR(0x0000007f);
    bottomView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    [self.view addSubview:bottomView];
    bottomView.userInteractionEnabled = NO;

    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    cancelButton.exclusiveTouch = YES;
    cancelButton.frame = CGRectMake(0, self.view.height - bottomView.height, 90, bottomView.height);
    cancelButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin;
    [cancelButton setTitle:DTEXT(@"取消") forState:UIControlStateNormal];
    [cancelButton addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
    cancelButton.titleLabel.font = [UIFont systemFontOfSize:18];
    [cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.view addSubview:cancelButton];

    UIButton *confirmButton = [UIButton buttonWithType:UIButtonTypeCustom];
    confirmButton.exclusiveTouch = YES;
    confirmButton.frame = CGRectMake(self.view.width - 90, self.view.height - bottomView.height, 90, bottomView.height);
    confirmButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;
    [confirmButton setTitle:DTEXT(@"确定") forState:UIControlStateNormal];
    [confirmButton addTarget:self action:@selector(confirm) forControlEvents:UIControlEventTouchUpInside];
    confirmButton.titleLabel.font = [UIFont systemFontOfSize:18];
    [confirmButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.view addSubview:confirmButton];

    CGFloat margin = 85;
    if (IS_480 && IS_IPHONE) {
        margin = 50;
    }

    UIButton *rotateLeftButton = [UIButton buttonWithType:UIButtonTypeCustom];
    rotateLeftButton.exclusiveTouch = YES;
    rotateLeftButton.frame = CGRectMake(self.view.width - 150, (self.view.height - self.view.width) / 2 - margin, 45, 45);
    rotateLeftButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [rotateLeftButton addTarget:self action:@selector(rotateLeft) forControlEvents:UIControlEventTouchUpInside];
    [rotateLeftButton setImage:[UIImage imageNamed:@"forum_bg_image_leftrotation.png"] forState:UIControlStateNormal];
    [self.view addSubview:rotateLeftButton];

    UIButton *rotateRightButton = [UIButton buttonWithType:UIButtonTypeCustom];
    rotateRightButton.exclusiveTouch = YES;
    rotateRightButton.frame = CGRectMake(self.view.width - 80, (self.view.height - self.view.width) / 2 - margin, 45, 45);
    rotateRightButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [rotateRightButton addTarget:self action:@selector(rotateRight) forControlEvents:UIControlEventTouchUpInside];
    [rotateRightButton setImage:[UIImage imageNamed:@"forum_bg_image_rightrotation.png"] forState:UIControlStateNormal];
    [self.view addSubview:rotateRightButton];

    // calculate
    CGSize imageViewSize = self.imageToOperate.size;
    CGSize croppingSize = self.croppingRect.size;
    CGSize scrollViewSize = self.scrollView.bounds.size;

    CGFloat imageViewSizeRatio = imageViewSize.width / imageViewSize.height;
    CGFloat croppingSizeRatio = croppingSize.width / croppingSize.height;

    if (imageViewSizeRatio > croppingSizeRatio) {
        imageViewSize = CGSizeMake(imageViewSizeRatio * croppingSize.height, croppingSize.height);
    } else {
        imageViewSize = CGSizeMake(croppingSize.width, croppingSize.width / imageViewSizeRatio);
    }

    CGFloat minimumZoomScale = 1;
    CGFloat scrollViewScale = 1;
    if (imageViewSize.width < scrollViewSize.width && imageViewSize.height < scrollViewSize.height) {
        minimumZoomScale = MAX(imageViewSize.width / scrollViewSize.width, imageViewSize.height / scrollViewSize.height);
        scrollViewScale = MAX(imageViewSize.width / scrollViewSize.width, imageViewSize.height / scrollViewSize.height);
    }
    self.scrollView.minimumZoomScale = minimumZoomScale;
    
    self.imageView.image = self.imageToOperate;
    self.imageView.frame = CGRectMake(self.croppingRect.origin.x, self.croppingRect.origin.y, imageViewSize.width / scrollViewScale, imageViewSize.height / scrollViewScale);
    [self calcutaleContentSize];

    self.scrollView.contentOffset = CGPointMake((self.scrollView.contentSize.width - self.scrollView.bounds.size.width) / 2, (self.scrollView.contentSize.height - self.scrollView.bounds.size.height) / 2);
}

- (void)calcutaleImageSizeAndContentSize {
    CGSize imageViewSize = self.imageToOperate.size;
    CGSize croppingSize = self.croppingRect.size;
    CGSize scrollViewSize = self.scrollView.bounds.size;

    CGFloat imageViewSizeRatio = imageViewSize.width / imageViewSize.height;
    CGFloat croppingSizeRatio = croppingSize.width / croppingSize.height;

    if (imageViewSizeRatio > croppingSizeRatio) {
        imageViewSize = CGSizeMake(imageViewSizeRatio * croppingSize.height, croppingSize.height);
    } else {
        imageViewSize = CGSizeMake(croppingSize.width, croppingSize.width / imageViewSizeRatio);
    }

    CGFloat scrollViewScale = 1;
    if (imageViewSize.width < scrollViewSize.width && imageViewSize.height < scrollViewSize.height) {
        scrollViewScale = MAX(imageViewSize.width / scrollViewSize.width, imageViewSize.height / scrollViewSize.height);
    }

    self.imageView.image = self.imageToOperate;
    CGFloat width = imageViewSize.width / scrollViewScale * self.scrollView.zoomScale;
    CGFloat height = imageViewSize.height / scrollViewScale * self.scrollView.zoomScale;
    if (width < croppingSize.width) {
        height = height * croppingSize.width / width;
        width = croppingSize.width;
    }
    if (height < croppingSize.height) {
        width = width * croppingSize.height / height;
        height = croppingSize.height;
    }

    CGFloat newWidth = self.imageView.height;
    CGFloat newHeight = self.imageView.width;

    if (newWidth < width || newHeight < height) {
        newWidth = width;
        newHeight = height;
    }
    self.imageView.frame = CGRectMake(self.croppingRect.origin.x, self.croppingRect.origin.y, newWidth, newHeight);
    CGFloat minimumZoomScaleRate = MIN(newWidth / croppingSize.width, newHeight / croppingSize.height);
    self.scrollView.minimumZoomScale = self.scrollView.zoomScale / minimumZoomScaleRate;

    [self calcutaleContentSize];
}

- (void)calcutaleContentSize {
    self.scrollView.contentSize = CGSizeMake(self.scrollView.width - self.croppingRect.size.width + self.imageView.width, self.scrollView.height - self.croppingRect.size.height + self.imageView.height);
}

- (void)calcutaleContentOffset {
    CGPoint basePoint = CGPointMake(self.croppingRect.size.width / 2, self.croppingRect.size.height / 2);
    CGFloat oldScale = self.originalZoomScale;
    CGFloat newScale = self.scrollView.zoomScale;
    CGPoint oldPoint = self.originalContentOffset;
    CGPoint newPoint = CGPointMake(((oldPoint.x + basePoint.x) * newScale / oldScale) - basePoint.x, ((oldPoint.y + basePoint.y) * newScale / oldScale) - basePoint.y);

    if (newPoint.x < 0) {
        newPoint.x = 0;
    }
    if (newPoint.x > self.scrollView.contentSize.width - self.scrollView.width) {
        newPoint.x = self.scrollView.contentSize.width - self.scrollView.width;
    }
    if (newPoint.y < 0) {
        newPoint.y = 0;
    }
    if (newPoint.y > self.scrollView.contentSize.height - self.scrollView.height) {
        newPoint.y = self.scrollView.contentSize.height - self.scrollView.height;
    }
    self.scrollView.contentOffset = newPoint;
}

- (void)rotateLeft {
    CGFloat newOffsetX = self.scrollView.contentOffset.y + (self.croppingRect.size.height - self.croppingRect.size.width) / 2;
    CGFloat newOffsetY = self.scrollView.contentSize.width - self.scrollView.contentOffset.x - self.scrollView.width + (self.croppingRect.size.width - self.croppingRect.size.height) / 2;

    UIImage *image = self.imageToOperate;
    UIImage *newImage = [image imageByRotatingAnticlockwise];
    self.imageToOperate = newImage;
    [self calcutaleImageSizeAndContentSize];

    if (newOffsetX < 0) {
        newOffsetX = 0;
    }
    if (newOffsetX > self.scrollView.contentSize.width - self.scrollView.width) {
        newOffsetX = self.scrollView.contentSize.width - self.scrollView.width;
    }
    if (newOffsetY < 0) {
        newOffsetY = 0;
    }
    if (newOffsetY > self.scrollView.contentSize.height - self.scrollView.height) {
        newOffsetY = self.scrollView.contentSize.height - self.scrollView.height;
    }
    self.scrollView.contentOffset = CGPointMake(newOffsetX, newOffsetY);
}

- (void)rotateRight {
    CGFloat newOffsetX = self.scrollView.contentSize.height - self.scrollView.contentOffset.y - self.scrollView.height + (self.croppingRect.size.height - self.croppingRect.size.width) / 2;
    CGFloat newOffsetY = self.scrollView.contentOffset.x + (self.croppingRect.size.width - self.croppingRect.size.height) / 2;

    UIImage *image = self.imageToOperate;
    UIImage *newImage = [image imageByRotatingClockwise];
    self.imageToOperate = newImage;
    [self calcutaleImageSizeAndContentSize];

    if (newOffsetX < 0) {
        newOffsetX = 0;
    }
    if (newOffsetX > self.scrollView.contentSize.width - self.scrollView.width) {
        newOffsetX = self.scrollView.contentSize.width - self.scrollView.width;
    }
    if (newOffsetY < 0) {
        newOffsetY = 0;
    }
    if (newOffsetY > self.scrollView.contentSize.height - self.scrollView.height) {
        newOffsetY = self.scrollView.contentSize.height - self.scrollView.height;
    }
    self.scrollView.contentOffset = CGPointMake(newOffsetX, newOffsetY);
}

- (void)confirm {
    if ([self.delegate respondsToSelector:@selector(croppingImageViewController:didFinishCroppingWithImage:)]) {
        UIImage *image = [self croppedImage];
        [self.delegate croppingImageViewController:self didFinishCroppingWithImage:image];
    }
}

- (UIImage *)croppedImage {
    CGRect imageViewFrame = self.imageView.frame;
    CGRect rect = CGRectMake(self.scrollView.contentOffset.x - imageViewFrame.origin.x + self.croppingRect.origin.x, self.scrollView.contentOffset.y - imageViewFrame.origin.y + self.croppingRect.origin.y, self.croppingRect.size.width, self.croppingRect.size.height);
    UIImage *resizedImage = [self.imageView.image resizedImage:imageViewFrame.size];
    CGImageRef imageRef = CGImageCreateWithImageInRect(resizedImage.CGImage, rect);
    UIImage *croppedImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);

    return croppedImage;
}

- (void)cancel {
    if ([self.delegate respondsToSelector:@selector(croppingImageViewControllerDidCancel:)]) {
        [self.delegate croppingImageViewControllerDidCancel:self];
    }
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    [self calcutaleContentSize];
    [self calcutaleContentOffset];
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {
    self.originalContentOffset = scrollView.contentOffset;
    self.originalZoomScale = scrollView.zoomScale;
}

- (void)tapTwice:(UIGestureRecognizer *)gestureRecognizer {
    if (self.scrollView.zoomScale == 1.0) {
        CGPoint point = [gestureRecognizer locationInView:self.imageView];
        CGFloat newZoomScale = self.scrollView.zoomScale * self.scrollView.maximumZoomScale;
        CGSize scrollViewSize = self.scrollView.bounds.size;
        CGFloat w = scrollViewSize.width / newZoomScale;
        CGFloat h = scrollViewSize.height / newZoomScale;
        CGFloat x = point.x - (w / 2.0f);
        CGFloat y = point.y - (h / 2.0f);
        CGRect rectToZoom = CGRectMake(x, y, w, h);
        [self.scrollView zoomToRect:rectToZoom animated:YES];
    } else {
        [self.scrollView setZoomScale:1.0 animated:YES];
    }
}

@end
