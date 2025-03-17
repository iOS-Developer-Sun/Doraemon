//
//  Database.h
//  Dayima-Core
//
//  Created by sunzj on 14-6-27.
//
//

#import <Foundation/Foundation.h>
#import "FMResultSet.h"

@interface Database : NSObject

/**
 *  打开指定路径的数据库，如果不存在则创建
 *
 *  @param path 数据库路径
 *
 *  @return 数据库实例
 */
+ (instancetype)databaseWithPath:(NSString *)path;

/**
 *  获取数据库版本
 *
 *  @return 数据库版本
 */
- (NSInteger)version;

/**
 *  设置数据库版本
 *
 *  @param version 数据库版本
 */
- (void)setVersion:(NSInteger)version;

/**
 *  获取数据库表名数组
 *
 *  @return 数据库表名数组
 */
- (NSArray *)allTables;

/**
 *  获取数据库自定义表名数组
 *
 *  @return 数据库自定义表名数组
 */
- (NSArray *)customTables;

/**
 *  判断表是否存在
 *
 *  @param tableName 表名
 *
 *  @return 表是否存在
 */
- (BOOL)isTableExistent:(NSString *)tableName;

/**
 *  查询数据库表的行数
 *
 *  @param table 数据库表名
 *
 *  @return 行数
 */
- (NSInteger)countFromTable:(NSString *)table;

/**
 *  按条件查询数据库表的行数
 *
 *  @param table     数据库表名
 *  @param condition 条件 @"where ..."
 *
 *  @return 行数
 */
- (NSInteger)countFromTable:(NSString *)table withCondition:(NSString *)condition;

/**
 *  在数据库表中插入数据
 *
 *  @param row   数据
 *  @param table 表名
 *
 *  @return 操作是否成功
 */
- (BOOL)insert:(NSDictionary *)row intoTable:(NSString *)table;

/**
 *  在数据库表中替换数据，如果不存在符合条件的行，则插入数据
 *
 *  @param row   数据
 *  @param table 表名
 *
 *  @return 操作是否成功
 */
- (BOOL)replace:(NSDictionary *)row intoTable:(NSString *)table;

/**
 *  从数据库表中删除所有数据
 *
 *  @param table 表名
 *
 *  @return 操作是否成功
 */
- (BOOL)deleteFromTable:(NSString *)table;

/**
 *  按条件从数据库表中删除所有数据
 *
 *  @param table     表名
 *  @param condition 条件 @"where ..."
 *
 *  @return 操作是否成功
 */
- (BOOL)deleteFromTable:(NSString *)table withCondition:(NSString *)condition;

/**
 *  按条件在数据库表中更新数据
 *
 *  @param data      数据
 *  @param table     表名
 *  @param condition 条件 @"where ..."
 *
 *  @return 操作是否成功
 */
- (BOOL)update:(NSDictionary *)data inTable:(NSString *)table withCondition:(NSString *)condition;

/**
 *  查找一行数据库表中的字段
 *
 *  @param fields    字段名 @"*"为全部
 *  @param table     表名
 *  @param order     顺序 @"asc" / @"desc"
 *  @param condition 条件 @"where ..."
 *
 *  @return 查找到的数据
 */

- (NSDictionary *)findOne:(NSString *)fields fromTable:(NSString *)table;
- (NSDictionary *)findOne:(NSString *)fields fromTable:(NSString *)table withOrder:(NSString *)order;
- (NSDictionary *)findOne:(NSString *)fields fromTable:(NSString *)table withCondition:(NSString *)condition;
- (NSDictionary *)findOne:(NSString *)fields fromTable:(NSString *)table withOrder:(NSString *)order withCondition:(NSString *)condition;

/**
 *  查找数据库表中的字段
 *
 *  @param fields    字段名 @"*"为全部
 *  @param table     表名
 *  @param limit     限制个数 为1相当于findOne方法
 *  @param start     起始索引
 *  @param offset    个数
 *  @param order     顺序 @"asc" / @"desc"
 *  @param condition 条件 @"where ..."
 *
 *  @return 查找到的数据
 */

- (NSArray *)findAll:(NSString *)fields fromTable:(NSString *)table;
- (NSArray *)findAll:(NSString *)fields fromTable:(NSString *)table withLimit:(NSInteger)limit;
- (NSArray *)findAll:(NSString *)fields fromTable:(NSString *)table withStart:(NSInteger)start withOffset:(NSInteger)offset;
- (NSArray *)findAll:(NSString *)fields fromTable:(NSString *)table withOrder:(NSString *)order;
- (NSArray *)findAll:(NSString *)fields fromTable:(NSString *)table withCondition:(NSString *)condition;
- (NSArray *)findAll:(NSString *)fields fromTable:(NSString *)table withLimit:(NSInteger)limit withOrder:(NSString *)order;
- (NSArray *)findAll:(NSString *)fields fromTable:(NSString *)table withStart:(NSInteger)start withOffset:(NSInteger)offset withOrder:(NSString *)order;
- (NSArray *)findAll:(NSString *)fields fromTable:(NSString *)table withLimit:(NSInteger)limit withCondition:(NSString *)condition;
- (NSArray *)findAll:(NSString *)fields fromTable:(NSString *)table withStart:(NSInteger)start withOffset:(NSInteger)offset withCondition:(NSString *)condition;
- (NSArray *)findAll:(NSString *)fields fromTable:(NSString *)table withOrder:(NSString *)order withCondition:(NSString *)condition;
- (NSArray *)findAll:(NSString *)fields fromTable:(NSString *)table withLimit:(NSInteger)limit withOrder:(NSString *)order withCondition:(NSString *)condition;
- (NSArray *)findAll:(NSString *)fields fromTable:(NSString *)table withStart:(NSInteger)start withOffset:(NSInteger)offset withOrder:(NSString *)order withCondition:(NSString *)condition;

/**
 *  通过sql语句执行
 *
 *  @param sql sql语句
 */
- (BOOL)executeUpdate:(NSString *)sql;

/**
 *  通过sql语句查询
 *
 *  @param sql sql语句
 *
 *  @return 查询结果
 */
- (NSArray *)executeQuery:(NSString *)sql;

/**
 *  执行事务
 *
 *  @param 事务block, 返回YES则commit，返回NO则cancel
 *
 *  @return 查询结果
 */
- (BOOL)executeTransaction:(BOOL (^)(void))transaction;

@end
