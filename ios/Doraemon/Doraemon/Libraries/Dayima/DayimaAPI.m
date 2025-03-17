//
//  DayimaAPI.m
//  Dayima
//
//  Created by jason on 12-2-6.
//

#import <MobileCoreServices/MobileCoreServices.h>
#import "UserManager.h"
#import <mach/mach_time.h>
#import "AFNetworking.h"
#import "NSJSONSerialization+Extension.h"
#import "NSDictionary+ObjectForKey.h"
#import "AppManager.h"

@interface ApiFileParameter : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, copy) NSData *fileData;
@property (nonatomic, copy) NSString *filePath;

@end

@implementation ApiFileParameter

@end


@interface ApiParameters ()

@property (nonatomic) NSMutableDictionary *parameters;
@property (nonatomic) NSMutableArray *files;

@end

@implementation ApiParameters

- (instancetype)init {
    self = [super init];
    if (self) {
        _parameters = [NSMutableDictionary dictionary];
        _files = [NSMutableArray array];
    }
    return self;
}

- (void)setObject:(NSString *)object forKeyedSubscript:(NSString *)key {
    if (!key) {
        return;
    }
    self.parameters[key] = object;
}

- (NSString *)objectForKeyedSubscript:(NSString *)key {
    if (!key) {
        return nil;
    }
    return [self.parameters objectForKeyedSubscript:key];
}

- (void)addEntriesFromDictionary:(NSDictionary *)otherDictionary {
    if (!otherDictionary) {
        return;
    }
    [self.parameters addEntriesFromDictionary:otherDictionary];
}

- (void)addFile:(NSString *)fileName fileData:(NSData *)fileData name:(NSString *)name {
    ApiFileParameter *file = [[ApiFileParameter alloc] init];
    file.name = name;
    file.fileData = fileData;
    file.fileName = fileName;
    [self.files addObject:file];
}

- (void)addFile:(NSString *)fileName filePath:(NSString *)filePath name:(NSString *)name {
    ApiFileParameter *file = [[ApiFileParameter alloc] init];
    file.name = name;
    file.filePath = filePath;
    file.fileName = fileName;
    [self.files addObject:file];
}

@end

@interface DayimaAPIParams() {
	BOOL has_file;
	NSMutableArray *_array;
}

@end

@implementation DayimaAPIParams

+ (id)params {
	return [[self alloc] init];
}

- (id)init {
    self = [super init];
    if (self) {
		_array = [NSMutableArray array];
        has_file = NO;
    }
    return self;
}

- (void)addParam:(NSString *)value withName:(NSString *)name {
	[_array addObject:[NSArray arrayWithObjects:name, value, @"0", nil]];
}

- (void)addFileParam:(NSString *)filepath withName:(NSString *)name {
	has_file = YES;
	[_array addObject:[NSArray arrayWithObjects:name, filepath, @"1", nil]];
}

- (void)addFile:(NSString *)fileName dataParam:(NSData *)fileData withName:(NSString *)name;
{
    has_file = YES;
	[_array addObject:[NSArray arrayWithObjects:name, fileData, @"2", fileName, nil]];
}

- (void)addParams:(NSDictionary *)params {
    for (NSString *key in params.allKeys) {
        [self addParam:params[key] withName:key];
    };
}

- (void)clearParams {
	[_array removeAllObjects];
	has_file = NO;
}

- (BOOL)hasFileParams {
	return has_file;
}

- (NSUInteger)count {
	return [_array count];
}

- (NSArray *)objectAtIndex:(NSUInteger)index {
	return [_array objectAtIndex:index];
}

