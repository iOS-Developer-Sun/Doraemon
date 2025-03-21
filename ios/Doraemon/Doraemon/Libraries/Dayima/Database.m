//
//  Database.m
//  Dayima-Core
//
//  Created by sunzj on 14-6-27.
//
//

#import "Database.h"
#import "FMDatabase.h"
#import "FMDatabaseAdditions.h"
#import "FMDatabaseQueue.h"

#if FMDB_SQLITE_STANDALONE
#import <sqlite3/sqlite3.h>
#else
#import <sqlite3.h>
#endif


@interface Database()

@property (nonatomic) FMDatabaseQueue *sqliteQueue;
@property (nonatomic, weak) NSThread *inDatabaseThread;
@property (nonatomic, weak) FMDatabase *databaseIn;

@end

@implementation Database

+ (instancetype)databaseWithPath:(NSString *)path
{
    return [[self alloc] initWithPath:path];
}

- (instancetype)initWithPath:(NSString *)name
{
    self = [super init];
    if (self) {
        _sqliteQueue = [FMDatabaseQueue databaseQueueWithPath:name flags:SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FILEPROTECTION_NONE];
        if (self.sqliteQueue == nil) {
            self = nil;
        }
    }
    return self;
}

- (void)dealloc
{
    [self.sqliteQueue inDatabase:^(FMDatabase *db) {
        [db closeOpenResultSets];
        [db close];
    }];
    [self.sqliteQueue close];
}

- (void)setPropertiesOfDatabase:(FMDatabase *)database
{
    database.logsErrors = YES;
}

- (void)inDatabase:(void (^)(FMDatabase *db))block
{
    @synchronized(self) {
        if (self.databaseIn) {
            FMDatabase *db = self.databaseIn;
            [self setPropertiesOfDatabase:db];
            block(db);
        } else {
            [self.sqliteQueue inDatabase:^(FMDatabase *db) {
                self.databaseIn = db;
                [self setPropertiesOfDatabase:db];
                block(db);
                self.databaseIn = nil;
            }];
        }
    }
}

- (BOOL)insert:(NSDictionary *)row intoTable:(NSString *)table withReplace:(BOOL)replace
{
    if (row == nil) {
        return NO;
    }
    NSArray *keys = [row allKeys];
    NSArray *values = [row allValues];
    NSString *keysString = [keys componentsJoinedByString:@", "];
    NSMutableString *valuesString = [NSMutableString string];

    for (NSInteger index = 0; index < values.count; index++) {
        if (index == 0) {
            [valuesString appendString:@"?"];
        } else {
            [valuesString appendString:@", ?"];
        }
    }

    NSString *sql = [NSString stringWithFormat:@"%@ into %@ (%@) values (%@)", (replace ? @"replace" : @"insert"), table, keysString, valuesString];

    __block BOOL result;
    [self inDatabase:^(FMDatabase *db) {
        result = [db executeUpdate:sql withArgumentsInArray:values];
    }];

    return result;
}

#pragma mark - public methods

#pragma mark execute

- (BOOL)executeUpdate:(NSString *)sql
{
    __block BOOL ret = NO;
    [self inDatabase:^(FMDatabase *db) {
        ret = [db executeUpdate:sql];
    }];

    return ret;
}

- (NSArray *)executeQuery:(NSString *)sql
{
    NSMutableArray *list = [NSMutableArray array];
    __block FMResultSet *rs;

    [self inDatabase:^(FMDatabase *db) {
        rs = [db executeQuery:sql];
        while ([rs next]) {
            if (rs.resultDictionary) {
                [list addObject:rs.resultDictionary];
            }
        }
        [rs close];
    }];

    return list.copy;
}

- (BOOL)executeTransaction:(BOOL (^)(void))transaction
{
    @synchronized(self) {
        __block BOOL ret = YES;
        [self inDatabase:^(FMDatabase *db) {
            ret = [db beginTransaction];
            if (ret) {
                BOOL transactionResult = transaction();
                if (transactionResult) {
                    ret = [db commit];
                } else {
                    ret = [db rollback];
                }
            }
        }];

        return ret;
    }
}


#pragma mark version

- (NSInteger)version
{
    __block NSInteger version = 0;
    [self inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"pragma user_version"];
        while ([rs next]) {
            version = [rs intForColumn:[rs columnNameForIndex:0]];
        }
        [rs close];
    }];
    return version;
}

