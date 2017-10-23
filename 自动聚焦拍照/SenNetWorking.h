//
//  SenNetWorking.h
//  SenNetWorking
//
//  Created by 八戒科技-Mr_Sen on 16/7/6.
//  Copyright © 2016年 Mr_Yangsen. All rights reserved.
//   pod 'AFNetworking', '~> 3.0.4'

#import <Foundation/Foundation.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#ifdef DEBUG
#define SenLog(s, ... ) NSLog( @"[%@ 第 %d 行] \n⬇️⬇️⬇️--- 别看我 看下面 ---⬇️⬇️⬇️%@", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
#define SenLog(s, ... )
#endif


@class NSURLSessionTask;

typedef NSURLSessionTask SenURLSessionTask;
/**
 *  @SenResponseSuccess 请求成功回调
 *  @SenResponseFail    请求失败回调
 */
typedef void(^SenResponseSuccess) (id response,BOOL isShowCache);
typedef void(^SenResponseFail) (NSError *error);


/**
 *
 *  @SenHttpMethod AFRequest类型
 */
typedef NS_ENUM(NSUInteger, SenHttpMethod) {
    SenHttpMethodGet= 1, // Get
    SenHttpMethodPost = 2 // Post
};

/**
 *
 *  @SenRequestType 请求类型
 */
typedef NS_ENUM(NSUInteger, SenRequestType) {
    
    SenRequestTypeNomalText  = 1, // 普通text/html 默认
    SenRequestTypeJSON = 2, // JSON
};

/**
 *
 *  @SenResponseType 响应类型
 */
typedef NS_ENUM(NSUInteger, SenResponseType) {
    SenResponseTypeJSON = 1, // 默认
    SenResponseTypeXML  = 2, // XML
    // 特殊情况下，一转换服务器就无法识别的，默认会尝试转换成JSON，若失败则需要自己去转换
    SenResponseTypeData = 3
};

/**
 *
 *  @SenNetWorkingStatus 当前网络类型
 */
typedef NS_ENUM(NSInteger, SenNetWorkingStatus) {
    SenNetWorkingStatusUnknown          = -1,//未知网络
    SenNetWorkingStatusNotReachable     = 0,//网络无连接
    SenNetWorkingStatusReachableViaWWAN = 1,//2，3，4G网络
    SenNetWorkingStatusReachableViaWiFi = 2,//WIFI网络
};
/**
 *
 *  下载进度
 *
 *  @param downBytes                 已下载的大小
 *  @param totalDownBytes            文件总大小
 */
typedef void(^SenDownloadProgress)(long long downBytes,long long totalDownBytes);

typedef SenDownloadProgress SenGetProgress;
typedef SenDownloadProgress SenPostProgress;

/**
 *
 *  上传进度
 *
 *  @param writtenBytes                 已上传的大小
 *  @param totalWrittenBytes            总上传大小
 */
typedef void(^SenUploadProgress)(long long writtenBytes,long long totalWrittenBytes);


@interface SenNetWorking : NSObject
#pragma mark  - 设置类方法
/**
 *
 *  设置网络请求的基础URL example:http://www.baidu.com
 *  @param baseUrl                 基础URL
 */
+(void)setBaseUrl:(NSString*)baseUrl;
+(NSString*)baseUrl;

/**
 * 设置请求超时时间，默认为30秒
 *
 *  @param overtime
 */
+(void)setOverTime:(NSTimeInterval)overtime;

/**
 *	当检查到网络异常时，是否从从本地提取数据。默认为NO。一旦设置为YES,当设置刷新缓存时，
 *  若网络异常也会从缓存中读取数据。除非本地没有数据！
 *
 *	@param shouldGet	YES/NO
 */
+(void)getDataFromLocalWhenNetWorkingAbnormal:(BOOL)shouldGet;


/**
 *
 *	获取缓存总大小/bytes
 *
 *	@return 缓存大小
 */
+(unsigned long long)totalCacheSize;

/**
 *	默认不会自动清除缓存，如果需要，可以设置自动清除缓存，并且需要指定上限。当指定上限>0M时，
 *  若缓存达到了上限值，则每次启动应用则尝试自动去清理缓存。
 *
 *	@param maxSize	缓存上限大小，单位为M（兆），默认为0，表示不清理
 */
+(void)autoToClearCacheWithLimitedToSize:(NSUInteger)maxSize;

/**
 *
 *	清除缓存
 */
+(void)clearCaches;

/**
 *
 *	是否打印日志
 */
+ (void)setEnableInterfaceDebug:(BOOL)isDebug;

/**
 *
 *  配置请求格式，默认为普通text/html 。如果要求传JSON或者PLIST，请在全局配置一下
 *
 *  @param requestType 请求格式，默认为text/html
 */
+(void)setRequestType:(SenRequestType)requestType;

/**
 *
 *  配置响应格式，默认为JSON 。
 *
 *  @param responseType 响应格式，默认为JSON，
 */
+(void)setResponseType:(SenResponseType)responseType;

/**
 *
 *  配置公共的请求头，只调用一次即可，放在应用启动的时候配置就可以了
 *
 *  @param httpHeaders 只需要将与服务器端商定的固定参数设置即可
 */
+(void)setPublicHttpHeaders:(NSDictionary *)httpHeaders;

