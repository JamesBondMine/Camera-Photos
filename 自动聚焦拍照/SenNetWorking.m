 //
//  SenNetWorking.m
//  SenNetWorking
//
//  Created by 八戒科技-Mr_Sen on 16/7/6.
//  Copyright © 2016年 Mr_Yangsen. All rights reserved.
//
//
#import "SenNetWorking.h"
#import "AFNetworkActivityIndicatorManager.h"
#import "AFNetworking.h"
#import "AFHTTPSessionManager.h"

#import <CommonCrypto/CommonDigest.h>

//扩展类 字符串Md5 加密
@interface NSString (md5)

+ (NSString *)SenNetWorking_md5:(NSString *)string;

@end

@implementation NSString (md5)

+ (NSString *)SenNetWorking_md5:(NSString *)string {
    if (string == nil || [string length] == 0) {
        return nil;
    }
    unsigned char digest[CC_MD5_DIGEST_LENGTH], i;
    CC_MD5([string UTF8String], (int)[string lengthOfBytesUsingEncoding:NSUTF8StringEncoding], digest);
    NSMutableString *ms = [NSMutableString string];
    
    for (i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [ms appendFormat:@"%02x", (int)(digest[i])];
    }
    
    return [ms copy];
}

@end

//基础Url
static NSString *sv_networkBaseUrl = nil;
//是否打印日志 默认否
static BOOL sv_isEnableInterfaceDebug = NO;
//公共请求头
static NSDictionary *sv_httpHeaders = nil;
//默认响应类型为JSON
static SenResponseType sv_responseType = SenResponseTypeJSON;
//默认请求类型 Nomal 普通text/html
static SenRequestType  sv_requestType  = SenRequestTypeNomalText;
//默认当前网络状态 未知
static SenNetWorkingStatus sv_networkStatus = SenNetWorkingStatusUnknown;
//储存请求的请求组
static NSMutableArray *sv_requestTasks;
//默认超时时间为30s
static NSTimeInterval overtime = 30.0f;
//默认当没网络时不加载缓存
static BOOL sv_shoulgetLocalWhenNetWorkingAbnormal = NO;
//AFNetworing 管理mananer
static AFHTTPSessionManager *sv_sharedManager = nil;
//默认缓存上限为0M时自动清除缓存（不清除）
static NSUInteger sv_maxCacheSize = 0;

@implementation SenNetWorking
#pragma mark - 设置类
+(void)autoToClearCacheWithLimitedToSize:(NSUInteger)maxSize{
    sv_maxCacheSize = maxSize;
}

//+(void)cacheData:(BOOL)shouldCache {
//  isCache = shouldCache;
//}

+(void)setBaseUrl:(NSString*)baseUrl {
    sv_networkBaseUrl = baseUrl;
}

+(NSString *)baseUrl {
    return sv_networkBaseUrl;
}

+(void)setOverTime:(NSTimeInterval)overtime {
    overtime = overtime;
}
+(void)setEnableInterfaceDebug:(BOOL)isDebug {
    sv_isEnableInterfaceDebug = isDebug;
}

+(BOOL)isDebug {
    return sv_isEnableInterfaceDebug;
}

+(void)getDataFromLocalWhenNetWorkingAbnormal:(BOOL)shouldGet {
    sv_shoulgetLocalWhenNetWorkingAbnormal = shouldGet;
}


+(void)setRequestType:(SenRequestType)requestType {
    sv_requestType = requestType;
}

+(void)setResponseType:(SenResponseType)responseType{
    sv_responseType = responseType;
}


+(void)setPublicHttpHeaders:(NSDictionary *)httpHeaders{
    sv_httpHeaders = httpHeaders;
}




#pragma mark - 请求类
+(SenURLSessionTask *)getWithUrl:(NSString *)url
                         isCache:(BOOL)isCache
                         success:(SenResponseSuccess)success
                            fail:(SenResponseFail)fail {
    return [self getWithUrl:url
                    isCache:isCache
                     params:nil
                    success:success
                       fail:fail];
}

