//
//  DatabaseAccess.m
//  Dayima
//
//  Created by sunzj on 14-5-13.
//
//

#import "DatabaseAccess.h"

@implementation DatabaseAccess

- (void)checkResult:(BOOL)result {
    if (!result && self.database) {
        NSLog(@"database failure\n%@", [NSThread callStackSymbols]);
    }
}

@end
