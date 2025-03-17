//
//  ImagePickerAssetListController.h
//  Dayima
//
//  Created by sunzj on 15/4/28.
//
//

#import "ImagePickerAssetListController.h"

@class ImagePickerAssetCell;

@protocol ImagePickerAssetCellDelegate <NSObject>

- (void)imagePickerAssetCellDidSelect:(ImagePickerAssetCell *)imagePickerAssetCell;

@end

@interface ImagePickerAssetCell : UICollectionViewCell

@property (nonatomic, weak) UIImageView *imageView;
@property (nonatomic, weak) UIImageView *selectionIndicatorOn;
@property (nonatomic, weak) UIImageView *selectionIndicatorOff;

@property (nonatomic) BOOL selectionOnIndicatorHidden;
@property (nonatomic) BOOL selectionOffIndicatorHidden;
@property (nonatomic, setter = setAssetSelected:) BOOL isAssetSelected;
@property (nonatomic, weak) id <ImagePickerAssetCellDelegate> delegate;

@property (nonatomic) ALAsset *asset;
@property (nonatomic, weak) NSCache *cache;

@end

@implementation ImagePickerAssetCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.contentView.bounds];
        imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        [self.contentView addSubview:imageView];
        self.contentView.clipsToBounds = YES;
        _imageView = imageView;

        UIImageView *selectionIndicatorOn = [[UIImageView alloc] initWithFrame:CGRectMake(self.contentView.bounds.size.width - 4 - 25, 4, 25, 25)];
        selectionIndicatorOn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        selectionIndicatorOn.backgroundColor = [UIColor clearColor];
        selectionIndicatorOn.image = [UIImage imageNamed:@"forum_icon_pressed_choice.png"];
        [self.contentView addSubview:selectionIndicatorOn];
        _selectionIndicatorOn = selectionIndicatorOn;

        UIImageView *selectionIndicatorOff = [[UIImageView alloc] initWithFrame:CGRectMake(self.contentView.bounds.size.width - 4 - 25, 4, 25, 25)];
        selectionIndicatorOff.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        selectionIndicatorOff.backgroundColor = [UIColor clearColor];
        selectionIndicatorOff.image = [UIImage imageNamed:@"forum_icon_normal_choice.png"];
        [self.contentView addSubview:selectionIndicatorOff];
        _selectionIndicatorOff = selectionIndicatorOff;

        imageView.userInteractionEnabled = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap)];
        [imageView addGestureRecognizer:tap];
    }
    return self;
}

- (void)tap {
    if ([self.delegate respondsToSelector:@selector(imagePickerAssetCellDidSelect:)]) {
        [self.delegate imagePickerAssetCellDidSelect:self];
    }
}

- (void)setSelectionOnIndicatorHidden:(BOOL)selectionOnIndicatorHidden {
    _selectionOnIndicatorHidden = selectionOnIndicatorHidden;
    [self refreshIndicator];
}

- (void)setSelectionOffIndicatorHidden:(BOOL)selectionOffIndicatorHidden {
    _selectionOffIndicatorHidden = selectionOffIndicatorHidden;
    [self refreshIndicator];
}

- (void)setAssetSelected:(BOOL)selected {
    _isAssetSelected = selected;
    [self refreshIndicator];
}

- (void)setAsset:(ALAsset *)asset {
    if (_asset != asset) {
        _asset = asset;
        NSURL *url = [asset valueForProperty:ALAssetPropertyAssetURL];
        NSString *key = url.absoluteString;
        UIImage *image = [self.cache objectForKey:key];
        if (image) {
            self.imageView.image = image;
        } else {
            __weak typeof(self) weakSelf = self;
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                UIImage *aspectRatioThumbnail = [UIImage imageWithCGImage:asset.aspectRatioThumbnail];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf.cache setObject:aspectRatioThumbnail forKey:key];
                    if (weakSelf.asset == asset) {
                        weakSelf.imageView.image = aspectRatioThumbnail;
                    }
                });
            });
        }
    }
}

