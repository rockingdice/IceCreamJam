//
//  TMBSDKConfig.m
//  TinyMobi SDK
//
//  Created by gaofeng on 12-7-17.
//  Copyright (c) 2012 TinyMobi. All rights reserved.
//
#import "TMBConfig.h"
#import "TMBSDKConfig.h"
#import "TMBNetWork.h"
#import "TMBPlistFile.h"
#import "TMBJob.h"
#import "TMBLog.h"

#define TMB_CONFIG_PLIST_FILENAME @"TMB_SDK_CONFIG_%@.plist"

@implementation TMBSDKConfig

- (id) initAppId: (NSString *)_appId
{
    if(self = [super init]){
        appId = _appId;
    }
    return self;
}

//sync config
- (void) refreshSDKConfigWithSecretKey:(NSString *)secretKey
{
    [TMBJob addJobQueueWithTarget:self selectot:@selector(syncConfigWithSecretKey:) object:secretKey];
}


//get config info by key
- (id) getConfigOfKey: (NSString *) key
{
    NSString *configFileName = [NSString stringWithFormat:TMB_CONFIG_PLIST_FILENAME, appId];
    NSDictionary *configs = [TMBPlistFile readDataInFile:configFileName];
    if(!configs || ![configs objectForKey:key] || [configs objectForKey:key]==[NSNull null]){
        return @"";
    }else{
        return [configs objectForKey:key];
    }
}

- (void) syncConfigWithSecretKey:(NSString *)secretKey
{
    TMBNetWork *net = [[[TMBNetWork alloc] initWithSecretKey:secretKey] autorelease];
    [net setTimeout:TMB_NET_TIMEOUT];
    NSString *url = [NSString stringWithFormat:[TMBNetWork fullUrl:TMB_CONFIG_SERVER_URL], [TMBNetWork host], appId];
    NSData *resData = [net sendRequestWithURL:url Data:nil];
    NSString *responseStr = [[[NSString alloc] initWithData:resData encoding:NSUTF8StringEncoding] autorelease];
    id config = [TMBNetWork decodeServerJsonResult:responseStr];
    if(config != nil && [config isKindOfClass:[NSDictionary class]]){
        if([self saveConfig: config]){
            [self saveConfig:config];
            [TMBLog log:@"SDK ASYNC CONFIG" :@"OK"];
        }else {
            [TMBLog log:@"SDK ASYNC CONFIG":@"FAIL"];
        }
    }else {
        [TMBLog log:@"SDK ASYNC CONFIG":@"SERVER SYNC FAIL"];
    }
}
//save config infos
- (BOOL) saveConfig: (NSDictionary *)configData
{
    NSString *configFileName = [NSString stringWithFormat:TMB_CONFIG_PLIST_FILENAME, appId];
    NSDictionary *allConfig = [TMBPlistFile readDataInFile:configFileName];
    if (allConfig == nil) {
        allConfig = [[[NSDictionary alloc] init] autorelease];
    }
    NSMutableDictionary *mutableConfig = [[[NSMutableDictionary alloc] initWithDictionary:allConfig] autorelease];
    [mutableConfig addEntriesFromDictionary:configData];
    for (id key in configData) {
        if ([configData objectForKey:key]  == [NSNull null]) {
            [mutableConfig setObject:@"" forKey:key];
        }else{
            [mutableConfig setObject:[configData objectForKey:key] forKey:key];
        }
    }
    return [TMBPlistFile saveData:mutableConfig InFile:configFileName];
}

@end
