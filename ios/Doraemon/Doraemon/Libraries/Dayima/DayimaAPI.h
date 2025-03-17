//
//  DayimaAPI.h
//  Dayima
//
//  Created by jason on 12-2-6.
//

#import <Foundation/Foundation.h>

@interface ApiParameters : NSObject

- (void)setObject:(NSString *)object forKeyedSubscript:(NSString *)key;
- (NSString *)objectForKeyedSubscript:(NSString *)key;
- (void)addEntriesFromDictionary:(NSDictionary *)otherDictionary;
- (void)addFile:(NSString *)fileName fileData:(NSData *)fileData name:(NSString *)name;
- (void)addFile:(NSString *)fileName filePath:(NSString *)filePath name:(NSString *)name;

@end

@interface DayimaAPIParams : NSObject

//添加一个普通字符串型参数
- (void)addParam:(NSString *)value withName:(NSString *)name;
//添加一个文件型参数，filepath为文件路径，如果该文件未找到，则忽略本次添加
- (void)addFileParam:(NSString *)filepath withName:(NSString *)name;
//添加一个文件型参数，filedata为文件内容，所有参数不能为空，fileName必须具有完整的基础名和扩展名，基础名任意，扩展名用于计算文件的类型
- (void)addFile:(NSString *)fileName dataParam:(NSData *)fileData withName:(NSString *)name;
//添加一个字典参数
- (void)addParams:(NSDictionary *)params;
//清除所有已添加的参数
- (void)clearParams;
//是否包含了文件型参数
- (BOOL)hasFileParams;
- (NSUInteger)count;
- (NSArray *)objectAtIndex:(NSUInteger)index;

+ (id)params;

@end

@class DayimaAPI;

@protocol DayimaAPIDelegate <NSObject>

- (NSDictionary *)tokenError:(DayimaAPI *)api domain:(NSString *)domain withAction:(NSString *)action withModule:(NSString *)module withParamFull:(DayimaAPIParams *)params url:(NSString *)url json:(NSDictionary *)json token:(NSString *)originalToken;

@end

typedef NS_ENUM(NSInteger, DayimaAPIDomain) {
    DayimaAPIDomainDefault,
    DayimaAPIDomainUic,
    DayimaAPIDomainForum,
    DayimaAPIDomainCalendar,
    DayimaAPIDomainData,
    DayimaAPIDomainTips,
    DayimaAPIDomainLive,
    DayimaAPIDomainMall,
    DayimaAPIDomainDoctor,
};

@interface DayimaAPI : NSObject

@property (nonatomic, copy) NSString *userId;
@property (nonatomic, copy) NSString *token;
@property (nonatomic, copy) NSString *period;
@property (nonatomic, copy) NSString *periodIndex;
@property (nonatomic, copy) NSString *physiologicalState;

@property (nonatomic, weak) id <DayimaAPIDelegate> delegate;

@property (readonly) NSTimeInterval serverTimeInterval;

/**
 *  发送Dayima的异步请求，自动添加domain与公共参数
 *
 *  @param dayimaUrlPath    请求的路径，原module/action的结合
 *  @param parameters 参数
 *  @param completion 处理结果的block
 */
- (void)dayimaUrlPath:(NSString *)dayimaUrlPath parameters:(NSDictionary *)parameters completion:(void (^)(NSDictionary *json))completion;

/**
 *  发送可带文件的Dayima的异步请求，自动添加domain与公共参数
 *
 *  @param dayimaUrlPath    请求的路径，原module/action的结合
 *  @param parameters       可带文件的参数
 *  @param completion       处理结果的block
 */
- (void)dayimaUrlPath:(NSString *)dayimaUrlPath apiParameters:(ApiParameters *)parameters completion:(void (^)(NSDictionary *json))completion;

/**
 *  发送可带文件的Dayima的异步请求，自动添加公共参数
 *
 *  @param dayimaUrlString 请求的完整路径，scheme://domain/path
 *  @param parameters      可带文件的参数
 *  @param completion      处理结果的block
 */
- (void)dayimaUrlString:(NSString *)dayimaUrlString apiParameters:(ApiParameters *)parameters completion:(void (^)(NSDictionary *json))completion;

/**
 *  发送可带文件的异步请求
 *
 *  @param urlString  请求的完整路径，scheme://host:port/path?query#fragment
 *  @param parameters 可带文件的参数
 *  @param completion 处理结果的block
 */
- (void)urlString:(NSString *)urlString apiParameters:(ApiParameters *)parameters completion:(void (^)(NSData *data, NSError *error))completion;

/**
 *  protobuf接口
 *
 *  @param dayimaUrlPath 请求的路径，原module/action的结合
 *  @param protoData     protofile的data
 *  @param completion    处理结果的block
 */
- (void)dayimaUrlPath:(NSString *)dayimaUrlPath protoData:(NSData *)protoData completion:(void (^)(NSData *data, NSError *error)) completion;



// 废弃的接口
- (NSDictionary *)api:(NSString *)action withModule:(NSString *)module;
- (NSDictionary *)api:(NSString *)action withModule:(NSString *)module withParam:(NSDictionary *)params;
- (NSDictionary *)api:(NSString *)action withModule:(NSString *)module withParamFull:(DayimaAPIParams *)params;

- (NSDictionary *)apiWithDomainType:(DayimaAPIDomain)domainType withAction:(NSString *)action withModule:(NSString *)module withParam:(NSDictionary *)params;
- (NSDictionary *)apiWithDomainType:(DayimaAPIDomain)domainType withAction:(NSString *)action withModule:(NSString *)module withParamFull:(DayimaAPIParams *)params;

- (NSDictionary *)api:(NSString *)domain withAction:(NSString *)action withModule:(NSString *)module withParam:(NSDictionary *)params;
- (NSDictionary *)api:(NSString *)domain withAction:(NSString *)action withModule:(NSString *)module withParamFull:(DayimaAPIParams *)params;

// 访问任意url
- (NSString *)dayimaUrl:(NSString *)dayimaUrl withParam:(DayimaAPIParams *)params;
- (NSString *)url:(NSString *)url withParamFull:(DayimaAPIParams *)params;

+ (NSDictionary *)getDeviceInfo;
+ (NSInteger)getVersion;
+ (NSString *)getVersionName;
+ (NSString *)contentTypeOfFilePath:(NSString *)path;

- (NSURLSessionDownloadTask *)downloadTask:(NSString *)urlString filePath:(NSString *)filePath progress:(void (^)(NSProgress *downloadProgress)) downloadProgressBlock completionHandler:(void (^)(NSError *error))completionHandler;








@end