+(SenURLSessionTask *)getWithUrl:(NSString *)url
                         isCache:(BOOL)isCache
                          params:(NSDictionary *)params
                         success:(SenResponseSuccess)success
                            fail:(SenResponseFail)fail {
    return [self getWithUrl:url
                    isCache:isCache
                     params:params
                   progress:nil
                    success:success
                       fail:fail];
}

+(SenURLSessionTask *)getWithUrl:(NSString *)url
                         isCache:(BOOL)isCache
                          params:(NSDictionary *)params
                        progress:(SenGetProgress)progress
                         success:(SenResponseSuccess)success
                            fail:(SenResponseFail)fail {
    return [self requestWithUrl:url
                        isCache:isCache
                      httpMedth:SenHttpMethodGet
                         params:params
                       progress:progress
                        success:success
                           fail:fail];
}

+(SenURLSessionTask *)postWithUrl:(NSString *)url
                          isCache:(BOOL)isCache
                           params:(NSDictionary *)params
                          success:(SenResponseSuccess)success
                             fail:(SenResponseFail)fail {
    return [self postWithUrl:url
                     isCache:isCache
                      params:params
                    progress:nil
                     success:success
                        fail:fail];
}

+(SenURLSessionTask *)postWithUrl:(NSString *)url
                          isCache:(BOOL)isCache
                           params:(NSDictionary *)params
                         progress:(SenPostProgress)progress
                          success:(SenResponseSuccess)success
                             fail:(SenResponseFail)fail {
    return [self requestWithUrl:url
                        isCache:isCache
                      httpMedth:SenHttpMethodPost
                         params:params
                       progress:progress
                        success:success
                           fail:fail];
}