- (NSString *)description {
	NSMutableString *str = [NSMutableString string];
	[str setString:@"{\n"];
	for (NSInteger i = 0; i < [_array count]; i ++) {
		NSArray *item = [_array objectAtIndex:i];
        if ([[item objectAtIndex:2] isEqualToString:@"2"]) {
            [str appendFormat:@"\t%@ = %@(%@)  <data>", [item objectAtIndex:0], [item objectAtIndex:3], @([[item objectAtIndex:1] length])];
		} else {
            [str appendFormat:@"\t%@ = %@", [item objectAtIndex:0], [item objectAtIndex:1]];
        }
		if ([[item objectAtIndex:2] isEqualToString:@"1"]) {
			[str appendString:@" <file>"];
		}
		[str appendString:@"\n"];
	}
	[str appendString:@"}"];

    return str.copy;
}

- (NSDictionary *)params {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    for (NSInteger i = 0; i < [self count]; i ++) {
        NSArray *item = [self objectAtIndex:i];
        if ([[item objectAtIndex:2] isEqualToString:@"1"]) {
        } else if ([[item objectAtIndex:2] isEqualToString:@"2"]) {
        } else {
            params[[item objectAtIndex:0]] = [item objectAtIndex:1];
        }
    }
    return params.copy;
}


@end

@interface DayimaAPI ()

@property (nonatomic, weak) DayimaUser *user;
@property (nonatomic) NSTimeInterval serverTimeIntervalOffset;
@property (nonatomic) AFHTTPSessionManager *sessionManager; 

@end

@implementation DayimaAPI

#pragma mark - Singleton

+ (DayimaAPI *)instance {
    static DayimaAPI *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        AFHTTPSessionManager *sessionManager = [AFHTTPSessionManager manager];
        sessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
        sessionManager.requestSerializer = [AFHTTPRequestSerializer serializer];
        sessionManager.requestSerializer.timeoutInterval = 300;
        _sessionManager = sessionManager;
    }
    return self;
}

- (instancetype)initWithUser:(DayimaUser *)user {
    if (self = [self init]) {
        _user = user;

        self.delegate = user;
        self.userId = user.userId;
        self.token = user.token;
    }
    return self;
}

+ (NSDictionary *)getDeviceInfo {
    static NSDictionary *deviceInfo = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UIDevice *device = [UIDevice currentDevice];
        deviceInfo = @{@"releasever" : [device systemVersion], @"sdkver" : @"iPhone 6 Plus (Global)", @"model" : [device model]};
    });
    return deviceInfo;
}

- (NSTimeInterval)serverTimeInterval {
    return [[NSDate date] timeIntervalSince1970] + [DayimaAPI instance].serverTimeIntervalOffset;
}

- (NSString *)baseDomain
{
    NSString *baseDomain;
    baseDomain = @"https://api.yoloho.com";
    return [baseDomain stringByAppendingString:@"/v1"];
}

- (NSString *)domainWithType:(DayimaAPIDomain)domainType {
    NSString *domain = nil;
    switch (domainType) {
        case DayimaAPIDomainUic:
            domain = @"https://uicapi.yoloho.com";
            break;
        case DayimaAPIDomainForum:
            domain = @"https://forumapi.yoloho.com";
            break;
        case DayimaAPIDomainCalendar:
            domain = @"https://calapi.yoloho.com";
            break;
        case DayimaAPIDomainData:
            domain = @"http://dataapi.yoloho.com";
            break;
        case DayimaAPIDomainTips:
            domain = @"https://tipsapi.yoloho.com";
            break;
        case DayimaAPIDomainLive:
            domain = @"https://live.yoloho.com";
            break;
        case DayimaAPIDomainMall:
            domain = @"https://ibuy.meiyue.com";
            break;
        case DayimaAPIDomainDoctor:
            domain = @"https://doctorapi.yoloho.com";
            break;
        default:
            domain = [self baseDomain];
            break;
    }

    return domain;
}

