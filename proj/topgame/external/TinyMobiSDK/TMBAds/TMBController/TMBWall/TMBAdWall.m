//
//  TMBAdWall.m
//  TinyMobi SDK
//
//  Created by gaofeng on 12-6-27.
//  Copyright (c) 2012 TinyMobi. All rights reserved.
//
#import "TMBConfig.h"
#import "TMBAdWall.h"
#import "TMBAdWallView.h"
#import "TMBNetWork.h"
#import "TMBSDKConfig.h"
#import "TMBJSONKit.h"

#import "TMBLog.h"

static TMBBaseAd *_sharedAd = nil;

static NSDictionary *_delegateMap = nil;

@implementation TMBAdWall

+ (TMBBaseAd *) sharedAd
{
    if(!_sharedAd)
	{
        TMBBaseAd *adObj = [[self alloc] init];
        _sharedAd = adObj;
	}
	return _sharedAd;
}

- (void) show
{
    [self loadConfig];
    //open
    if ([[adConfig objectForKey:@"ad.wall.open"] intValue] != 1) {
        return;
    }
    [self loadStart];
}

- (void) loadStart
{
    [self setAdView:[[[TMBAdWallView alloc] init] autorelease]];
    [(TMBAdWallView *)adView setAdController:self];
    [(TMBAdWallView *)adView loadAdPre];
    [self loadData];
}

- (void) loadData
{
    TMBNetWork *net = [[[TMBNetWork alloc] initWithSecretKey:secretKey] autorelease];
    [net setTimeout:TMB_NET_TIMEOUT];
    NSString *url = [NSString stringWithFormat:[TMBNetWork fullUrl:TMB_AD_WALL_URL], [TMBNetWork host], appId];
    NSMutableDictionary *params = [[[NSMutableDictionary alloc] initWithCapacity:1] autorelease];
    [params setObject:@"wall" forKey:@"wall_type"];
    [net sendAsyncRequestWithURL:url Data:params ResponseObj:self Method:@selector(loadDataFinish:)];
}

- (void) loadDataFinish: (NSData *)data
{
    if (data) {
        [self setAdData:[[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]];
    }else{
        [self setAdData:@""];
    }
    [adView loadAd];
}

- (BOOL) isReady
{
    [self loadConfig];
    if (!adConfig || [[adConfig valueForKey:@"ad.wall.open"] intValue]==0) {
        return FALSE;
    }
    TMBNetWork *net = [[[TMBNetWork alloc] initWithSecretKey:secretKey] autorelease];
    [net setTimeout:TMB_NET_TIMEOUT];
    NSString *url = [NSString stringWithFormat:[TMBNetWork fullUrl:TMB_AD_WALL_READY_URL], [TMBNetWork host], appId];
    NSData *ret = [net sendRequestWithURL:url Data:nil];
    if (ret) {
        id decodeRes = [TMBNetWork decodeServerJsonResult:[[[NSString alloc] initWithData:ret encoding:NSUTF8StringEncoding] autorelease]];
        if (decodeRes && [decodeRes isKindOfClass:[NSDictionary class]]) {
            NSDictionary *res = (NSDictionary *)decodeRes;
            if ([res valueForKey:@"display"] && [[res valueForKey:@"display"] intValue] != 1) {
                return FALSE;
            }
        }
    }
    return TRUE;
}

- (void) loadConfig
{
    TMBSDKConfig *config = [[[TMBSDKConfig alloc] initAppId:appId] autorelease];
    NSMutableDictionary *adConf = [[[NSMutableDictionary alloc] init] autorelease];
    [adConf setObject:[config getConfigOfKey:@"ad.wall.open"] forKey:@"ad.wall.open"];
    id loading = [[config getConfigOfKey:@"ad.wall.loading"] objectFromJSONString];
    if (loading) {
        [adConf setObject:loading forKey:@"ad.wall.loading"];
    }
    [self setAdConfig:adConf];
}

+ (NSDictionary *) noticeDelegateMap
{
    if (!_delegateMap) {
        _delegateMap = [[NSDictionary alloc] initWithObjectsAndKeys:@"tinyWallWillInstall", TMB_AD_EVENT_APP_INSTALL, @"tinyWallWillPlay", TMB_AD_EVENT_APP_PLAY, @"tinyWallDidDisplay", TMB_AD_EVENT_DISPLAY, @"tinyWallDidDismiss", TMB_AD_EVENT_DISMISS, nil];
    }
    return _delegateMap;
}
@end
