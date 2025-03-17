//
//  DatabaseAccess.h
//  Dayima
//
//  Created by sunzj on 14-5-13.
//
//

#import <Foundation/Foundation.h>
#import "Database.h"

@interface DatabaseAccess : NSObject

@property (nonatomic, weak) Database *database;

- (void)checkResult:(BOOL)result;

@end
