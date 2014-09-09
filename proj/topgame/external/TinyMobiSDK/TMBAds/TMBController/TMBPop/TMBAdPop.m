//
//  TMBAdPop.m
//  TinyMobi SDK
//
//  Created by gaofeng on 12-8-7.
//  Copyright (c) 2012 TinyMobi. All rights reserved.
//
#import "TMBConfig.h"
#import "TMBAdPop.h"
#import "TMBAdPopView.h"
#import "TMBNetWork.h"
#import "TMBSDKConfig.h"

#import "TMBLog.h"

static TMBBaseAd *_sharedAd = nil;

static NSDictionary *_delegateMap = nil;

@implementation TMBAdPop

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
    if ([[adConfig objectForKey:@"ad.pop.open"] intValue] != 1) {
        return;
    }
    if ([[adConfig objectForKey:@"ad.pop.delay"] intValue] > 0) {
        [self performSelector:@selector(loadData) withObject:nil afterDelay:[[adConfig objectForKey:@"ad.pop.delay"] intValue]];
    }else{
        [self loadStart];
    }
}

- (void) loadStart
{
    if(delegate && [delegate respondsToSelector:@selector(shouldDisplayPop)]){
        if(![delegate shouldDisplayPop]){
            [TMBLog log:@"pop sleep" :@"3"];
            [self performSelector:@selector(loadStart) withObject:nil afterDelay:3];
            return;
        }
    }
    [self loadData];
}

- (void) loadData
{
    TMBNetWork *net = [[[TMBNetWork alloc] initWithSecretKey:secretKey] autorelease];
    [net setTimeout:TMB_NET_TIMEOUT];
    NSString *url = [NSString stringWithFormat:[TMBNetWork fullUrl:TMB_AD_POP_URL], [TMBNetWork host], appId];
    [net sendAsyncRequestWithURL:url Data:nil ResponseObj:self Method:@selector(loadDataFinish:)];
}

- (void) loadDataFinish: (NSData *)data
{
    [self setAdData:nil];
    if (!data) {
        return;
    }
    id json = [TMBNetWork decodeServerJsonResult:[[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]];
    if (json && [json isKindOfClass:[NSDictionary class]]) {
        if ([json objectForKey:@"type"] && [[json objectForKey:@"type"] intValue]==1){
            [self setAdData:json];
            [self setAdView:[[[TMBAdPopView alloc] init] autorelease]];
            [(TMBAdPopView *)adView setAdController:self];
            if (adData && ![adView isShow]) {
                [self setFatherViewController:nil];
                [adView loadAd];
            }
        }
    }
}

- (BOOL) isReady
{
    [self loadConfig];
    if (!adConfig || [[adConfig valueForKey:@"ad.pop.open"] intValue]==0) {
        return FALSE;
    }
    TMBNetWork *net = [[[TMBNetWork alloc] initWithSecretKey:secretKey] autorelease];
    [net setTimeout:TMB_NET_TIMEOUT];
    NSString *url = [NSString stringWithFormat:[TMBNetWork fullUrl:TMB_AD_POP_READY_URL], [TMBNetWork host], appId];
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
    [adConf setObject:[config getConfigOfKey:@"ad.pop.open"] forKey:@"ad.pop.open"];
    [adConf setObject:[config getConfigOfKey:@"ad.pop.delay"] forKey:@"ad.pop.delay"];
    [adConf setObject:[config getConfigOfKey:@"ad.pop.auto.close.time"] forKey:@"ad.pop.auto.close.time"];
    NSString *maxShow = [config getConfigOfKey:@"ad.pop.show.max"];
    if ([maxShow intValue] <= 0) {
        maxShow = @"60";
    }
    [adConf setObject:maxShow forKey:@"ad.pop.show.max"];
    [self setAdConfig:adConf];
}

+ (NSDictionary *) noticeDelegateMap
{
    if (!_delegateMap) {
        _delegateMap = [[NSDictionary alloc] initWithObjectsAndKeys:@"tinyPopWillInstall", TMB_AD_EVENT_APP_INSTALL, @"tinyPopWillPlay", TMB_AD_EVENT_APP_PLAY, @"tinyPopDidDisplay", TMB_AD_EVENT_DISPLAY, @"tinyPopDidDismiss", TMB_AD_EVENT_DISMISS, @"tinyPopWillOpenWall", TMB_AD_EVENT_OTHER_AD_WALL, nil];
    }
    return _delegateMap;
}
@end
