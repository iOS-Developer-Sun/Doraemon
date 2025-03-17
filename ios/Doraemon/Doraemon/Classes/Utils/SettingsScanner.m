//
//  SettingsScanner.m
//  Dayima
//
//  Created by sunzj on 15/3/18.
//
//

#import "SettingsScanner.h"

@interface SettingsScannerItem()

@property (nonatomic) id oldvalue;
@property (nonatomic, copy) id (^loader)(void);
@property (nonatomic, copy) void (^saver)(id value);
@property (nonatomic, copy) NSString *(^printer)(id value);

@end

@implementation SettingsScannerItem

@synthesize itemId;
@synthesize name;
@synthesize description;
@synthesize oldvalue;
@synthesize value;
@synthesize defaultValue;
@synthesize descriptionValue;
@synthesize printer;
@synthesize loader;
@synthesize saver;
@synthesize isOptional;
@synthesize data;

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.isOptional = NO;
    }
    return self;
}

- (NSString *)valueString
{
    return self.printer(self.value);
}

- (NSString *)descriptionString
{
    if (self.desc) {
        return self.desc;
    }
    return self.printer(self.descriptionValue);
}

- (BOOL)isFinished
{
    if (self.value == nil && self.isOptional == NO) {
        return NO;
    }
    return YES;
}

- (BOOL)hasChanged
{
    if ((self.oldvalue == nil) && (self.value != nil)) {
        return YES;
    }

    if ((self.oldvalue != nil) && (self.value == nil)) {
        return YES;
    }

    if ((self.oldvalue == nil) && (self.value == nil)) {
        return NO;
    }

    return ![self.oldvalue isEqual:self.value];
}

- (void)load
{
    if (self.loader) {
        self.oldvalue = loader();
        self.value = self.oldvalue;
    }
}

- (void)save
{
    if (self.saver) {
        self.saver(self.value);
    }
}

@end

@interface SettingsScanner()

@property (nonatomic) NSMutableArray *items;

@end

@implementation SettingsScanner : NSObject

@synthesize items;

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.items = [NSMutableArray array];
    }
    return self;
}

- (void)addSettingsScannerItem:(SettingsScannerItem *)item
{
    [self.items addObject:item];
}

- (void)insertSettingsScannerItem:(SettingsScannerItem *)item atIndex:(NSInteger)index
{
    if ([self.items containsObject:item]) {
        NSInteger oldIndex = [self.items indexOfObject:item];
        if (oldIndex != index) {
            [self.items exchangeObjectAtIndex:oldIndex withObjectAtIndex:index];
        }
    } else {
        [self.items insertObject:item atIndex:index];
    }
}

- (void)removeSettingsScannerItem:(SettingsScannerItem *)item
{
    [self.items removeObject:item];
}

- (SettingsScannerItem *)itemAtIndex:(NSInteger)index
{
    return self.items[index];
}

- (NSInteger)count
{
    return self.items.count;
}

- (BOOL)isFinished
{
    for (SettingsScannerItem *item in self.items.copy) {
        if (!item.isFinished) {
            return NO;
        }
    }
    return YES;
}

- (BOOL)hasChanged
{
    for (SettingsScannerItem *item in self.items.copy) {
        if (item.hasChanged) {
            return YES;
        }
    }
    return NO;
}

- (void)load
{
    for (SettingsScannerItem *item in self.items.copy) {
        [item load];
    }
}

- (void)save
{
    for (SettingsScannerItem *item in self.items.copy) {
        if (item.hasChanged) {
            [item save];
        }
    }
}


@end