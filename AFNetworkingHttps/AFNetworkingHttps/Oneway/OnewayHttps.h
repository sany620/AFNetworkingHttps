//
//  OnewayHttps.h
//  AFNetworkingHttps
//
//  Created by duanmu on 2020/9/13.
//  Copyright © 2020 duanmu. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OnewayHttps : NSObject

+ (void)POST:(NSString *)Url
  parameters:(_Nullable id)parameters
     success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
     failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure;

+ (void)GET:(NSString *)Url
 parameters:(_Nullable id)parameters
    success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
    failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure;

@end

NS_ASSUME_NONNULL_END