- (DayimaAPIDomain)domainTypeWithModule:(NSString *)module action:(NSString *)action {
    if ([action isEqualToString:@"searchdigest"]) {
        return DayimaAPIDomainDefault;
    }
    NSArray *uicDomains = @[@"follow", @"black", @"dayima_points", @"user", @"user/remind", @"boy"];
    if ([uicDomains containsObject:module]) {
        return DayimaAPIDomainUic;
    }
    NSArray *forumDomains = @[@"group/group", @"group/my", @"group/recommendGroup", @"group/admin", @"group/transfer", @"group/topic", @"tag/topic", @"tag/tag", @"group/chat",@"vote",@"wap",@"topic"];
    if ([forumDomains containsObject:module]) {
        return DayimaAPIDomainForum;
    }
    NSArray *calendarDomains = @[@"calendar", @"sliming", @"misfit"];
    if ([calendarDomains containsObject:module]) {
        return DayimaAPIDomainCalendar;
    }
    NSArray *dataDomains = @[@"crashLog",@"appIndexAd",@"indexOpenAd"];
    if ([dataDomains containsObject:module]) {
        return DayimaAPIDomainData;
    }
    NSArray *tipsDomains = @[@"tips"];
    if ([tipsDomains containsObject:module]) {
        return DayimaAPIDomainTips;
    }
    NSArray *liveDomains = @[@"broadcast"];
    if ([liveDomains containsObject:module]) {
        return DayimaAPIDomainLive;
    }

    NSArray *mallDomains = @[@"dym", @"trade/api/checkout", @"trade/api/count"];
    if ([mallDomains containsObject:module]) {
        return DayimaAPIDomainMall;
    }

    NSArray *doctorDomains = @[@"doctor"];
    if ([doctorDomains containsObject:module]) {
        return DayimaAPIDomainDoctor;
    }

    return DayimaAPIDomainDefault;
}

- (NSArray *)errorNeedLogin
{
    return @[@10010, @10011, @10012];
}

#pragma mark - ASYNC

- (DayimaAPIDomain)domainTypeWithPath:(NSString *)path {
    NSArray *uicDomains = @[@"follow", @"black", @"dayima_points", @"user", @"user/remind", @"boy"];
    NSArray *urlCompomentArray = [path componentsSeparatedByString:@"/"];
    NSString *urlPrefix = urlCompomentArray.firstObject;
    for (NSString *uicDomain in uicDomains) {
        if ([urlPrefix isEqualToString:uicDomain]) {
            return DayimaAPIDomainUic;
        }
    }

    NSArray *forumDomains = @[@"group/group", @"group/my", @"group/recommendGroup", @"group/admin", @"group/transfer", @"group/topic", @"userRecomment", @"tag/topic", @"tag/tag", @"group/chat",@"vote",@"wap"];
    for (NSString *forumDomain in forumDomains) {
        if ([urlPrefix isEqualToString:forumDomain]) {
            return DayimaAPIDomainForum;
        }
    }

    NSArray *calendarDomains = @[@"calendar", @"sliming", @"misfit"];
    for (NSString *calendarDomain in calendarDomains) {
        if ([urlPrefix isEqualToString:calendarDomain]) {
            return DayimaAPIDomainCalendar;
        }
    }

    NSArray *dataDomains = @[@"crashLog",@"indexOpenAd",@"appIndexAd"];
    for (NSString *dataDomain in dataDomains) {
        if ([urlPrefix isEqualToString:dataDomain]) {
            return DayimaAPIDomainData;
        }
    }

    NSArray *tipsDomains = @[@"tips"];
    for (NSString *tipsDomain in tipsDomains) {
        if ([urlPrefix isEqualToString:tipsDomain]) {
            return DayimaAPIDomainTips;
        }
    }

    NSArray *liveDomains = @[@"broadcast"];
    for (NSString *liveDomain in liveDomains) {
        if ([urlPrefix isEqualToString:liveDomain]) {
            return DayimaAPIDomainLive;
        }
    }

    NSArray *mallDomains = @[@"dym", @"trade/api/checkout", @"trade/api/count"];
    for (NSString *mallDomain in mallDomains) {
        if ([urlPrefix isEqualToString:mallDomain]) {
            return DayimaAPIDomainMall;
        }
    }

    NSArray *doctorDomains = @[@"doctor"];
    for (NSString *doctorDomain in doctorDomains) {
        if ([urlPrefix isEqualToString:doctorDomain]) {
            return DayimaAPIDomainDoctor;
        }
    }

    return DayimaAPIDomainDefault;
}

