//
//  TapjoyHelper.m
//  iPetHotel
//
//  Created by LEON on 11-7-22.
//  Copyright 2011 D.I.O Game. All rights reserved.
//
#import "SNSLogType.h"
#import "ChukongHelper.h"
#import "SystemUtils.h"
#import "StringUtils.h"
#import "SNSAlertView.h"
#import "smPopupWindowNotice.h"
#import "smPopupWindowQueue.h"


enum {
    OFFER_STATUS_NONE = 0,
    OFFER_STATUS_LOADING = 1,
    OFFER_STATUS_READY   = 2,
    OFFER_STATUS_LOADFAIL  = 3,
    OFFER_STATUS_SHOWING   = 4,
};

static ChukongHelper *_gChukongHelper = nil;

@implementation ChukongHelper

+(ChukongHelper *)helper
{
	@synchronized(self) {
		if(!_gChukongHelper) {
			_gChukongHelper = [[ChukongHelper alloc] init];
		}
	}
	return _gChukongHelper;
}

-(id)init
{
    self = [super init];
    
	isSessionInitialized = NO; stAppKey = nil; 
	return self;
}

-(void)dealloc
{
    [stAppKey release];
	[super dealloc];
}

-(void) initSession
{
	if(isSessionInitialized) return;

    stAppKey = [SystemUtils getGlobalSetting:@"kChukongPubID"];
    if(!stAppKey || [stAppKey length]<3) stAppKey = [SystemUtils getSystemInfo:@"kChukongPubID"];
    if(!stAppKey || [stAppKey length]<3) return;
    
#ifdef DEBUG
    stAppKey = @"100032-4CE817-ABA2-5B48-14D009296720";
#endif
    
    isSessionInitialized = YES; pendingCoins = 0;
    [stAppKey retain];
    
    [ChanceAd startSession: stAppKey];
    [CSAppZone sharedAppZone].delegate = self;
    [CSInterstitial sharedInterstitial].delegate = self;
    
    
    
    interstitialStatus = OFFER_STATUS_NONE; offerStatus = OFFER_STATUS_NONE;
    [self loadInterstitial];
    [self loadOffer];
    [self checkPointsLazy];
}

// 如果昨天有打开广告墙，就检查是否有奖励
-(void) checkPointsLazy
{
    // 显示广告的时间
    int showTime = [[SystemUtils getNSDefaultObject:@"kChukongShowTime"] intValue];
    if(showTime==0) return;
    // 检查奖励的时间
    int checkTime = [[SystemUtils getNSDefaultObject:@"kChukongCheckTime"] intValue];
    if(checkTime>showTime+1) return;
    [self initSession];
    [self checkPoints];
}

- (void) loadOffer
{
    if(offerStatus==OFFER_STATUS_LOADING || offerStatus==OFFER_STATUS_READY || offerStatus==OFFER_STATUS_SHOWING) return;
    offerStatus = OFFER_STATUS_LOADING;
    // 加载积分墙
    [[CSAppZone sharedAppZone] loadAppZone:[CSADRequest request]];

}

- (void) loadInterstitial
{
    if(interstitialStatus==OFFER_STATUS_LOADING || interstitialStatus==OFFER_STATUS_READY || interstitialStatus==OFFER_STATUS_SHOWING) return;
    interstitialStatus = OFFER_STATUS_LOADING;
    // 加载弹窗
    [[CSInterstitial sharedInterstitial] loadInterstitial:[CSADRequest request]];
}

- (void) showInterstitial
{
    [self initSession];
    if(interstitialStatus!=OFFER_STATUS_READY)
    {
        if(interstitialStatus==OFFER_STATUS_LOADFAIL)
            [self loadInterstitial];
        return;
    }
    if(interstitialStatus==OFFER_STATUS_SHOWING || offerStatus==OFFER_STATUS_SHOWING) {
        SNSLog(@"offers is showing");
        return;
    }
    
    interstitialStatus = OFFER_STATUS_SHOWING;
    [[CSInterstitial sharedInterstitial] showInterstitialWithScale:0.9f];
    
}

- (void) showOffers
{
    NSLog(@"%s",__func__);
    [self initSession];

    if(offerStatus!=OFFER_STATUS_READY)
    {
        if(offerStatus==OFFER_STATUS_LOADFAIL)
            [self loadOffer];
        return;
    }
    if(interstitialStatus==OFFER_STATUS_SHOWING || offerStatus==OFFER_STATUS_SHOWING) {
        SNSLog(@"offers is showing");
        return;
    }
    offerStatus = OFFER_STATUS_SHOWING;
    
    int date = [SystemUtils getTodayDate];
    [SystemUtils setNSDefaultObject:[NSNumber numberWithInt:date] forKey:@"kChukongShowTime"];
    
    //显示广告墙
    [[CSAppZone sharedAppZone] showAppZoneWithScale:0.9f];
}

