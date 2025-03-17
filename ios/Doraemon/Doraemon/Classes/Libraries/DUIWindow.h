//
//  DUIWindow.h
//  Dayima
//
//  Created by sunzj on 14-11-11.
//
//

#import <UIKit/UIKit.h>
#import "ObjectIdentifierProtocol.h"

UIKIT_EXTERN NSString *const DUIWindowShakeNotification;
UIKIT_EXTERN NSString *const DUIWindowKeyWindowChangedNotification;
UIKIT_EXTERN NSString *const DUIWindowHiddenNotification;

UIKIT_EXTERN const UIWindowLevel DUIWindowLevelKeyboard;

UIKIT_EXTERN UIWindowLevel DUIWindowLevelLaunchImage;
UIKIT_EXTERN UIWindowLevel DUIWindowLevelAd;
UIKIT_EXTERN UIWindowLevel DUIWindowLevelPrivacyPassword;
UIKIT_EXTERN UIWindowLevel DUIWindowLevelGuide;
UIKIT_EXTERN UIWindowLevel DUIWindowLevelViewDebugger;
UIKIT_EXTERN UIWindowLevel DUIWindowLevelMemoryDebugger;
UIKIT_EXTERN UIWindowLevel DUIWindowLevelDevelopmentToolMenu;

@interface DUIWindow : UIWindow <ObjectIdentifierProtocol>

@property (nonatomic) BOOL inhibitsKey;

+ (void)switchWindow;
+ (BOOL)isTopWindow:(DUIWindow *)window;

- (void)setRootViewControllerViewDidFirstlyAppear:(void (^)(void))handler;

@end