- (void)setVersion:(NSInteger)version
{
    [self inDatabase:^(FMDatabase *db) {
        [db executeUpdate:[[NSString alloc] initWithFormat:@"pragma user_version = %d", (int)version]];
    }];
}

#pragma mark table

- (NSArray *)allTables
{
    NSMutableArray *allTables = [NSMutableArray array];
    [self inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"select * from sqlite_master where type = 'table'"];
        while ([rs next]) {
            NSString *name = [rs stringForColumn:@"tbl_name"];
            if (name != nil) {
                [allTables addObject:name];
            }
        }
        [rs close];
    }];

    return allTables.copy;
}

- (NSArray *)customTables
{
    NSMutableArray *customTables = [NSMutableArray array];
    [self inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"select * from sqlite_master where type = 'table'"];
        NSString *sysprefix = @"sqlite_";
        while ([rs next]) {
            NSString *name = [rs stringForColumn:@"tbl_name"];
            if (name != nil && ![name hasPrefix:sysprefix]) {
                [customTables addObject:name];
            }
        }
        [rs close];
    }];

    return customTables.copy;
}

- (BOOL)isTableExistent:(NSString *)tableName
{
    __block BOOL ret = NO;
    [self inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"select count(*) as 'count' from sqlite_master where type ='table' and name = ?", tableName];
        if ([rs next]) {
            NSInteger count = [rs intForColumn:@"count"];
            if (count > 0) {
                ret = YES;
            }
        }
        [rs close];
    }];
    return ret;
}

#pragma mark state

- (NSInteger)countFromTable:(NSString *)table
{
    return [self countFromTable:table withCondition:nil];
}

- (NSInteger)countFromTable:(NSString *)table withCondition:(NSString *)condition
{
    NSMutableString *sql = [NSMutableString stringWithFormat:@"select count(1) from %@", table];
    if (condition) {
        [sql appendFormat:@" %@", condition];
    }
    __block NSInteger count = 0;
    [self inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:sql];
        if ([rs next]) {
            count = [rs intForColumnIndex:0];
        }
        [rs close];
    }];
    return count;
}

#pragma mark insert delete update

- (BOOL)insert:(NSDictionary *)row intoTable:(NSString *)table
{
    return [self insert:row intoTable:table withReplace:NO];
}

- (BOOL)replace:(NSDictionary *)row intoTable:(NSString *)table
{
    return [self insert:row intoTable:table withReplace:YES];
}

- (BOOL)deleteFromTable:(NSString *)table
{
    return [self deleteFromTable:table withCondition:nil];
}

- (BOOL)deleteFromTable:(NSString *)table withCondition:(NSString *)condition
{
    NSMutableString *sql = [NSMutableString stringWithFormat:@"delete from %@", table];
    if (condition) {
        [sql appendFormat:@" %@", condition];
    }
    __block BOOL ret = NO;
    [self inDatabase:^(FMDatabase *db) {
        ret = [db executeUpdate:sql];
    }];
    return ret;
}

- (BOOL)update:(NSDictionary *)data inTable:(NSString *)table withCondition:(NSString *)condition
{
    NSMutableString *update = [NSMutableString string];
    for (id key in data) {
        if ([update length] > 0) {
            [update appendString:@", "];
        }
        id value = [data valueForKey:key];
        [update appendString:[NSString stringWithFormat:@"%@ = '%@'", key, value]];
    }
    __block BOOL ret = NO;
    NSString *sql = [NSString stringWithFormat:@"update %@ set %@ %@", table, update, condition?:@""];
    [self inDatabase:^(FMDatabase *db) {
        ret = [db executeUpdate:sql];
    }];
    return ret;
}

#pragma mark findOne

- (NSDictionary *)findOne:(NSString *)fields fromTable:(NSString *)table
{
    return [self findOne:fields fromTable:table withOrder:nil withCondition:nil];
}

- (NSDictionary *)findOne:(NSString *)fields fromTable:(NSString *)table withOrder:(NSString *)order
{
    return [self findOne:fields fromTable:table withOrder:order withCondition:nil];
}

- (NSDictionary *)findOne:(NSString *)fields fromTable:(NSString *)table withCondition:(NSString *)condition
{
    NSDictionary *one = [self findOne:fields fromTable:table withOrder:nil withCondition:condition];
    return one;
}