+(SenURLSessionTask *)requestWithUrl:(NSString *)url
                             isCache:(BOOL)isCache
                           httpMedth:(SenHttpMethod)httpMethod
                              params:(NSDictionary *)params
                            progress:(SenDownloadProgress)progress
                             success:(SenResponseSuccess)success
                                fail:(SenResponseFail)fail {
    
    
    url = [self encodeUrl:url];
    AFHTTPSessionManager *manager = [self manager];
    
    NSString *absolute = [self absoluteUrlWithPath:url];
    
    if ([self baseUrl] == nil) {
        if ([NSURL URLWithString:url] == nil) {
            NSLog(@"URLString无效，无法生成URL。可能是URL中有中文，请尝试Encode URL");
            return nil;
        }
    } else {
        NSURL *absoluteURL = [NSURL URLWithString:absolute];
        
        if (absoluteURL == nil) {
            NSLog(@"URLString无效，无法生成URL。可能是URL中有中文，请尝试Encode URL");
            return nil;
        }
    }
    
    SenURLSessionTask *session = nil;
    
    switch (httpMethod) {
        case SenHttpMethodGet:
        {
            if (isCache) {
                if (sv_shoulgetLocalWhenNetWorkingAbnormal) {
                    if (sv_networkStatus == kSCNetworkFlagsReachable ||  sv_networkStatus == SenNetWorkingStatusUnknown ) {
                        id response = [SenNetWorking cahceResponseWithURL:absolute
                                                               parameters:params];
                        if (response) {
                            if (success) {
                                
                                [self successResponse:response callback:success isShowCache:YES];
                                if ([self isDebug]) {
                                    [self logWithSuccessResponse:response
                                                             url:absolute
                                                          params:params];
                                }
                            }
                            return nil;
                        }
                    }
                }
                
            }
            
            session = [manager GET:url parameters:params progress:^(NSProgress * _Nonnull downloadProgress) {

                if (progress) {
                    progress(downloadProgress.completedUnitCount, downloadProgress.totalUnitCount);
                }
            } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                [self successResponse:responseObject callback:success isShowCache:NO];
                
                if (isCache) {
                    [self cacheResponseObject:responseObject requestURL:absolute parameters:params];
                }
                
                [[self allTasks] removeObject:task];
                if ([self isDebug]) {
                    
                    [self logWithSuccessResponse:responseObject
                                             url:absolute
                                          params:params];
                }
                
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                [[self allTasks] removeObject:task];
                
                if ([error code] < 0 && isCache) {// 获取缓存
                    id response = [SenNetWorking cahceResponseWithURL:absolute
                                                           parameters:params];
                    if (response) {
                        if (success) {
                            [self successResponse:response callback:success isShowCache:YES];
                            if ([self isDebug]) {
                                [self logWithSuccessResponse:response
                                                         url:absolute
                                                      params:params];
                            }
                            
                        }
                    } else {
                        [self handleCallbackWithError:error fail:fail];
                        if ([self isDebug]) {
                            [self logWithFailError:error url:absolute params:params];
                        }
                        
                    }
                } else {
                    [self handleCallbackWithError:error fail:fail];
                    if ([self isDebug]) {
                        [self logWithFailError:error url:absolute params:params];
                    }
                }
            }];
            
        }
            break;
        case SenHttpMethodPost:
        {
            if (isCache ) {// 获取缓存
                if (sv_shoulgetLocalWhenNetWorkingAbnormal) {
                    if (sv_networkStatus == kSCNetworkFlagsReachable ||  sv_networkStatus == SenNetWorkingStatusUnknown ) {
                        id response = [SenNetWorking cahceResponseWithURL:absolute
                                                               parameters:params];
                        if (response) {
                            if (success) {
                                [self successResponse:response callback:success isShowCache:YES];
                                if ([self isDebug]) {
                                    [self logWithSuccessResponse:response
                                                             url:absolute
                                                          params:params];
                                }
                                
                            }
                            return nil;
                        }
                    }
                }
                
            }
            NSLog(@"%@  %@",absolute,params);
            session = [manager POST:url parameters:params progress:^(NSProgress * _Nonnull downloadProgress) {
                if (progress) {
                    progress(downloadProgress.completedUnitCount, downloadProgress.totalUnitCount);
                }
                
                
            } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
 
                
                [self successResponse:responseObject callback:success isShowCache:NO];
                
                if (isCache) {
                    [self cacheResponseObject:responseObject requestURL:absolute   parameters:params];
                }
                
                [[self allTasks] removeObject:task];
                
                if ([self isDebug]) {
                    [self logWithSuccessResponse:responseObject
                                             url:absolute
                                          params:params];
                }
                
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                [[self allTasks] removeObject:task];
                
                if ([error code] < 0 && isCache) {// 获取缓存
                    id response = [SenNetWorking cahceResponseWithURL:absolute
                                                           parameters:params];
                    
                    if (response) {
                        if (success) {
                            [self successResponse:response callback:success isShowCache:YES];
                            
                            if ([self isDebug]) {
                                [self logWithSuccessResponse:response
                                                         url:absolute
                                                      params:params];
                            }
                            
                        }
                    } else {
                        [self handleCallbackWithError:error fail:fail];
                        if ([self isDebug]) {
                            [self logWithFailError:error url:absolute params:params];
                        }
                    }
                } else {
                    [self handleCallbackWithError:error fail:fail];
                    if ([self isDebug]) {
                        [self logWithFailError:error url:absolute params:params];
                    }
                    
                }
            }];
            
        }
            break;
            
        default:
            break;
    }
    
    
    if (session) {
        [[self allTasks] addObject:session];
    }
    
    return session;
}

+(SenURLSessionTask *)uploadFileWithUrl:(NSString *)url
                          uploadingFile:(NSString *)uploadingFile
                               progress:(SenUploadProgress)progress
                                success:(SenResponseSuccess)success
                                   fail:(SenResponseFail)fail {
    if ([NSURL URLWithString:uploadingFile] == nil) {
        NSLog(@"uploadingFile无效，无法生成URL。请检查待上传文件是否存在");
        return nil;
    }
    
    NSURL *uploadURL = nil;
    if ([self baseUrl] == nil) {
        uploadURL = [NSURL URLWithString:url];
    } else {
        uploadURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", [self baseUrl], url]];
    }
    
    if (uploadURL == nil) {
        NSLog(@"URLString无效，无法生成URL。可能是URL中有中文或特殊字符，请尝试Encode URL");
        return nil;
    }
    
    AFHTTPSessionManager *manager = [self manager];
    NSURLRequest *request = [NSURLRequest requestWithURL:uploadURL];
    SenURLSessionTask *session = nil;
    
    [manager uploadTaskWithRequest:request fromFile:[NSURL URLWithString:uploadingFile] progress:^(NSProgress * _Nonnull uploadProgress) {
        if (progress) {
            progress(uploadProgress.completedUnitCount, uploadProgress.totalUnitCount);
        }
    } completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        [[self allTasks] removeObject:session];
        
        [self successResponse:responseObject callback:success isShowCache:NO];
        
        if (error) {
            [self handleCallbackWithError:error fail:fail];
            if ([self isDebug]) {
                [self logWithFailError:error url:response.URL.absoluteString params:nil];
            }
            
        } else {
            if ([self isDebug]) {
                [self logWithSuccessResponse:responseObject
                                         url:response.URL.absoluteString
                                      params:nil];
            }
        }
    }];
    
    if (session) {
        [[self allTasks] addObject:session];
    }
    
    return session;
}

