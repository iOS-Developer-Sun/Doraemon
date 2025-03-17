//
//  MemoryContainer.m
//  Dayima
//
//  Created by sunzj on 16/1/20.
//
//

#import "MemoryContainer.h"

@implementation MemoryContainer

+ (NSHashTable *)memoryContainer {
    static NSHashTable *memoryContainer = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        memoryContainer = [NSHashTable weakObjectsHashTable];
    });
    return memoryContainer;
}

+ (void)addObject:(id)object {
    [self.memoryContainer addObject:object];
}

+ (NSArray *)allObjects {
    return self.memoryContainer.allObjects;
}

@end

@implementation NSObject (MemoryContainer)

- (void)logMemory {
    [MemoryContainer addObject:self];
}

@end