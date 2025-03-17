//
//  ImagePickerGroupListController.m
//  Dayima
//
//  Created by sunzj on 15/4/28.
//
//

#import "ImagePickerGroupListController.h"

@interface ImagePickerGroupCell : UITableViewCell

@end

@implementation ImagePickerGroupCell

- (void)layoutSubviews {
    [super layoutSubviews];

    if (self.imageView.image) {
        self.imageView.left = 0;
        self.imageView.bounds = CGRectInset(self.imageView.bounds, 5, 5);
        self.textLabel.left = self.imageView.width + 15;
        self.detailTextLabel.left = self.textLabel.left;
    } else {
        self.textLabel.left = 15;
        self.detailTextLabel.left = self.textLabel.left;
    }
}

@end

@interface ImagePickerGroupListController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) UITableView *tableView;

@end

@implementation ImagePickerGroupListController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = DTEXT(@"相册");
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(cancel)];

    UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    tableView.dataSource = self;
    tableView.delegate = self;
    [self.view addSubview:tableView];
    self.tableView = tableView;
    if ([tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        tableView.separatorInset = UIEdgeInsetsMake(0, 5, 0, 5);
    }
    if ([tableView respondsToSelector:@selector(layoutMargins)]) {
        tableView.layoutMargins = UIEdgeInsetsZero;
    }
    tableView.tableFooterView = [[UIView alloc] init];
}

- (void)reload {
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger number = 0;
    if ([self.delegate respondsToSelector:@selector(groupListControllerNumberOfAlbums:)]) {
        number = [self.delegate groupListControllerNumberOfAlbums:self];
    }
    return number;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 80;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *idetifier = @"groupIdentifier";

    ALAssetsGroup *group = nil;
    if ([self.delegate respondsToSelector:@selector(groupListController:groupAtIndex:)]) {
        group = [self.delegate groupListController:self groupAtIndex:indexPath.row];
    }

    ImagePickerGroupCell *cell = [tableView dequeueReusableCellWithIdentifier:idetifier];
    if (!cell) {
        cell = [[ImagePickerGroupCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:idetifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        if ([cell respondsToSelector:@selector(layoutMargins)]) {
            cell.layoutMargins = UIEdgeInsetsZero;
        }
    }

    cell.textLabel.text = [group valueForProperty:ALAssetsGroupPropertyName];
    if (group.posterImage) {
        cell.imageView.image = [UIImage imageWithCGImage:group.posterImage];
    }
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@张", @(group.numberOfAssets)];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.delegate respondsToSelector:@selector(groupListController:didSelectGroupAtIndex:)]) {
        [self.delegate groupListController:self didSelectGroupAtIndex:indexPath.row];
    }
}

- (void)cancel {
    if ([self.delegate respondsToSelector:@selector(groupListControllerDidCancel:)]) {
        [self.delegate groupListControllerDidCancel:self];
    }
}

@end