- (NSString *)dayimaApiUrlStringByAddingPublicParametersWithUrlString:(NSString *)urlString {
    NSString *dayimaApiUrl = [NSString stringWithFormat:@"%@?%@", urlString, [self publicParameters]];
    return dayimaApiUrl;
}

- (NSString *)dayimaApiUrlStringWithDomain:(NSString *)domain path:(NSString *)path {
    NSString *apiDomain = domain;
    if (apiDomain == nil) {
        apiDomain = [self baseDomain];
    }

    NSString *dayimaApiUrlString = [NSString stringWithFormat:@"%@/%@", apiDomain, path];
    return dayimaApiUrlString;
}

- (NSString *)dayimaUrlStringWithPath:(NSString *)path {
    DayimaAPIDomain domainType = [self domainTypeWithPath:path];
    NSString *domain = [self domainWithType:domainType];
    NSString *dayimaUrlString = [self dayimaApiUrlStringWithDomain:domain path:path];
    NSString *urlString = [self dayimaApiUrlStringByAddingPublicParametersWithUrlString:dayimaUrlString];
    return urlString;
}

- (void)dayimaUrlPath:(NSString *)dayimaUrlPath parameters:(NSDictionary *)parameters completion:(void (^)(NSDictionary *json))completion {
    
    ApiParameters *params = [[ApiParameters alloc] init];
    [params addEntriesFromDictionary:parameters];
    
    [self dayimaUrlPath:dayimaUrlPath apiParameters:params completion:completion];
}

- (void)dayimaUrlPath:(NSString *)dayimaUrlPath apiParameters:(ApiParameters *)parameters completion:(void (^)(NSDictionary *json))completion {
    DayimaAPIDomain domainType = [self domainTypeWithPath:dayimaUrlPath];
    NSString *domain = [self domainWithType:domainType];
    NSString *dayimaUrlString = [self dayimaApiUrlStringWithDomain:domain path:dayimaUrlPath];
    
    [self dayimaUrlString:dayimaUrlString apiParameters:parameters completion:completion];
}

- (void)dayimaUrlString:(NSString *)dayimaUrlString apiParameters:(ApiParameters *)parameters completion:(void (^)(NSDictionary *json))completion {
    NSString *URL = [self dayimaApiUrlStringByAddingPublicParametersWithUrlString:dayimaUrlString];
    [self post:URL params:parameters completion:^(id responseObject, NSError *error) {
        if (completion) {
            NSDictionary *responseDictionary = nil;
            if ([responseObject isKindOfClass:[NSData class]]) {
                responseDictionary = [responseObject objectFromJSONData];
            }
            if ([responseDictionary isKindOfClass:[NSDictionary class]]) {
                completion(responseDictionary);
            } else {
                completion(nil);
            }

        }
    }];
}

- (void)urlString:(NSString *)urlString apiParameters:(ApiParameters *)parameters completion:(void (^)(NSData *data, NSError *error))completion {
    [self post:urlString params:parameters completion:^(id responseObject, NSError *error) {
        if (completion) {
            completion(responseObject, error);
        }
    }];
}

