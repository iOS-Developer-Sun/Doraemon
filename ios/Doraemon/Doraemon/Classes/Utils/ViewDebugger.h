//
//  ViewDebugger.h
//  Dayima
//
//  Created by sunzj on 15/4/28.
//
//

#import <Foundation/Foundation.h>

@interface ViewDebugger : NSObject

+ (BOOL)isDebugging;
+ (void)startDebugging;
+ (void)stopDebugging;

@end