+(SenURLSessionTask *)uploadWithImages:(NSArray *)images
                                   url:(NSString *)url
                                  name:(NSString *)name
                              filename:(NSString *)filename
                              mimeType:(NSString *)mimeType
                            parameters:(NSDictionary *)parameters
                              progress:(SenUploadProgress)progress
                               success:(SenResponseSuccess)success
                                  fail:(SenResponseFail)fail {
    if ([self baseUrl] == nil) {
        if ([NSURL URLWithString:url] == nil) {
            NSLog(@"URLString无效，无法生成URL。可能是URL中有中文，请尝试Encode URL");
            return nil;
        }
    } else {
        if ([NSURL URLWithString:[NSString stringWithFormat:@"%@%@", [self baseUrl], url]] == nil) {
            NSLog(@"URLString无效，无法生成URL。可能是URL中有中文，请尝试Encode URL");
            return nil;
        }
    }
    
    
    url = [self encodeUrl:url];
    NSString *absolute = [self absoluteUrlWithPath:url];
    
    AFHTTPSessionManager *manager = [self manager];
    SenURLSessionTask *session = [manager POST:url parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        
        NSString*imageMimeType=mimeType;
        NSString *imageFileName = filename;
        
        if (mimeType == nil || ![mimeType isKindOfClass:[NSString class]] || mimeType.length == 0) {
            imageMimeType = @"image/jpeg";
        }
        
        if (filename == nil || ![filename isKindOfClass:[NSString class]] || filename.length == 0) {
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateFormat = @"yyyyMMddHHmmss";
            imageFileName =[NSString stringWithFormat:@"%@.jpg",[formatter stringFromDate:[NSDate date]]] ;
        }
        NSArray*filenames=[self handleFileName:imageFileName];
        
        if (images.count==1)
        {
            NSData *imageData = UIImageJPEGRepresentation(images[0], 1);
            [formData appendPartWithFileData:imageData name:name fileName:imageFileName mimeType:imageMimeType];
        }else
        {
            for (int i=0; i<images.count; i++) {
            NSData *imageData = UIImageJPEGRepresentation(images[i], 1);
            NSString*upload_name=[NSString stringWithFormat:@"%@%d",name,i];
            NSString*upload_fileName=[NSString stringWithFormat:@"%@%d.%@",[filenames firstObject],i,[filenames lastObject]];
            // 上传图片，以文件流的格式
            [formData appendPartWithFileData:imageData name:upload_name fileName:upload_fileName mimeType:imageMimeType];
            }
            
        }
        

        
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        if (progress) {
            progress(uploadProgress.completedUnitCount, uploadProgress.totalUnitCount);
        }
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [[self allTasks] removeObject:task];
        [self successResponse:responseObject callback:success isShowCache:NO];
        if ([self isDebug]) {
            [self logWithSuccessResponse:responseObject
                                     url:absolute
                                  params:parameters];
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [[self allTasks] removeObject:task];
        
        [self handleCallbackWithError:error fail:fail];
        if ([self isDebug]) {
            [self logWithFailError:error url:absolute params:nil];
        }
        
    }];
    
    [session resume];
    if (session) {
        [[self allTasks] addObject:session];
    }
    
    return session;
}

