//
//  TMBSDKConfig.h
//  TinyMobi SDK
//
//  Created by gaofeng on 12-7-17.
//  Copyright (c) 2012 TinyMobi. All rights reserved.
//
#import <Foundation/Foundation.h>

@interface TMBSDKConfig : NSObject
{
    NSString *appId;
}
- (id) initAppId: (NSString *)_appId;

- (void) refreshSDKConfigWithSecretKey:(NSString *)secretKey;

- (id) getConfigOfKey: (NSString *) key;

@end
