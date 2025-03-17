//
//  DoraemonPlayerViewController.m
//  King
//
//  Created by sunzj on 16/2/6.
//  Copyright © 2016年 sunzj. All rights reserved.
//

#import "DoraemonPlayerViewController.h"
#import "DoraemonPlayerManager.h"
#import "AvatarView.h"
#import "iToast.h"
#import "PopActionSheet.h"
#import "ImagePicker.h"
#import "CroppingCircleView.h"
#import "MBProgressHUD.h"
#import "DayimaAPI.h"
#import "UserManager.h"
#import "NSDictionary+ObjectForKey.h"

@interface DoraemonPlayerViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIGestureRecognizerDelegate>

@property (nonatomic) NSInteger playerId;
@property (nonatomic) DoraemonPlayer *player;

@property (nonatomic, weak) DUITableView *tableView;
@property (nonatomic, weak) AvatarView *avartarImageView;
@property (nonatomic, weak) UITextField *nameTextField;
@property (nonatomic) NSMutableArray *cells;

@property (nonatomic) UIImage *modifiedAvartarImage;

@end

@implementation DoraemonPlayerViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        _player = [[DoraemonPlayer alloc] init];
    }
    return self;
}

- (instancetype)initWithPlayerId:(NSInteger)playerId {
    self = [super init];
    if (self) {
        _playerId = playerId;
        if (playerId == 0) {
            _player = [[DoraemonPlayer alloc] init];
        } else {
            _player = [[DoraemonPlayerManager sharedInstance] playerForId:playerId];
        }
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    self.title = @"新玩家";
    if (self.playerId != 0) {
        self.title = self.player.name;
    }

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(cancel)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"确定" style:UIBarButtonItemStylePlain target:self action:@selector(confirm)];
    self.view.backgroundColor = [UIColor whiteColor];

    DUITableView *tableView = [[DUITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    tableView.dataSource = self;
    tableView.delegate = self;
    tableView.rowHeight = 50;
    tableView.editing = YES;
    [self.view addSubview:tableView];
    self.tableView = tableView;

    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.width, 300)];
    headerView.backgroundColor = [UIColor backgroundColor];
    tableView.tableHeaderView = headerView;

    AvatarView *avartarImageView = [[AvatarView alloc] initWithFrame:CGRectMake(0, 30, 200, 200)];
    [avartarImageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAvatar)]];
    [headerView addSubview:avartarImageView];
    self.avartarImageView = avartarImageView;

    UITextField *nameTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 260, headerView.width, 40)];
    nameTextField.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    nameTextField.textAlignment = NSTextAlignmentCenter;
    nameTextField.borderStyle = UITextBorderStyleNone;
    nameTextField.placeholder = @"哆啦A梦";
    [headerView addSubview:nameTextField];
    self.nameTextField = nameTextField;

    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.width, 40)];
    tableView.tableFooterView = footerView;

    UIButton *button = [[UIButton alloc] initWithFrame:footerView.bounds];
    button.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [button setTitle:@"添加昵称" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor purpleColor] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(addAlias) forControlEvents:UIControlEventTouchUpInside];
    [footerView addSubview:button];

    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapView)];
    tapGestureRecognizer.delegate = self;
    [self.view addGestureRecognizer:tapGestureRecognizer];

    self.nameTextField.text = self.player.name;
    [self.avartarImageView setAvatarUrlString:self.player.avatarUrlString];
    self.cells = [NSMutableArray array];
    for (NSString *alias in self.player.aliases) {
        UITableViewCell *cell = [self aliasCell:alias];
        [self.cells addObject:cell];
    }
    [self.tableView reloadData];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    self.avartarImageView.center = CGPointMake(self.avartarImageView.superview.width / 2, self.avartarImageView.center.y);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)keyboardDidShow:(NSNotification *)notification {
    CGRect keyRect= [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat height = keyRect.size.height;
    self.tableView.height = self.view.height - height;
}

- (void)keyboardWillHide:(NSNotification *)notification {
    self.tableView.frame = self.tableView.superview.bounds;
}

- (UITableViewCell *)aliasCell:(NSString *)alias {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    cell.separatorInset = UIEdgeInsetsZero;
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
            cell.layoutMargins = UIEdgeInsetsZero;
        }
    }

    UITextField *aliasTextField = [[UITextField alloc] initWithFrame:cell.contentView.bounds];
    aliasTextField.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    aliasTextField.tag = 1;
    aliasTextField.borderStyle = UITextBorderStyleNone;
    aliasTextField.placeholder = @"昵称";
    aliasTextField.text = alias;
    [cell.contentView addSubview:aliasTextField];
    return cell;
}