+(SenURLSessionTask *)downloadWithUrl:(NSString *)url
                           saveToPath:(NSString *)saveToPath
                             progress:(SenDownloadProgress)progressBlock
                              success:(SenResponseSuccess)success
                              failure:(SenResponseFail)failure {
    if ([self baseUrl] == nil) {
        if ([NSURL URLWithString:url] == nil) {
            NSLog(@"URLString无效，无法生成URL。可能是URL中有中文，请尝试Encode URL");
            return nil;
        }
    } else {
        if ([NSURL URLWithString:[NSString stringWithFormat:@"%@%@", [self baseUrl], url]] == nil) {
            NSLog(@"URLString无效，无法生成URL。可能是URL中有中文，请尝试Encode URL");
            return nil;
        }
    }
    
    NSURLRequest *downloadRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    AFHTTPSessionManager *manager = [self manager];
    
    SenURLSessionTask *session = nil;
    
    session = [manager downloadTaskWithRequest:downloadRequest progress:^(NSProgress * _Nonnull downloadProgress) {
        if (progressBlock) {
            progressBlock(downloadProgress.completedUnitCount, downloadProgress.totalUnitCount);
        }
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        return [NSURL fileURLWithPath:saveToPath];
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        [[self allTasks] removeObject:session];
        
        if (error == nil) {
            if (success) {
                success(filePath.absoluteString,NO);
            }
            if ([self isDebug]) {
                SenLog(@"Download success for url %@",
                       [self absoluteUrlWithPath:url]);
            }
            
        } else {
            [self handleCallbackWithError:error fail:failure];
            if ([self isDebug]) {
                SenLog(@"Download fail for url %@, reason : %@",
                       [self absoluteUrlWithPath:url],
                       [error description]);
            }
            
        }
    }];
    
    [session resume];
    if (session) {
        [[self allTasks] addObject:session];
    }
    
    return session;
}

#pragma mark - 公共类


+(AFHTTPSessionManager *)manager {
    
  @synchronized (self) {
        // 开启转圈圈
        [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
        
        AFHTTPSessionManager *manager = nil;;
        if ([self baseUrl] != nil) {
            manager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:[self baseUrl]]];
        } else {
            manager = [AFHTTPSessionManager manager];
        }
      
        switch (sv_requestType) {
            case SenRequestTypeJSON: {
                manager.requestSerializer = [AFJSONRequestSerializer serializer];
                break;
            }
            case SenRequestTypeNomalText: {
                manager.requestSerializer = [AFHTTPRequestSerializer serializer];
                break;
            }
            default: {
                break;
            }
        }
        
        switch (sv_responseType) {
            case SenResponseTypeJSON: {
                manager.responseSerializer = [AFJSONResponseSerializer serializer];
                break;
            }
            case SenResponseTypeXML: {
                manager.responseSerializer = [AFXMLParserResponseSerializer serializer];
                break;
            }
            case SenResponseTypeData: {
                manager.responseSerializer = [AFHTTPResponseSerializer serializer];
                break;
            }
            default: {
                break;
            }
        }
        manager.requestSerializer.stringEncoding = NSUTF8StringEncoding;
        
        for (NSString *key in sv_httpHeaders.allKeys) {
            if (sv_httpHeaders[key] != nil) {
                [manager.requestSerializer setValue:sv_httpHeaders[key] forHTTPHeaderField:key];
            }
        }
      
        manager.responseSerializer.acceptableContentTypes = [NSSet setWithArray:@[@"application/json",
                                                                                  @"text/html",
                                                                                  @"text/json",
                                                                                  @"text/Nomal",
                                                                                  @"text/javascript",
                                                                                  @"text/xml",
                                                                                  @"image/*"]];
        
        manager.requestSerializer.timeoutInterval = overtime;
        
        // 设置允许同时最大并发数量，过大容易出问题
        manager.operationQueue.maxConcurrentOperationCount = 3;
        sv_sharedManager = manager;
    };
    
    if (sv_shoulgetLocalWhenNetWorkingAbnormal) {
        [self detectNetwork];
    }
    sv_sharedManager.responseSerializer = [AFHTTPResponseSerializer serializer];
    return sv_sharedManager;
}

