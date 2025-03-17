//
//  DUINavigationController.h
//  Dayima
//
//  Created by sunzj on 14-6-11.
//
//

#import <UIKit/UIKit.h>
#import "ObjectIdentifierProtocol.h"

#define NAVIGATION_BAR_COLOR_CHANGED_NOTIFICATION @"NAVIGATION_BAR_COLOR_CHANGED_NOTIFICATION"

@protocol DUINavigationControllerPop <NSObject>

- (BOOL)supportsPopGuesture;

@end

@interface DUINavigationController : UINavigationController <ObjectIdentifierProtocol>

@end