-(void) hideOffers
{
    
}

-(void)checkPoints
{
    [self initSession];
    SNSLog(@"start checking points");
    [[CSAppZone sharedAppZone] queryRewardCoin:nil];

    // [[LmmobAdWallSDK defaultSDK] ScoreQuery];
	// This method requests the tapjoy server for current virtual currency of the user.
	// if([TapjoyConnect 
	// [TapjoyConnect getTapPoints];
    int date = [SystemUtils getTodayDate];
    [SystemUtils setNSDefaultObject:[NSNumber numberWithInt:date] forKey:@"kChukongCheckTime"];
}

-(BOOL) isOfferReady
{
    return (offerStatus==OFFER_STATUS_READY);
}



#pragma mark appZoneDelegate

/**
 *	@brief	用户完成积分墙任务的回调
 *
 *	@param 	pbOfferWall 	pbOfferWall
 *	@param 	taskCoins 	taskCoins中的元素为NSDictionary类型（taskCoins为空表示无积分返回，为nil表示查询出错）
 *                            键值说明：taskContent  NSString   任务名称
 //                                   coins        NSNumber    赚得金币数量
 *	@param 	error 	taskCoins为nil时有效，查询失败原因
 */
- (void)pbAppZone:(CSAppZone *)pbAppZone queryResult:(NSArray *)taskCoins
        withError:(CSRequestError *)error
{
    if(taskCoins==nil) {
        SNSLog(@"error: %@", error);
        return;
    }
    int coins = 0;
    for(NSDictionary *info in taskCoins) {
        coins += [[info objectForKey:@"coins"] intValue];
    }
    if(coins<=0) return;
    
    int coinType = [[SystemUtils getGlobalSetting:@"kChukongCoinType"] intValue];
    if(coinType<=0)coinType = [[SystemUtils getSystemInfo:@"kChukongCoinType"] intValue];
    if(coinType<=0) coinType = 1;
	
    int amount = coins;
    
	[SystemUtils addGameResource:amount ofType:coinType];
    
    NSString *coinKey = [NSString stringWithFormat:@"CoinName%d",coinType];
    
    NSString *leafName = [SystemUtils getLocalizedString:coinKey];
    if(amount>1) leafName = [StringUtils getPluralFormOfWord:leafName];
	NSString *mesg = [NSString stringWithFormat:[SystemUtils getLocalizedString:@"Congratulations! You've got %1$i %2$@ for free!"], amount, leafName];
    NSString *title = [SystemUtils getLocalizedString:@"Ad Bonus Received"];
    [SystemUtils showSNSAlert:title message:mesg];
    
}

// 积分墙加载完成
- (void)pbAppZoneDidLoadAd:(CSAppZone *)pbAppZone
{
    offerStatus = OFFER_STATUS_READY;
}

// 积分墙加载错误
- (void)pbAppZone:(CSAppZone *)pbAppZone
loadAdFailureWithError:(CSRequestError *)requestError
{
    offerStatus = OFFER_STATUS_LOADFAIL;
}

// 积分墙打开完成
- (void)pbAppZoneDidPresentScreen:(CSAppZone *)pbAppZone
{
    offerStatus = OFFER_STATUS_READY;
}

// 积分墙将要关闭
- (void)pbAppZoneWillDismissScreen:(CSAppZone *)pbAppZone
{

}

// 积分墙关闭完成
- (void)pbAppZoneDidDismissScreen:(CSAppZone *)pbAppZone
{
    
}

#pragma mark -
#pragma mark PBInterstitialDelegate
// 弹出广告加载完成
- (void)pbInterstitialDidLoadAd:(CSInterstitial *)pbInterstitial
{
    interstitialStatus = OFFER_STATUS_READY;
}

// 弹出广告加载错误
- (void)pbInterstitial:(CSInterstitial *)pbInterstitial
loadAdFailureWithError:(CSRequestError *)requestError
{
    interstitialStatus = OFFER_STATUS_LOADFAIL;
}

// 弹出广告打开完成
- (void)pbInterstitialDidPresentScreen:(CSInterstitial *)pbInterstitial
{
    
}

// 倒计时结束
- (void)pbInterstitialCountDownFinished:(CSInterstitial *)pbInterstitial
{
    
}

// 弹出广告将要关闭
- (void)pbInterstitialWillDismissScreen:(CSInterstitial *)pbInterstitial
{
    
}

// 弹出广告关闭完成
- (void)pbInterstitialDidDismissScreen:(CSInterstitial *)pbInterstitial
{
    interstitialStatus = OFFER_STATUS_NONE;
    [self loadInterstitial];
}

#pragma mark -

@end