- (void)tapAvatar {
    [self.view endEditing:YES];

    __weak __typeof(self) weakSelf = self;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Actions" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [alertController addAction:[UIAlertAction actionWithTitle:@"拍照" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf takePhoto];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"从相册选择" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf choosePhoto];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        ;
    }]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)takePhoto{
    __weak typeof(self) weakSelf = self;
    ImagePicker *imagePicker = [[ImagePicker alloc] init];
    imagePicker.sourceType = ImagePickerSourceTypeCamera;
    imagePicker.allowsEditing = YES;
    CroppingCircleView *circleView = [[CroppingCircleView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    CGFloat width = [UIScreen mainScreen].bounds.size.width - 10 * 2;
    CGFloat height = width;
    CGRect rect = CGRectMake(([UIScreen mainScreen].bounds.size.width - width) / 2, ([UIScreen mainScreen].bounds.size.height - height) / 2, width, height);
    circleView.croppingIndicatorRect = rect;
    imagePicker.croppingView = circleView;
    imagePicker.croppingRect = rect;
    [imagePicker showWithController:self completion:^(ImagePickerResult result, NSArray *assets, UIImage *image) {
        if (result == ImagePickerResultSuccess) {
            [weakSelf setAvatar:image];
        }
    }];
}

- (void)choosePhoto {
    __weak typeof(self) weakSelf = self;
    ImagePicker *imagePicker = [[ImagePicker alloc] init];
    imagePicker.sourceType = ImagePickerSourceTypePhotoLibrary;
    imagePicker.allowsEditing = YES;
    CroppingCircleView *circleView = [[CroppingCircleView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    CGFloat width = [UIScreen mainScreen].bounds.size.width - 10 * 2;
    CGFloat height = width;
    CGRect rect = CGRectMake(([UIScreen mainScreen].bounds.size.width - width) / 2, ([UIScreen mainScreen].bounds.size.height - height) / 2, width, height);
    circleView.croppingIndicatorRect = rect;
    imagePicker.croppingView = circleView;
    imagePicker.croppingRect = rect;
    [imagePicker showWithController:self completion:^(ImagePickerResult result, NSArray *assets, UIImage *image) {
        if (result == ImagePickerResultSuccess) {
            [weakSelf setAvatar:image];
        }
    }];
}

- (void)setAvatar:(UIImage *)image {
    self.modifiedAvartarImage = image;
    [self.avartarImageView setAvatarImage:image];
}

- (void)tapView {
    [self.view endEditing:YES];
}

- (void)addAlias {
    NSString *alias = self.nameTextField.text;
    [self.cells addObject:[self aliasCell:alias]];
    [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.cells.count - 1 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)confirm {
    if (self.nameTextField.text.length == 0) {
        [[[iToast makeText:@"请输入玩家的名字"] setDuration:1000] show];
        [self.nameTextField becomeFirstResponder];
        return;
    }

    [self.view endEditing:YES];

    if (self.modifiedAvartarImage) {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view.window animated:YES];
        ApiParameters *parameters = [[ApiParameters alloc] init];
        NSData *data = UIImageJPEGRepresentation(self.modifiedAvartarImage, 1);
        [parameters addFile:@"a.png" fileData:data name:@"pic[]"];
        [[UserManager sharedInstance].doraemonPlayerUser.dayimaApi dayimaUrlPath:@"calendar/update_pic" apiParameters:parameters completion:^(NSDictionary *json) {
            [hud hide:YES];
            if (json && [json[@"errno"] integerValue] == 0) {
                NSString *avatarUrlString = nil;
                NSArray *pictures = [json arrayObjectForKey:@"pic"];
                NSDictionary *picture = pictures.lastObject;
                if ([picture isKindOfClass:[NSDictionary class]]) {
                    avatarUrlString = [picture stringObjectForKey:@"pic"];
                }
                self.player.avatarUrlString = avatarUrlString;

                self.player.name = self.nameTextField.text;
                NSMutableArray *aliases = [NSMutableArray array];
                for (UITableViewCell *cell in self.cells) {
                    UITextField *aliasTextField = [cell viewWithTag:1];
                    NSString *alias = aliasTextField.text;
                    if (alias.length > 0) {
                        [aliases addObject:alias];
                    }
                }
                self.player.aliases = aliases;

                if (self.playerId == 0) {
                    [[DoraemonPlayerManager sharedInstance] addPlayer:self.player];
                } else {
                    [[DoraemonPlayerManager sharedInstance] setPlayer:self.player forId:self.playerId];
                }
                [self dismissViewControllerAnimated:YES completion:nil];
            } else {
                [[[iToast makeText:@"网络问题"] setDuration:3000] show];
            }
        }];
    } else {
        self.player.name = self.nameTextField.text;
        NSMutableArray *aliases = [NSMutableArray array];
        for (UITableViewCell *cell in self.cells) {
            UITextField *aliasTextField = [cell viewWithTag:1];
            NSString *alias = aliasTextField.text;
            if (alias.length > 0) {
                [aliases addObject:alias];
            }
        }
        self.player.aliases = aliases;

        if (self.playerId == 0) {
            [[DoraemonPlayerManager sharedInstance] addPlayer:self.player];
        } else {
            [[DoraemonPlayerManager sharedInstance] setPlayer:self.player forId:self.playerId];
        }
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

/*
DayimaAPIParams *param = [[DayimaAPIParams alloc] init];
[param addParam:self.catName withName:@"cat_name"];


dispatch_async(dispatch_get_global_queue(0, 0), ^{
    NSArray *imagePaths = [self dealImage:images];
    for (NSString *path in imagePaths) {
        [param addFileParam:path withName:@"pic[]"];
    }

    NSDictionary *json = [[DayimaAPI getInstance] api:@"update_pic" withModule:@"app" withParamFull:param];
    dispatch_async(dispatch_get_main_queue(), ^{
        [progresHud hide:YES];
        if (json && [json[@"errno"] integerValue] == 0) {
            NSString *component = @"webImage";

            NSString *cachePath = [Misc dayimaPath];
            NSString *path = [NSString stringWithFormat:@"%@/%@",cachePath,component];

            [self clearCachePath:path];


            NSArray *pics = [json arrayObjectForKey:@"pic"];
            if (pics.count > 0) {
                NSMutableArray *array = [NSMutableArray array];
                for (NSDictionary *dict in pics) {
                    [array addObject:[dict stringObjectForKey:@"pic"]];
                }
                NSDictionary *dict = @{@"pic" : array};
                NSString *str = [NSString stringWithFormat:@"set_pic('%@')", [dict JSONString]];
                [self webViewInvokeJaveScript:str completHandle:^(id  _Nullable object, NSError * _Nullable error) {

                }];
            }
        } else {
            NSString *error = DTEXT(@"网络错误");
            if (json) {
                error = json[@"errdesc"];
            }
            [Misc alert:error];
        }
    });
});
*/

- (void)cancel {
    [self.view endEditing:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.cells.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = self.cells[indexPath.row];

    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    BOOL canEdit = YES;
    return canEdit;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    BOOL canMove = YES;
    return canMove;
}


- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (editingStyle) {
        case UITableViewCellEditingStyleNone:
            break;
        case UITableViewCellEditingStyleDelete: {
            [self.cells removeObjectAtIndex:indexPath.row];
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];

            break;
        }

        default:
            break;
    }
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    if (sourceIndexPath.row == destinationIndexPath.row) {
        return;
    }

    UITableViewCell *cell = [self.cells objectAtIndex:sourceIndexPath.row];
    [self.cells removeObjectAtIndex:sourceIndexPath.row];
    [self.cells insertObject:cell atIndex:destinationIndexPath.row];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    BOOL shouldReceiveTouch = ![touch.view isKindOfClass:[UIControl class]];
    return shouldReceiveTouch;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self.nameTextField becomeFirstResponder];
}

@end
