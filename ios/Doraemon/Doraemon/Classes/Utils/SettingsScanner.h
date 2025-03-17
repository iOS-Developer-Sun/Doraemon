//
//  SettingsScanner.h
//  Dayima
//
//  Created by sunzj on 15/3/18.
//
//

#import <Foundation/Foundation.h>

@protocol SettingsScannerItemValue <NSObject>

@required
- (id)value;
- (void)setValue:(id)value;

@end

@interface SettingsScannerItem : NSObject

@property (nonatomic) NSInteger itemId;

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *desc;
@property (nonatomic) id value;
@property (nonatomic) id defaultValue;
@property (nonatomic) id descriptionValue;
@property (nonatomic) BOOL isOptional;
@property (nonatomic) id data;

- (void)setLoader:(id (^)(void))loader;
- (void)setSaver:(void (^)(id value))saver;
- (void)setPrinter:(NSString *(^)(id value))printer;

- (NSString *)valueString;
- (NSString *)descriptionString;
- (BOOL)isFinished;
- (BOOL)hasChanged;

- (void)load;
- (void)save;

@end

@interface SettingsScanner : NSObject

- (void)addSettingsScannerItem:(SettingsScannerItem *)item;
- (void)insertSettingsScannerItem:(SettingsScannerItem *)item atIndex:(NSInteger)index;
- (void)removeSettingsScannerItem:(SettingsScannerItem *)item;
- (SettingsScannerItem *)itemAtIndex:(NSInteger)index;
- (NSInteger)count;
- (BOOL)isFinished;
- (BOOL)hasChanged;
- (void)load;
- (void)save;

@end