+(void)detectNetwork {
    AFNetworkReachabilityManager *reachabilityManager = [AFNetworkReachabilityManager sharedManager];
    
    [reachabilityManager startMonitoring];
    [reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        if (status == AFNetworkReachabilityStatusNotReachable){
            sv_networkStatus = kSCNetworkFlagsReachable;
        } else if (status == AFNetworkReachabilityStatusUnknown){
            sv_networkStatus = SenNetWorkingStatusUnknown;
        } else if (status == AFNetworkReachabilityStatusReachableViaWWAN){
            sv_networkStatus = SenNetWorkingStatusReachableViaWWAN;
        } else if (status == AFNetworkReachabilityStatusReachableViaWiFi){
            sv_networkStatus = SenNetWorkingStatusReachableViaWiFi;
        }
    }];
}

+(void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 尝试清除缓存
        if (sv_maxCacheSize > 0 && [self totalCacheSize] > 1024 * 1024 * sv_maxCacheSize) {
            [self clearCaches];
        }
    });
}
static inline NSString *cachePath() {
    return [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/SenNetWorkingCaches"];
}

+(void)clearCaches {
    NSString *directoryPath = cachePath();
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:directoryPath isDirectory:nil]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:directoryPath error:&error];
        
        if (error) {
            NSLog(@"SenNetWorking 清除缓存失败: %@", error);
        } else {
            NSLog(@"SenNetWorking 清除缓存成功");
        }
    }
}

+(unsigned long long)totalCacheSize {
    NSString *directoryPath = cachePath();
    BOOL isDir = NO;
    unsigned long long total = 0;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:directoryPath isDirectory:&isDir]) {
        if (isDir) {
            NSError *error = nil;
            NSArray *array = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directoryPath error:&error];
            
            if (error == nil) {
                for (NSString *subpath in array) {
                    NSString *path = [directoryPath stringByAppendingPathComponent:subpath];
                    NSDictionary *dict = [[NSFileManager defaultManager] attributesOfItemAtPath:path
                                                                                          error:&error];
                    if (!error) {
                        total += [dict[NSFileSize] unsignedIntegerValue];
                    }
                }
            }
        }
    }
    
    return total;
}

+(NSMutableArray *)allTasks {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (sv_requestTasks == nil) {
            sv_requestTasks = [[NSMutableArray alloc] init];
        }
    });
    
    return sv_requestTasks;
}

+(void)cancelAllRequest {
    
    @synchronized(self) {
        
        [[self allTasks] enumerateObjectsUsingBlock:^(SenURLSessionTask * _Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([task isKindOfClass:[SenURLSessionTask class]]) {
                [task cancel];
            }
        }];
        [[self allTasks] removeAllObjects];
        
   };
    
    
}
+(void)cancelRequestWithURL:(NSString *)url {
    if (url == nil) {
        return;
    }
      @synchronized(self) {
        [[self allTasks] enumerateObjectsUsingBlock:^(SenURLSessionTask * _Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([task isKindOfClass:[SenURLSessionTask class]]
                && [task.currentRequest.URL.absoluteString hasSuffix:url]) {
                [task cancel];
                [[self allTasks] removeObject:task];
                return;
            }
        }];
    }
}
+(void)cancelAllRequestOnlyOneWithURL:(NSString *)url
{
    if (url == nil) {
        return;
    }
    @synchronized(self) {
        [[self allTasks] enumerateObjectsUsingBlock:^(SenURLSessionTask * _Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([task isKindOfClass:[SenURLSessionTask class]]
                && ![task.currentRequest.URL.absoluteString hasSuffix:url]) {
                [task cancel];
                [[self allTasks] removeObject:task];
                return;
            }
        }];
    }
    
    
}