- (void)post:(NSString *)URL params:(ApiParameters *)params completion:(void(^)(id responseObject, NSError *error))completion {
    NSString *requestURL = [self urlStringWithString:URL];
    if (params.files.count > 0) {
        [self.sessionManager POST:requestURL parameters:params.parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
            NSArray *files = params.files;
            for (ApiFileParameter *item in files) {
                if (item.filePath.length > 0) {
                    if ([[NSFileManager defaultManager] fileExistsAtPath:item.filePath isDirectory:NULL]) {
                        [formData appendPartWithFileURL:[NSURL URLWithString:item.filePath] name:item.name error:nil];
                    }
                } else if (item.fileData) {
                    [formData appendPartWithFileData:item.fileData name:item.name fileName:item.fileName mimeType:[self.class contentTypeOfFilePath:item.fileName]];
                } else {
                    [formData appendPartWithFormData:[[item.fileData description] dataUsingEncoding:NSUTF8StringEncoding] name:item.name];
                }
            }
        } progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            if (completion && [responseObject isKindOfClass:[NSData class]]) {
                completion(responseObject, nil);
            }
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            if (completion) {
                completion(nil, error);
            }
        }];
        
    } else {
        [self.sessionManager POST:requestURL parameters:params.parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            if (completion && [responseObject isKindOfClass:[NSData class]]) {
                completion(responseObject, nil);
            }
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            if (completion) {
                completion(nil, error);
            }
        }];
    }
}

- (void)dayimaUrlPath:(NSString *)dayimaUrlPath protoData:(NSData *)protoData completion:(void (^)(NSData *data, NSError *error)) completion {
    DayimaAPIDomain domainType = [self domainTypeWithPath:dayimaUrlPath];
    NSString *domain = [self domainWithType:domainType];
    NSString *dayimaUrlString = [self dayimaApiUrlStringWithDomain:domain path:dayimaUrlPath];
    NSString *URL = [self dayimaApiUrlStringByAddingPublicParametersWithUrlString:dayimaUrlString];
    
    NSString *requestURL = [self urlStringWithString:URL];
    if (protoData.length > 0) {
        [self.sessionManager POST:requestURL parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
//            NSArray *files = params.files;
            [formData appendPartWithFileData:protoData name:@"protoFile" fileName:@"protoFile" mimeType:@""];
        } progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            if (completion && [responseObject isKindOfClass:[NSData class]]) {
                completion(responseObject, nil);
            }
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            if (completion) {
                completion(nil, error);
            }
        }];
        
    } else {
        [self.sessionManager POST:requestURL parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            if (completion && [responseObject isKindOfClass:[NSData class]]) {
                completion(responseObject, nil);
            }
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            if (completion) {
                completion(nil, error);
            }
        }];
    }
}


#pragma mark - Dayima API Access Methods
- (NSDictionary *)api:(NSString *)action withModule:(NSString *)module {
    return [self api:action withModule:module withParam:nil];
}

- (NSDictionary *)api:(NSString *)action withModule:(NSString *)module withParam:(NSDictionary *)params {
    DayimaAPIDomain domainType = [self domainTypeWithModule:module action:action];
    return [self apiWithDomainType:domainType withAction:action withModule:module withParam:params];
}

- (NSDictionary *)api:(NSString *)action withModule:(NSString *)module withParamFull:(DayimaAPIParams *)params {
    DayimaAPIDomain domainType = [self domainTypeWithModule:module action:action];
    return [self apiWithDomainType:domainType withAction:action withModule:module withParamFull:params];
}

- (NSDictionary *)apiWithDomainType:(DayimaAPIDomain)domainType withAction:(NSString *)action withModule:(NSString *)module withParam:(NSDictionary *)params {
    NSString *domain = [self domainWithType:domainType];
    return [self api:domain withAction:action withModule:module withParam:params];
}

- (NSDictionary *)apiWithDomainType:(DayimaAPIDomain)domainType withAction:(NSString *)action withModule:(NSString *)module withParamFull:(DayimaAPIParams *)params {
    NSString *domain = [self domainWithType:domainType];
    return [self api:domain withAction:action withModule:module withParamFull:params];
}

- (NSDictionary *)api:(NSString *)domain withAction:(NSString *)action withModule:(NSString *)module withParam:(NSDictionary *)params
{
    DayimaAPIParams *newparams = [DayimaAPIParams params];
    for (NSString *key in params) {
        [newparams addParam:[params objectForKey:key] withName:key];
    }
    return [self api:domain withAction:action withModule:module withParamFull:newparams];
}

