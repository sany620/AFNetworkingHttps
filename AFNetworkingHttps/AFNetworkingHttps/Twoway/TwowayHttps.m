//
//  TwowayHttps.m
//  AFNetworkingHttps
//
//  Created by duanmu on 2020/9/13.
//  Copyright © 2020 duanmu. All rights reserved.
//

#import "TwowayHttps.h"
#import <AFNetworking.h>

#define AppAPIBaseURL @"https://..."


@implementation TwowayHttps

+ (AFHTTPSessionManager *)sessionManager {
    __weak typeof(self)weakSelf = self;
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

                    /// 创建质询证书
                    credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
                    /// 确认质询方式
                    if (credential) {
                        disposition = NSURLSessionAuthChallengeUseCredential;
                    } else {
                        disposition = NSURLSessionAuthChallengePerformDefaultHandling;
                    }
                } else {
                    /// 取消挑战
                    disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
                }

            } else {
                /// client authentication
                SecIdentityRef identity = NULL;
                SecTrustRef trust = NULL;
                /// 客户端证书.p12
                NSString *p12 = [[NSBundle mainBundle] pathForResource:@"test-p12" ofType:@"p12"];
                NSFileManager *fileManager = [NSFileManager defaultManager];

                if(![fileManager fileExistsAtPath:p12]) {
                    NSLog(@"client.p12:not exist");
                } else {
                    NSData *PKCS12Data = [NSData dataWithContentsOfFile:p12];
                    /// extract: 提取
                    if ([[weakSelf class] extractIdentity:&identity andTrust:&trust fromPKCS12Data:PKCS12Data]){
                        SecCertificateRef certificate = NULL;
                        SecIdentityCopyCertificate(identity, &certificate);
                        const void *certs[] = {certificate};
                        CFArrayRef certArray =CFArrayCreate(kCFAllocatorDefault, certs,1,NULL);
                        credential = [NSURLCredential credentialWithIdentity:identity certificates:(__bridge  NSArray*)certArray persistence:NSURLCredentialPersistencePermanent];
                        disposition = NSURLSessionAuthChallengeUseCredential;
                    }
                }
            }
            *_credential = credential;
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

    [[TwowayHttps sessionManager] POST:Url parameters:parameters headers:haers progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
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

    [[TwowayHttps sessionManager] GET:Url parameters:parameters  headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (success) {
            success(task, responseObject);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (failure) {
            failure(task, error);
        }
    }];
}

#pragma mark p12验证

+ (BOOL)extractIdentity:(SecIdentityRef*)outIdentity andTrust:(SecTrustRef *)outTrust fromPKCS12Data:(NSData *)inPKCS12Data {
    OSStatus securityError = errSecSuccess;
    /// client p12 certificate password
    NSDictionary *optionsDictionary = [NSDictionary dictionaryWithObject:@"p12-test"
                                                                  forKey:(__bridge id)kSecImportExportPassphrase];

    CFArrayRef items = CFArrayCreate(NULL, 0, 0, NULL);
    securityError = SecPKCS12Import((__bridge CFDataRef)inPKCS12Data,(__bridge CFDictionaryRef)optionsDictionary,&items);

    if(securityError == 0) {
        CFDictionaryRef myIdentityAndTrust =CFArrayGetValueAtIndex(items,0);
        const void*tempIdentity = NULL;
        tempIdentity= CFDictionaryGetValue (myIdentityAndTrust,kSecImportItemIdentity);
        *outIdentity = (SecIdentityRef)tempIdentity;
        const void*tempTrust = NULL;
        tempTrust = CFDictionaryGetValue(myIdentityAndTrust,kSecImportItemTrust);
        *outTrust = (SecTrustRef)tempTrust;
    } else {
        NSLog(@"Failedwith error code %d",(int)securityError);
        return NO;
    }
    return YES;
}


@end