// 仅对一级字典结构起作用
+(NSString *)generateGETAbsoluteURL:(NSString *)url params:(id)params {
    if (params == nil || ![params isKindOfClass:[NSDictionary class]] || [params count] == 0) {
        return url;
    }
    
    NSString *queries = @"";
    for (NSString *key in params) {
        id value = [params objectForKey:key];
        
        if ([value isKindOfClass:[NSDictionary class]]) {
            continue;
        } else if ([value isKindOfClass:[NSArray class]]) {
            continue;
        } else if ([value isKindOfClass:[NSSet class]]) {
            continue;
        } else {
            queries = [NSString stringWithFormat:@"%@%@=%@&",
                       (queries.length == 0 ? @"&" : queries),
                       key,
                       value];
        }
    }
    
    if (queries.length > 1) {
        queries = [queries substringToIndex:queries.length - 1];
    }
    
    if (([url hasPrefix:@"http://"] || [url hasPrefix:@"https://"]) && queries.length > 1) {
        if ([url rangeOfString:@"?"].location != NSNotFound
            || [url rangeOfString:@"#"].location != NSNotFound) {
            url = [NSString stringWithFormat:@"%@%@", url, queries];
        } else {
            queries = [queries substringFromIndex:1];
            url = [NSString stringWithFormat:@"%@?%@", url, queries];
        }
    }
    
    return url.length == 0 ? queries : url;
}


+(NSString *)encodeUrl:(NSString *)url {
    return [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}


+(NSArray *)handleFileName:(NSString *)filename {
    
    NSArray *array = [filename componentsSeparatedByString:@"."]; //从字符中以.分隔成数组
    if (array.count==1) {
        return @[filename,@"jpg"];
    }else
    {
        return array;
    }
}

+ (id)tryToParseData:(id)responseData {
    if ([responseData isKindOfClass:[NSData class]]) {
        // 尝试解析成JSON
        if (responseData == nil) {
            return responseData;
        } else {
            NSError *error = nil;
            NSDictionary *response = [NSJSONSerialization JSONObjectWithData:responseData
                                                                     options:NSJSONReadingMutableContainers
                                                                       error:&error];
            
            if (error != nil) {
                return responseData;
            } else {
                return response;
            }
        }
    } else {
        return responseData;
    }
}

+(void)successResponse:(id)responseData callback:(SenResponseSuccess)success isShowCache:(BOOL)isShowCache{
    if (success) {
        success([self tryToParseData:responseData],isShowCache);
    }
}

+(id)cahceResponseWithURL:(NSString *)url parameters:params {
    id cacheData = nil;
    
    if (url) {
        // Try to get datas from disk
        NSString *directoryPath = cachePath();
        NSString *absoluteURL = [self generateGETAbsoluteURL:url params:params];
        NSString *key = [NSString SenNetWorking_md5:absoluteURL];
        NSLog(@"%@",key);
        
        NSString *path = [directoryPath stringByAppendingPathComponent:key];
        
        NSData *data = [[NSFileManager defaultManager] contentsAtPath:path];
        if (data) {
            cacheData = data;
            NSLog(@"从缓存中读取数据，路径: %@\n", url);
        }
    }
    
    return cacheData;
}

+(void)cacheResponseObject:(id)responseObject  requestURL:(NSString *)url  parameters:params {
    if (url && responseObject && ![responseObject isKindOfClass:[NSNull class]]) {
        NSString *directoryPath = cachePath();
        
        NSError *error = nil;
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:directoryPath isDirectory:nil]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:directoryPath
                                      withIntermediateDirectories:YES
                                                       attributes:nil
                                                            error:&error];
            if (error) {
                NSLog(@"创建缓存目录失败: %@\n", error);
                return;
            }
        }
        NSString *absoluteURL = [self generateGETAbsoluteURL:url params:params];
        NSString *key = [NSString SenNetWorking_md5:absoluteURL];
        NSString *path = [directoryPath stringByAppendingPathComponent:key];
        NSDictionary *dict = (NSDictionary *)responseObject;
        
        NSData *data = nil;
        if ([dict isKindOfClass:[NSData class]]) {
            data = responseObject;
        } else {
            data = [NSJSONSerialization dataWithJSONObject:dict
                                                   options:NSJSONWritingPrettyPrinted
                                                     error:&error];
        }
        
        if (data && error == nil) {
            BOOL isOk = [[NSFileManager defaultManager] createFileAtPath:path contents:data attributes:nil];
            if (isOk) {
                NSLog(@"缓存成功：Request: %@\n", absoluteURL);
            } else {
                NSLog(@"缓存失败：Request: %@\n", absoluteURL);
            }
        }
    }
}

