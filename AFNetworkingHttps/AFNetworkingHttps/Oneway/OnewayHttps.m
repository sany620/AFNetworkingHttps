//
//  OnewayHttps.m
//  AFNetworkingHttps
//
//  Created by duanmu on 2020/9/13.
//  Copyright © 2020 duanmu. All rights reserved.
//

#import "OnewayHttps.h"
#import <AFNetworking.h>

#define AppAPIBaseURL @"https://..."

@implementation OnewayHttps

+ (AFHTTPSessionManager *)sessionManager {
    static dispatch_once_t onceToken;
    static AFHTTPSessionManager *_manager = nil;
    dispatch_once(&onceToken, ^{
        _manager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:AppAPIBaseURL]];
        _manager.requestSerializer.timeoutInterval = 60.f;
        _manager.requestSerializer = [AFJSONRequestSerializer serializer];
        _manager.responseSerializer = [AFJSONResponseSerializer serializer];//设置返回数据为json
        _manager.responseSerializer.acceptableContentTypes = [NSSet setWithArray:@[@"application/json",
                                                                                          @"text/html",
                                                                                          @"text/json",
                                                                                          @"text/plain",
                                                                                          @"text/javascript",
                                                                                          @"text/xml",
                                                                                          @"image/*",
                                                                                          @"multipart/form-data"]];
        _manager.requestSerializer.stringEncoding = NSUTF8StringEncoding;
        _manager.requestSerializer.cachePolicy = NSURLRequestReloadIgnoringCacheData;//忽略缓存

        /// 服务端的证书.cer
        NSString *cerPath = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"cer"];
        NSData *caCertData = [NSData dataWithContentsOfFile:cerPath];

        AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate withPinnedCertificates:[NSSet setWithObject:caCertData]];

        /// 是否允许使用自签名证书
        securityPolicy.allowInvalidCertificates = YES;
        /// 是否需要验证域名
        securityPolicy.validatesDomainName = YES;

        _manager.securityPolicy = securityPolicy;

        /// 关闭缓存避免干扰测试
        _manager.requestSerializer.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;

        /// 客户端请求验证 重写 setSessionDidReceiveAuthenticationChallengeBlock 方法
        [_manager setSessionDidReceiveAuthenticationChallengeBlock:^NSURLSessionAuthChallengeDisposition(NSURLSession * _Nonnull session, NSURLAuthenticationChallenge * _Nonnull challenge, NSURLCredential *__autoreleasing *_credential) {

            /// 选择质询认证的处理方式
            NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
            __autoreleasing NSURLCredential *credential = nil;

            /// NSURLAuthenticationMethodServerTrust质询认证方式
            if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {

                /// 基于客户端的安全策略来决定是否信任该服务器，不信任则不响应质询。
                if ([_manager.securityPolicy evaluateServerTrust:challenge.protectionSpace.serverTrust forDomain:challenge.protectionSpace.host]) {

                    /// 创建证书
                    credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
                    /// 确认
                    if (credential) {
                        disposition = NSURLSessionAuthChallengeUseCredential;
                    } else {
                        disposition = NSURLSessionAuthChallengePerformDefaultHandling;
                    }
                } else {
                    /// 取消
                    disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
                }

            } else {
                 disposition = NSURLSessionAuthChallengePerformDefaultHandling;
            }
            return disposition;
        }];

    });
    return _manager;
}

+ (void)POST:(NSString *)Url
  parameters:(_Nullable id)parameters
     success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
     failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure {
    NSDictionary *haers =[[self class] sessionManager].requestSerializer.HTTPRequestHeaders;

    [[OnewayHttps sessionManager] POST:Url parameters:parameters headers:haers progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (success) {
            success(task, responseObject);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (failure) {
            failure(task, error);
        }
    }];
}

+ (void)GET:(NSString *)Url
 parameters:(_Nullable id)parameters
    success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
    failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure {

    [[OnewayHttps sessionManager] GET:Url parameters:parameters  headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (success) {
            success(task, responseObject);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (failure) {
            failure(task, error);
        }
    }];
}


@end