- (void)refreshIndicator {
    self.selectionIndicatorOn.hidden = YES;
    self.selectionIndicatorOff.hidden = YES;
    if (self.isAssetSelected) {
        self.selectionIndicatorOn.hidden = self.selectionOnIndicatorHidden;
    } else {
        self.selectionIndicatorOff.hidden = self.selectionOffIndicatorHidden;
    }
}

@end


@interface ImagePickerAssetListControllerCollectionViewLayout : UICollectionViewFlowLayout

@end
@implementation ImagePickerAssetListControllerCollectionViewLayout

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    return YES;
}

@end

@interface ImagePickerAssetListController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, ImagePickerAssetCellDelegate>

@property (nonatomic, weak) UICollectionView *collectionView;
@property (nonatomic, weak) UIView *countView;
@property (nonatomic, weak) UILabel *countLabel;
@property (nonatomic, weak) UIButton *confirmButton;
@property (nonatomic) NSCache *cache;

// Used for iOS6
@property (nonatomic) BOOL isNeedScroll;
@property (nonatomic) NSInteger indexToScroll;
@property (nonatomic) BOOL animated;

@end

@implementation ImagePickerAssetListController

- (instancetype)init {
    self = [super init];
    if (self) {
        _cache = [[NSCache alloc] init];
        self.cache.countLimit = 100;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(cancel)];

    NSInteger num = 4;
    CGFloat gap = 4;
    ImagePickerAssetListControllerCollectionViewLayout *layout = [[ImagePickerAssetListControllerCollectionViewLayout alloc] init];
    layout.itemSize = CGSizeMake(([UIScreen mainScreen].bounds.size.width - (2 * gap + (num - 1) * gap)) / num, ([UIScreen mainScreen].bounds.size.width - (2 * gap + (num - 1) * gap)) / num);
    layout.minimumLineSpacing = gap;
    layout.minimumInteritemSpacing = gap;
    layout.sectionInset = UIEdgeInsetsMake(gap, gap, gap, gap);
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:layout];
    collectionView.delegate = self;
    collectionView.dataSource = self;
    collectionView.backgroundColor = [UIColor clearColor];
    collectionView.allowsSelection = NO;
    [collectionView registerClass:[ImagePickerAssetCell class] forCellWithReuseIdentifier:@"ImagePickerAssetListCollectionViewCellIdentifier"];
    [self.view addSubview:collectionView];
    self.collectionView = collectionView;

    UIView *countView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.height - 45, self.view.width, 45)];
    countView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    countView.backgroundColor = HEXCOLOR(0xfafafaff);
    [self.view addSubview:countView];
    self.countView = countView;

    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, countView.width, 1 / [UIScreen mainScreen].scale)];
    lineView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    lineView.backgroundColor = HEXCOLOR(0xbfbfbfff);
    [countView addSubview:lineView];

    UIButton *confirmButton = [UIButton buttonWithType:UIButtonTypeCustom];
    confirmButton.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin;
    confirmButton.titleLabel.font = [UIFont systemFontOfSize:18];
    [confirmButton setTitleColor:HEXCOLOR(0xff8698ff) forState:UIControlStateNormal];
    [confirmButton setTitleColor:HEXCOLOR(0xff86987f) forState:UIControlStateDisabled];
    [confirmButton setTitle:DTEXT(@"完成") forState:UIControlStateNormal];
    CGFloat confirmButtonWidth = 58;
    confirmButton.frame = CGRectMake(countView.width - confirmButtonWidth, 0, confirmButtonWidth, countView.height);
    [confirmButton addTarget:self action:@selector(confirm) forControlEvents:UIControlEventTouchUpInside];
    [countView addSubview:confirmButton];
    self.confirmButton = confirmButton;

    UILabel *countLabel = [[UILabel alloc] initWithFrame:CGRectMake(countView.width - 75, (countView.height - 22) / 2, 22, 22)];
    countLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    countLabel.backgroundColor = HEXCOLOR(0xff8698ff);
    countLabel.textColor = [UIColor whiteColor];
    countLabel.font = [UIFont systemFontOfSize:16];
    countLabel.layer.cornerRadius = countLabel.height / 2;
    countLabel.textAlignment = NSTextAlignmentCenter;
    countLabel.layer.masksToBounds = YES;
    [countView addSubview:countLabel];
    self.countLabel = countLabel;

    countLabel.hidden = self.countLabelHidden;
    countView.hidden = self.countViewHidden;
    countLabel.text = @(self.selectedCount).stringValue;
    confirmButton.enabled = (self.selectedCount > 0);
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    self.collectionView.width = self.view.width;
    self.collectionView.height = self.view.height - (self.countView.hidden ? 0 : self.countView.height);

    if (self.isNeedScroll) {
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:self.indexToScroll inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally | UICollectionViewScrollPositionCenteredVertically animated:self.animated];
        self.isNeedScroll = NO;
    }
}