+(NSString *)absoluteUrlWithPath:(NSString *)path {
    if (path == nil || path.length == 0) {
        return @"";
    }
    
    if ([self baseUrl] == nil || [[self baseUrl] length] == 0) {
        return path;
    }
    
    NSString *absoluteUrl = path;
    
    if (![path hasPrefix:@"http://"] && ![path hasPrefix:@"https://"]) {
        if ([[self baseUrl] hasSuffix:@"/"]) {
            if ([path hasPrefix:@"/"]) {
                NSMutableString * mutablePath = [NSMutableString stringWithString:path];
                [mutablePath deleteCharactersInRange:NSMakeRange(0, 1)];
                absoluteUrl = [NSString stringWithFormat:@"%@%@",
                               [self baseUrl], mutablePath];
            } else {
                absoluteUrl = [NSString stringWithFormat:@"%@%@",[self baseUrl], path];
            }
        } else {
            if ([path hasPrefix:@"/"]) {
                absoluteUrl = [NSString stringWithFormat:@"%@%@",[self baseUrl], path];
            } else {
                absoluteUrl = [NSString stringWithFormat:@"%@/%@",
                               [self baseUrl], path];
            }
        }
    }
    
    return absoluteUrl;
}

+(void)handleCallbackWithError:(NSError *)error fail:(SenResponseFail)fail {
    if ([error code] == NSURLErrorCancelled) {
        if (fail) {
            fail(error);
        }
    } else {
        if (fail) {
            fail(error);
        }
    }
}

+(void)logWithSuccessResponse:(id)response url:(NSString *)url params:(NSDictionary *)params {
    SenLog(@"\nRequest success, URL: %@\n params:%@\n response:%@\n\n",
           [self generateGETAbsoluteURL:url params:params],
           params,
           [self tryToParseData:response]);
}

+(void)logWithFailError:(NSError *)error url:(NSString *)url params:(id)params {
    NSString *format = @" params: ";
    if (params == nil || ![params isKindOfClass:[NSDictionary class]]) {
        format = @"";
        params = @"";
    }
    
    SenLog(@"\n");
    if ([error code] == NSURLErrorCancelled) {
        SenLog(@"\nRequest was canceled mannully, URL: %@ %@%@\n\n",
               [self generateGETAbsoluteURL:url params:params],
               format,
               params);
    } else {
        SenLog(@"\nRequest error, URL: %@ %@%@\n errorInfos:%@\n\n",
               [self generateGETAbsoluteURL:url params:params],
               format,
               params,
               [error localizedDescription]);
    }
}


+(SenURLSessionTask *)checkDeviceWithUrl:(NSString *)url
                                  params:(NSDictionary *)params
                                 success:(SenResponseSuccess)success
                                 failure:(SenResponseFail)failure{
    
    url = [self encodeUrl:url];
    AFHTTPSessionManager *manager = [self manager];
    NSString *absolute = [self absoluteUrlWithPath:url];
    
    if ([self baseUrl] == nil) {
        if ([NSURL URLWithString:url] == nil) {
            NSLog(@"URLString无效，无法生成URL。可能是URL中有中文，请尝试Encode URL");
        }
    } else {
        NSURL *absoluteURL = [NSURL URLWithString:absolute];
        
        if (absoluteURL == nil) {
            NSLog(@"URLString无效，无法生成URL。可能是URL中有中文，请尝试Encode URL");
        }
    }
    
    SenURLSessionTask *session = nil;
            NSLog(@"%@  %@",url,params);
    session = [manager POST:url parameters:params progress:^(NSProgress * _Nonnull downloadProgress) {
                
       } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                
        [self successResponse:responseObject callback:success isShowCache:NO];
                [[self allTasks] removeObject:task];
                
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [[self allTasks] removeObject:task];
        [self handleCallbackWithError:error fail:failure];
    }];
    
    if (session) {
        [[self allTasks] addObject:session];
    }
    
    return session;
}

@end