/**
 *  取消请求
 *  cancelAllRequest 取消所有请求
 *	取消某个请求。
 *	除了摸个请求外，取消其他所有请求。
 *
 *	@param url		URL，可以是绝对URL，也可以是path（也就是不包括baseurl）
 */
+(void)cancelAllRequest;

+(void)cancelRequestWithURL:(NSString *)url;

+(void)cancelAllRequestOnlyOneWithURL:(NSString *)url;

#pragma mark  - 请求类方法
/**
 *
 *  GET请求接口，若不指定baseurl，可传完整的url
 *
 *  @param url     接口路径，如/path/getArticleList
 *  @param isCache 是否缓存
 *  @param params  接口中所需要的拼接参数，如@{"categoryid" : @(12)}
 *  @param success 接口成功请求到数据的回调
 *  @param fail    接口请求数据失败的回调
 *
 *  @return 返回的对象中有可取消请求的API
 */
+(SenURLSessionTask *)getWithUrl:(NSString *)url
                         isCache:(BOOL)isCache
                         success:(SenResponseSuccess)success
                            fail:(SenResponseFail)fail;
/**
 *
 *  GET请求接口，若不指定baseurl，可传完整的url 带params参数
 */
+(SenURLSessionTask *)getWithUrl:(NSString *)url
                         isCache:(BOOL)isCache
                          params:(NSDictionary *)params
                         success:(SenResponseSuccess)success
                            fail:(SenResponseFail)fail;
/**
 *
 *  GET请求接口，若不指定baseurl，可传完整的url 带params参数 带进度回调
 */
+(SenURLSessionTask *)getWithUrl:(NSString *)url
                         isCache:(BOOL)isCache
                          params:(NSDictionary *)params
                        progress:(SenGetProgress)progress
                         success:(SenResponseSuccess)success
                            fail:(SenResponseFail)fail;

/**
 *  POST请求接口，若不指定baseurl，可传完整的url
 *
 *  @param url     接口路径，如/path/getArticleList
 *  @param params  接口中所需的参数，如@{"categoryid" : @(12)}
 *  @param success 接口成功请求到数据的回调
 *  @param fail    接口请求数据失败的回调
 *
 *  @return 返回的对象中有可取消请求的API
 */
+(SenURLSessionTask *)postWithUrl:(NSString *)url
                          isCache:(BOOL)isCache
                           params:(NSDictionary *)params
                          success:(SenResponseSuccess)success
                             fail:(SenResponseFail)fail;

/**
 *
 *  POST请求接口，若不指定baseurl，可传完整的url  带进度回调
 */
+(SenURLSessionTask *)postWithUrl:(NSString *)url
                          isCache:(BOOL)isCache
                           params:(NSDictionary *)params
                         progress:(SenPostProgress)progress
                          success:(SenResponseSuccess)success
                             fail:(SenResponseFail)fail;
/**
 *
 *	图片上传接口，若不指定baseurl，可传完整的url 图片fileName默认格式"yyyyMMddHHmmss.jpg" 默认后缀为`jpg` mimeType 默认为`image/jpeg`
 *
 *	@param images		图片对象数组
 *	@param url			上传图片的接口路径，如/path/images/
 *	@param name			与指定的图片相关联的名称，这是由后端写接口的人指定的，如imagefiles
 *	@param filename		给图片起一个名字，默认为当前日期时间,格式为"yyyyMMddHHmmss"，后缀为`jpg`
 *	@param mimeType		默认为image/jpeg
 *	@param parameters	参数
 *	@param progress		上传进度
 *	@param success		上传成功回调
 *	@param fail			上传失败回调
 *
 *	@return
 */
+(SenURLSessionTask *)uploadWithImages:(NSArray *)images
                                   url:(NSString *)url
                                  name:(NSString *)name
                              filename:(NSString *)filename
                              mimeType:(NSString *)mimeType
                            parameters:(NSDictionary *)parameters
                              progress:(SenUploadProgress)progress
                               success:(SenResponseSuccess)success
                                  fail:(SenResponseFail)fail;

/**
 *
 *	上传文件操作
 *
 *	@param url				上传路径
 *	@param uploadingFile	待上传文件的路径
 *	@param progress			上传进度
 *	@param success			上传成功回调
 *	@param fail				上传失败回调
 *
 *	@return
 */
+(SenURLSessionTask *)uploadFileWithUrl:(NSString *)url
                          uploadingFile:(NSString *)uploadingFile
                               progress:(SenUploadProgress)progress
                                success:(SenResponseSuccess)success
                                   fail:(SenResponseFail)fail;

/**
 *
 *  下载文件
 *
 *  @param url           下载URL
 *  @param saveToPath    下载到哪个路径下
 *  @param progressBlock 下载进度
 *  @param success       下载成功后的回调
 *  @param failure       下载失败后的回调
 */
+(SenURLSessionTask *)downloadWithUrl:(NSString *)url
                           saveToPath:(NSString *)saveToPath
                             progress:(SenDownloadProgress)progressBlock
                              success:(SenResponseSuccess)success
                              failure:(SenResponseFail)failure;



/********************************************************************/
/***************************    扩展     ****************************/
/********************************************************************/

+(SenURLSessionTask *)checkDeviceWithUrl:(NSString *)url
                            params:(NSDictionary *)params
                              success:(SenResponseSuccess)success
                              failure:(SenResponseFail)failure;

/********************************************************************/
/********************************************************************/
/********************************************************************/
@end