- (void)setCountViewHidden:(BOOL)countViewHidden {
    _countViewHidden = countViewHidden;
    self.countView.hidden = countViewHidden;
}

- (void)setCountLabelHidden:(BOOL)countLabelHidden {
    _countLabelHidden = countLabelHidden;
    self.countLabel.hidden = countLabelHidden;
}

- (void)setSelectedCount:(NSInteger)selectedCount {
    _selectedCount = selectedCount;
    self.countLabel.text = @(selectedCount).stringValue;

    self.confirmButton.enabled = (selectedCount > 0);
}
- (void)setScrollToIndex:(NSInteger)index animated:(BOOL)animated {
    self.isNeedScroll = YES;
    self.indexToScroll = index;
    self.animated = animated;
}

- (void)confirm {
    if ([self.delegate respondsToSelector:@selector(assetListControllerDidConfirm:)]) {
        [self.delegate assetListControllerDidConfirm:self];
    }
}

- (void)cancel {
    if ([self.delegate respondsToSelector:@selector(assetListControllerDidCancel:)]) {
        [self.delegate assetListControllerDidCancel:self];
    }
}

- (void)reload {
    [self.collectionView reloadData];
}

- (void)scrollToIndex:(NSInteger)index animated:(BOOL)animated {
    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally | UICollectionViewScrollPositionCenteredVertically animated:animated];
}

- (void)reloadItemAtIndex:(NSInteger)index {
    [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:index inSection:0]]];
}

- (void)imagePickerAssetCellDidSelect:(ImagePickerAssetCell *)imagePickerAssetCell {
    if ([self.delegate respondsToSelector:@selector(assetListController:didSelectAssetAtIndex:)]) {
        [self.delegate assetListController:self didSelectAssetAtIndex:imagePickerAssetCell.tag];
    }
}

#pragma mark - UICollectionViewDataSource & UICollectionViewDelegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSInteger number = 0;
    if ([self.delegate respondsToSelector:@selector(assetListControllerNumberOfAssets:)]) {
        number = [self.delegate assetListControllerNumberOfAssets:self];
    }
    return number;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ImagePickerAssetCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ImagePickerAssetListCollectionViewCellIdentifier" forIndexPath:indexPath];
    ALAsset *asset = nil;
    BOOL isAssetSelected = NO;
    if ([self.delegate respondsToSelector:@selector(assetListController:assetAtIndex:)]) {
        asset = [self.delegate assetListController:self assetAtIndex:indexPath.item];
    }

    if ([self.delegate respondsToSelector:@selector(assetListController:isAssetSelectedAtIndex:)]) {
        isAssetSelected = [self.delegate assetListController:self isAssetSelectedAtIndex:indexPath.item];
    }

    cell.delegate = self;
    cell.cache = self.cache;
    cell.asset = asset;
    cell.selectionOnIndicatorHidden = self.selectionOnIndicatorHidden;
    cell.selectionOffIndicatorHidden = self.selectionOffIndicatorHidden;
    cell.assetSelected = isAssetSelected;
    cell.tag = indexPath.item;

    return cell;
}

@end
