//
//  TinyMobiConnect.m
//  TinyMobi SDK
//
//  Created by gaofeng on 12-6-20.
//  Copyright (c) 2012 TinyMobi. All rights reserved.
//

#import "TinyMobiConnect.h"
#import "TMBOffer.h"
#import "TMBCommon.h"
#import "TMBAdWall.h"
#import "TMBAdPop.h"
#import "TMBAdMyGames.h"
#import "TMBNetWork.h"
#import "TMBSDKConfig.h"
#import "TMBUActivityFactory.h"

@class TMBUActivityProtocol;
@class TMBViewProtocol;

//To make TinyMobiConnect Singleton
static TinyMobiConnect *_sharedTMBInstance = nil;

@interface TinyMobiConnect ()
{
    BOOL tinyPopNotAutoOpen;
}

@end

@implementation TinyMobiConnect
@synthesize appId;
@synthesize secretKey;
@synthesize delegate;

+ (TinyMobiConnect *) sharedTinyMobi
{
    if(!_sharedTMBInstance)
	{
		_sharedTMBInstance = [[self alloc] init];
	}
	return _sharedTMBInstance;
}

- (void) dealloc
{
    [appId release];
    [secretKey release];
    [super dealloc];
}

- (void) checkProperty
{
    if (!appId || !secretKey || [appId length]<1 || [secretKey length]<1) {
        NSException *e = [NSException exceptionWithName:@"TinyMobiException" reason:@"empty appId or secretKey" userInfo:nil];
        @throw e;
    }
}

//sync sdk config
- (void) syncConfig
{
    TMBSDKConfig *config = [[[TMBSDKConfig alloc] initAppId:appId] autorelease];
    [config refreshSDKConfigWithSecretKey:secretKey];
}

//send open event
- (void) sdkOpen
{
    id<TMBUActivityProtocol> uaOpen = [TMBUActivityFactory createActivityWithAppid:appId AndSecretKey:secretKey AndActivityType:TMB_USER_ACTIVITY_OPEN];
    [uaOpen do];
}

//check installed apps
- (void) checkInstall
{
    id<TMBUActivityProtocol> uaInstalled = [TMBUActivityFactory createActivityWithAppid:appId AndSecretKey:secretKey AndActivityType:TMB_USER_ACTIVITY_INSTALLED];
    [uaInstalled do];
}

- (void) start
{
    [self checkProperty];
    //init system info
    [TMBCommon initSysInfo];
    [self sdkOpen];
    [self syncConfig];
    [self checkInstall];
    //auto show tinypop
    if (!tinyPopNotAutoOpen) {
        TMBSDKConfig *config = [[[TMBSDKConfig alloc] initAppId:appId] autorelease];
        id popAutoOpenClose = [config getConfigOfKey:@"ad.pop.auto.open.close"];
        if (!popAutoOpenClose || [popAutoOpenClose intValue]!=1) {
            [self showTinyPop:nil];
        }
    }
}

//display TinyPop advertisement
- (void) showTinyPop:(UIViewController *)viewController
{
    TMBBaseAd *ad = [TMBAdPop sharedAd];
    if (![ad isShow]) {
        [self checkProperty];
        [ad setAppId:appId];
        [ad setSecretKey:secretKey];
        [ad setDelegate:delegate];
        [ad setFatherViewController:viewController];
        [ad show];
    }
}

//display TinyWall advertisement
- (void) showTinyWall:(UIViewController *)viewController
{
    TMBBaseAd *ad = [TMBAdWall sharedAd];
    if (![ad isShow]) {
        [self checkProperty];
        [ad setAppId:appId];
        [ad setSecretKey:secretKey];
        [ad setDelegate:delegate];
        [ad setFatherViewController:viewController];
        [ad show];
    }
}

//display TinyMyGames advertisement
- (void) showTinyMyGames:(UIViewController *)viewController
{
    TMBBaseAd *ad = [TMBAdMyGames sharedAd];
    if (![ad isShow]) {
        [self checkProperty];
        [ad setAppId:appId];
        [ad setSecretKey:secretKey];
        [ad setDelegate:delegate];
        [ad setFatherViewController:viewController];
        [ad show];
    }
}

//TinyPop ready
- (BOOL) isTinyPopReady
{
    [self checkProperty];
    TMBBaseAd *ad = [TMBAdPop sharedAd];
    [ad setAppId:appId];
    [ad setSecretKey:secretKey];
    [ad setDelegate:delegate];
    return [ad isReady];
}

//TinyWall ready
- (BOOL) isTinyWallReady
{
    [self checkProperty];
    TMBBaseAd *ad = [TMBAdWall sharedAd];
    [ad setAppId:appId];
    [ad setSecretKey:secretKey];
    [ad setDelegate:delegate];
    return [ad isReady];
}


//get rewards info
- (NSArray *) getRewardsInfo
{
    [self checkProperty];
    TMBOffer *offer = [[[TMBOffer alloc] init] autorelease];
    [offer setAppId:appId];
    [offer setSecretKey:secretKey];
    NSArray *infos = [offer offer];
    return infos;
}

//finished rewards
- (BOOL) finishRewardsInfo:(NSArray *)rewardsIdArray
{
    [self checkProperty];
    if (rewardsIdArray && [rewardsIdArray count]>0) {
        TMBOffer *offer = [[[TMBOffer alloc] init] autorelease];
        [offer setAppId:appId];
        [offer setSecretKey:secretKey];
        return [offer finish:[rewardsIdArray componentsJoinedByString:@","]];
    }else{
        return false;
    }
}

//set option
- (void) setOption:(NSString *)optionName WithValue:(NSString*)optionValue;
{
    if ([optionName isEqualToString:TMB_OPT_APP_ORIENTATION]) {
        [TMBCommon setAppOrientation:optionValue];
    }
    if ([optionName isEqualToString:TMB_OPT_IS_POP_AUTO_OPEN]) {
        tinyPopNotAutoOpen = ![optionValue boolValue];
    }
}

//use demo
- (void) useSandbox:(BOOL) isUseSandbox
{
    [TMBNetWork setSandboxUrlFlag:isUseSandbox];
}

@end