- (NSDictionary *)findOne:(NSString *)fields fromTable:(NSString *)table withOrder:(NSString *)order withCondition:(NSString *)condition
{
    NSArray *list = [self findAll:fields fromTable:table withStart:0 withOffset:1 withOrder:order withCondition:condition];
    if ([list count] <= 0) {
        return nil;
    }
    return list[0];
}

#pragma mark findAll

- (NSArray *)findAll:(NSString *)fields fromTable:(NSString *)table
{
    return [self findAll:fields fromTable:table withStart:0 withOffset:-1 withOrder:nil withCondition:nil];
}

- (NSArray *)findAll:(NSString *)fields fromTable:(NSString *)table withLimit:(NSInteger)limit
{
    return [self findAll:fields fromTable:table withStart:0 withOffset:limit withOrder:nil withCondition:nil];
}

- (NSArray *)findAll:(NSString *)fields fromTable:(NSString *)table withStart:(NSInteger)start withOffset:(NSInteger)offset
{
    return [self findAll:fields fromTable:table withStart:start withOffset:offset withOrder:nil withCondition:nil];
}

- (NSArray *)findAll:(NSString *)fields fromTable:(NSString *)table withOrder:(NSString *)order
{
    return [self findAll:fields fromTable:table withStart:0 withOffset:-1 withOrder:order withCondition:nil];
}

- (NSArray *)findAll:(NSString *)fields fromTable:(NSString *)table withCondition:(NSString *)condition
{
    NSArray *all = [self findAll:fields fromTable:table withStart:0 withOffset:-1 withOrder:nil withCondition:condition];
    return all;
}

- (NSArray *)findAll:(NSString *)fields fromTable:(NSString *)table withLimit:(NSInteger)limit withOrder:(NSString *)order
{
    return [self findAll:fields fromTable:table withStart:0 withOffset:limit withOrder:order withCondition:nil];
}

- (NSArray *)findAll:(NSString *)fields fromTable:(NSString *)table withStart:(NSInteger)start withOffset:(NSInteger)offset withOrder:(NSString *)order
{
    return [self findAll:fields fromTable:table withStart:start withOffset:offset withOrder:order withCondition:nil];
}

- (NSArray *)findAll:(NSString *)fields fromTable:(NSString *)table withLimit:(NSInteger)limit withCondition:(NSString *)condition
{
    NSArray *all = [self findAll:fields fromTable:table withStart:0 withOffset:limit withOrder:nil withCondition:condition];
    return all;
}

- (NSArray *)findAll:(NSString *)fields fromTable:(NSString *)table withStart:(NSInteger)start withOffset:(NSInteger)offset withCondition:(NSString *)condition
{
    NSArray *all = [self findAll:fields fromTable:table withStart:start withOffset:offset withOrder:nil withCondition:condition];
    return all;
}

- (NSArray *)findAll:(NSString *)fields fromTable:(NSString *)table withOrder:(NSString *)order withCondition:(NSString *)condition
{
    NSArray *all = [self findAll:fields fromTable:table withStart:0 withOffset:-1 withOrder:order withCondition:condition];
    return all;
}

- (NSArray *)findAll:(NSString *)fields fromTable:(NSString *)table withLimit:(NSInteger)limit withOrder:(NSString *)order withCondition:(NSString *)condition
{
    NSArray *all = [self findAll:fields fromTable:table withStart:0 withOffset:limit withOrder:order withCondition:condition];
    return all;
}

- (NSArray *)findAll:(NSString *)fields fromTable:(NSString *)table withStart:(NSInteger)start withOffset:(NSInteger)offset withOrder:(NSString *)order withCondition:(NSString *)condition
{
    NSMutableString *sql = [NSMutableString stringWithFormat:@"select %@ from %@", fields, table];
    if (condition) {
        [sql appendFormat:@" %@", condition];
    }
    if (order) {
        [sql appendFormat:@" %@", order];
    }
    if (offset >= 0) {
        [sql appendFormat:@" limit %@, %@", @(start), @(offset)];
    }

    NSMutableArray *list = [NSMutableArray array];
    [self inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:sql];
        while ([rs next]) {
            if (rs.resultDictionary) {
                [list addObject:rs.resultDictionary];
            }
        }
        [rs close];
    }];
    
    return list.copy;
}

@end