- (NSDictionary *)api:(NSString *)domain withAction:(NSString *)action withModule:(NSString *)module withParamFull:(DayimaAPIParams *)params {
    NSString *originalUserId = self.userId ?: @"";
    NSString *originalToken = self.token ?: @"";

    NSString *apiUrl = [self apiUrl:domain withAction:action withModule:module];

    NSString *url = [self dayimaApiUrlStringByAddingPublicParametersWithUrlString:apiUrl];
    NSString *body = [self responseStringWithUrlString:url parameters:params apiUrl:apiUrl];
    NSDictionary *json = [body objectFromJSONString];
    if (![json isKindOfClass:[NSDictionary class]]) {
        json = nil;
    }

    NSNumber *errorNumber = [json integerNumberForKey:@"errno"];
    if (errorNumber == nil) {
        json = nil;
    }

    NSNumber *timeIntervalNumber = [json doubleNumberForKey:@"timestamp"];
    if (timeIntervalNumber) {
        NSTimeInterval timeInterval = timeIntervalNumber.doubleValue;
        NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
        NSTimeInterval serverTimeIntervalOffset = timeInterval - now;
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [DayimaAPI instance].serverTimeIntervalOffset = serverTimeIntervalOffset;
        });
    }

    NSInteger errorNumberValue = [errorNumber integerValue];
    if (errorNumberValue != 0) {
        if ([[self errorNeedLogin] containsObject:@(errorNumberValue)]) {
            // maybe token error
            NSString *newUserId = self.userId ?: @"";
            NSString *newToken = self.token ?: @"";
            if ([originalToken isEqualToString:newToken]) {
                // token error
                if ([self.delegate respondsToSelector:@selector(tokenError:domain:withAction:withModule:withParamFull:url:json:token:)]) {
                    json = [self.delegate tokenError:self domain:domain withAction:action withModule:module withParamFull:params url:url json:json token:originalToken];
                }
            } else {
                if ([originalUserId isEqualToString:newUserId]) {
                    return [self api:domain withAction:action withModule:module withParamFull:params];
                } else {
                    return nil;
                }
            }

        }
    }

    NSLog(@"--->dayima api error number:%@ desc:%@", [json objectForKey:@"errno"], [json objectForKey:@"errdesc"]);

    return json;
}

- (NSString *)apiUrl:(NSString *)domain withAction:(NSString *)action withModule:(NSString *)module {
    NSString *apiDomain = domain;
    if (apiDomain == nil) {
        apiDomain = [self baseDomain];
    }

    NSString *apiUrl = [NSString stringWithFormat:@"%@/%@/%@", apiDomain, module, action];
    return apiUrl;
}

