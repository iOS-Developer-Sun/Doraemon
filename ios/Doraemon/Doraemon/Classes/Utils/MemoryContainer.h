//
//  MemoryContainer.h
//  Dayima
//
//  Created by sunzj on 16/1/20.
//
//

#import <Foundation/Foundation.h>

#define LOG_MEMORY [self logMemory]

@interface MemoryContainer : NSObject

+ (void)addObject:(id)object;
+ (NSArray *)allObjects;

@end

@interface NSObject (MemoryContainer)

- (void)logMemory;

@end