- (NSString *)publicParameters {
    NSDictionary *info = [self.class getDeviceInfo];
    NSString *lngt = @"";
    NSString *latt = @"";
    NSString *reach = @"0";
    NSString *publicParameters = [NSString stringWithFormat:
                                  @"device=%@"
                                  @"&ver=%@"
                                  @"&platform=%@"
                                  @"&channel=%@"
                                  @"&model=%@"
                                  @"&sdkver=%@"
                                  @"&releasever=%@"
                                  @"&screen_width=%@"
                                  @"&screen_height=%@"
                                  @"&period=%@"
                                  @"&period_index=%@"
                                  @"&userStatus=%@"
                                  @"&lngt=%@"
                                  @"&latt=%@"
                                  @"&networkType=%@"
                                  @"&token=%@",
                                  [AppManager deviceId],
                                  @([self.class getVersion]),
                                  @"iphone",
                                  @"AppStore",
                                  [[info valueForKey:@"model"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                                  [info[@"sdkver"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                                  [info valueForKey:@"releasever"],
                                  [NSString stringWithFormat:@"%@", @([[NSNumber numberWithFloat:[UIScreen mainScreen].bounds.size.width * 2] integerValue])],
                                  [NSString stringWithFormat:@"%@", @([[NSNumber numberWithFloat:[UIScreen mainScreen].bounds.size.height * 2] integerValue])],
                                  self.period ?: @"",
                                  self.periodIndex ?: @"",
                                  self.physiologicalState ?: @"",
                                  lngt,
                                  latt,
                                  reach,
                                  [self.token?:@"" stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    return publicParameters;
}

- (NSString *)urlStringWithString:(NSString *)string {
    return string;
}

- (NSString *)dayimaUrl:(NSString *)dayimaUrl withParam:(DayimaAPIParams *)params {
    NSString *url = [self dayimaApiUrlStringByAddingPublicParametersWithUrlString:dayimaUrl];
    NSString *body = [self responseStringWithUrlString:url parameters:params apiUrl:nil];
    return body;
}

- (NSString *)url:(NSString *)url withParamFull:(DayimaAPIParams *)params {
    NSString *body = [self responseStringWithUrlString:url parameters:params apiUrl:nil];
    return body;
}

- (NSString *)userAgentString {
    static NSString *userAgentString = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        NSString *appName = [bundle objectForInfoDictionaryKey:@"CFBundleDisplayName"];
        appName = nil;
        if (!appName) {
            appName = [bundle objectForInfoDictionaryKey:@"CFBundleName"];
        }
        NSData *latin1Data = [appName dataUsingEncoding:NSUTF8StringEncoding];
        appName = [[NSString alloc] initWithData:latin1Data encoding:NSISOLatin1StringEncoding];

        NSString *appVersion = nil;
        NSString *marketingVersionNumber = [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        NSString *developmentVersionNumber = [bundle objectForInfoDictionaryKey:@"CFBundleVersion"];
        if (marketingVersionNumber && developmentVersionNumber) {
            if ([marketingVersionNumber isEqualToString:developmentVersionNumber]) {
                appVersion = marketingVersionNumber;
            } else {
                appVersion = [NSString stringWithFormat:@"%@ rv:%@",marketingVersionNumber,developmentVersionNumber];
            }
        } else {
            appVersion = (marketingVersionNumber ? marketingVersionNumber : developmentVersionNumber);
        }

        NSString *deviceName;
        NSString *OSName;
        NSString *OSVersion;
        NSString *locale = [[NSLocale currentLocale] localeIdentifier];

        UIDevice *device = [UIDevice currentDevice];
        deviceName = [device model];
        OSName = [device systemName];
        OSVersion = [device systemVersion];

        userAgentString = [NSString stringWithFormat:@"%@ %@ (%@; %@ %@; %@)", appName, appVersion, deviceName, OSName, OSVersion, locale];
    });
    
    return userAgentString;
}

- (NSString *)responseStringWithUrlString:(NSString *)urlString parameters:(DayimaAPIParams *)parameters apiUrl:(NSString *)apiUrl {
    assert ([NSThread currentThread] != [NSThread mainThread]);
    NSString *url = [self urlStringWithString:urlString];
    AFHTTPRequestSerializer *serializer = [AFHTTPRequestSerializer serializer];
    serializer.timeoutInterval = 300;
    NSString *userAgentString = [self userAgentString];
    [serializer setValue:userAgentString forHTTPHeaderField:@"User-Agent"];
    NSError *error = nil;

    NSMutableURLRequest *request;
    if ([parameters hasFileParams]) {
       
        request = [serializer multipartFormRequestWithMethod:@"POST" URLString:url parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
            for (NSInteger i = 0; i < [parameters count]; i ++) {
                NSArray *item = [parameters objectAtIndex:i];
                if ([[item objectAtIndex:2] isEqualToString:@"1"]) {
                    NSString *itemString = [item objectAtIndex:1];
                    if ([itemString isKindOfClass:[NSString class]]) {
                        if ([[NSFileManager defaultManager] fileExistsAtPath:[item objectAtIndex:1] isDirectory:NULL]) {
                            [formData appendPartWithFileURL:[NSURL fileURLWithPath:[item objectAtIndex:1]] name:[item objectAtIndex:0] error:nil];
                        }
                    }
                } else if ([[item objectAtIndex:2] isEqualToString:@"2"]) {
                    [formData appendPartWithFileData:[item objectAtIndex:1] name:[item objectAtIndex:0] fileName:[item objectAtIndex:3] mimeType:[self.class contentTypeOfFilePath:[item objectAtIndex:3]]];
                } else {
                    [formData appendPartWithFormData:[[[item objectAtIndex:1] description] dataUsingEncoding:NSUTF8StringEncoding] name:[item objectAtIndex:0]];
                }
            }
        } error:&error];
        
        if (SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(@"7.1")) {
            __block NSString *ret = nil;

            NSString *tmpFilename = [NSString stringWithFormat:@"%f",[NSDate timeIntervalSinceReferenceDate]];
            NSURL *tmpFileUrl = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:tmpFilename]];
            dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
            [serializer requestWithMultipartFormRequest:request writingStreamContentsToFile:tmpFileUrl completionHandler:^(NSError * _Nullable error) {
                NSURLSessionUploadTask *tast = [self.sessionManager uploadTaskWithRequest:request fromFile:tmpFileUrl progress:nil completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
                    if ((error == nil) && ([responseObject isKindOfClass:[NSData class]])) {
                        ret = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
                    }
                    dispatch_semaphore_signal(semaphore);
                }];
                [tast resume];

                NSLog(@"url: %@, %@", urlString, parameters);
                NSLog(@"response: %@", ret);
            }];
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            return ret;
        }

    } else {
        request = [serializer requestWithMethod:@"POST" URLString:url parameters:[parameters params] error:&error];
    }

    request.timeoutInterval = 300;

    if (error) {
        return nil;
    }

    __block NSString *ret = nil;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    NSURLSessionDataTask *task = [self.sessionManager dataTaskWithRequest:request completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        if ((error == nil) && ([responseObject isKindOfClass:[NSData class]])) {
            ret = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        }
        dispatch_semaphore_signal(semaphore);
    }];

    if (task == nil) {
        return nil;
    }

    [task resume];

    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    NSLog(@"url: %@, %@", urlString, parameters);
    NSLog(@"response: %@", ret);

    return ret;
}

+ (NSInteger)getVersion {
    NSDictionary *infoBundle = [[NSBundle mainBundle] infoDictionary];
    return [[infoBundle valueForKey:(NSString *)kCFBundleVersionKey] integerValue];
}

+ (NSString *)getVersionName {
    NSDictionary *infoBundle = [[NSBundle mainBundle] infoDictionary];
    return [infoBundle valueForKey:@"CFBundleShortVersionString"];
}

+ (NSString *)contentTypeOfFilePath:(NSString *)path {
    NSString *mimeType;
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)[path pathExtension], NULL);
    CFStringRef MIMEType = UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassMIMEType);
    CFRelease(UTI);
	if (!MIMEType) {
		mimeType = @"application/octet-stream";
	} else {
        mimeType = (__bridge NSString *)(MIMEType);
    }
    return mimeType;
}

- (NSURLSessionDownloadTask *)downloadTask:(NSString *)urlString filePath:(NSString *)filePath progress:(void (^)(NSProgress *downloadProgress)) downloadProgressBlock completionHandler:(void (^)(NSError *error))completionHandler {
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    if (request == nil) {
        return nil;
    }

    NSURL *fileUrl = [NSURL fileURLWithPath:filePath];
    if (fileUrl == nil) {
        return nil;
    }

    NSURLSessionDownloadTask *task = [self.sessionManager downloadTaskWithRequest:request progress:downloadProgressBlock destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        return fileUrl;
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        if (completionHandler) {
            completionHandler(error);
        }
    }];

    return task;
}

@end
