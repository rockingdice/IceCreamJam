//
//  TapjoyHelper.m
//  iPetHotel
//
//  Created by LEON on 11-7-22.
//  Copyright 2011 D.I.O Game. All rights reserved.
//
#import "SNSLogType.h"
#import "DomobHelper.h"
//#import "TapjoyConnect.h"
#import "SystemUtils.h"
//#import "smPopupWindowNotice.h"
//#import "smPopupWindowQueue.h"
// #import "AudioPlayer.h"
//#import "cocos2d.h"
//#import "SNSWebWindow.h"
#import "StringUtils.h"
//#import "ZFGuiLayer.h"
//#import "GameDefines.h"
//#import "SimpleAudioEngine.h"
//#import "ZFSoundIDs.h"
#import "SNSAlertView.h"
#import "smPopupWindowNotice.h"
#import "smPopupWindowQueue.h"

static DomobHelper *_gDomobHelper = nil;

@implementation DomobHelper

+(DomobHelper *)helper
{
	@synchronized(self) {
		if(!_gDomobHelper) {
			_gDomobHelper = [[DomobHelper alloc] init];
		}
	}
	return _gDomobHelper;
}

-(id)init
{
    self = [super init];
    
	isSessionInitialized = NO; stAppKey = nil; _offerWallController = nil;
	_offerWallManager = nil; isOfferShowing = NO;
	return self;
}

-(void)dealloc
{
    _offerWallController.delegate = nil;
    [_offerWallController release];
    _offerWallManager.delegate = nil;
    [_offerWallManager release];
    
    [stAppKey release];
	[super dealloc];
}

-(void) initSession
{
	if(isSessionInitialized) return;
    
    stAppKey = [SystemUtils getGlobalSetting:@"kDomobPublisherID"];
    if(!stAppKey || [stAppKey length]<3) stAppKey = [SystemUtils getSystemInfo:@"kDomobPublisherID"];
    if(!stAppKey || [stAppKey length]<3) return;
    [stAppKey retain];
	
    isSessionInitialized = YES; isOfferLoaded = NO; pendingCoins = 0;
    
    // [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showOffers) name:@"PushAD" object:nil];
    // entranceID: 4834cdd70c90821fd807b4cfafeb2d63
    // mediaID: 7f297998776f5aaa3a45c9cca1fa5bf5
    // adWallID: 2d4ac11944143a74458dd5d6f42fef38
    // -(void)GetAdWallWithEntranceID:(NSString *)entranceid AndDelegate:(id<LmmobAdWallDelegate>)delegate;
    SNSLog(@"id:%@", stAppKey);
    // [pLimeiView immobViewRequest];
    _offerWallController = [[DMOfferWallViewController alloc] initWithPublisherID:stAppKey];
    _offerWallController.delegate = self;
    
    _offerWallManager = [[DMOfferWallManager alloc] initWithPublishId:stAppKey userId:nil];
    _offerWallManager.delegate = self;
    [self checkPointsLazy];
	
}

// 如果昨天有打开广告墙，就检查是否有奖励
-(void) checkPointsLazy
{
    // 显示广告的时间
    int showTime = [[SystemUtils getNSDefaultObject:@"kDomobShowTime"] intValue];
    if(showTime==0) return;
    // 检查奖励的时间
    int checkTime = [[SystemUtils getNSDefaultObject:@"kDomobCheckTime"] intValue];
    if(checkTime>showTime+1) return;
    [self initSession];
    [self checkPoints];
}


- (void) showOffers
{
    NSLog(@"%s",__func__);
    [self initSession];
    
    if(isOfferShowing) {
        SNSLog(@"offers is showing");
        return;
    }
    isOfferShowing = YES;
    UIViewController *root = [SystemUtils getRootViewController];
    
    [_offerWallController presentOfferWallWithViewController:root];
    int date = [SystemUtils getTodayDate];
    [SystemUtils setNSDefaultObject:[NSNumber numberWithInt:date] forKey:@"kDomobShowTime"];

}

-(void) hideOffers
{
    
}

-(void)checkPoints
{
    [self initSession];
    SNSLog(@"start checking domob points");
    [_offerWallManager requestOnlinePointCheck];
    // [[LmmobAdWallSDK defaultSDK] ScoreQuery];
	// This method requests the tapjoy server for current virtual currency of the user.
	// if([TapjoyConnect 
	// [TapjoyConnect getTapPoints];
    int date = [SystemUtils getTodayDate];
    [SystemUtils setNSDefaultObject:[NSNumber numberWithInt:date] forKey:@"kDomobCheckTime"];
}

-(BOOL) isOfferReady
{
    [self initSession];
    return isOfferLoaded;
}


#pragma mark DMOfferWallDelegate

// 积分墙开始加载数据。
- (void)offerWallDidStartLoad
{
    SNSLog(@"start loading offer");
}
// 积分墙加载完成。
- (void)offerWallDidFinishLoad
{
    SNSLog(@"offer ready");
    isOfferLoaded = YES;
}
// 积分墙加载失败。可能的原因由 error 部分提供,例如⺴⽹网络连接失败、被禁⽤用等。
- (void)offerWallDidFailLoadWithError:(NSError *)error
{
    SNSLog(@"load offer failed");
    isOfferLoaded = NO;
    isOfferShowing = NO;
}

// 积分墙页面被关闭。
// Offer wall closed.
- (void)offerWallDidClosed
{
    isOfferShowing = NO;
}


#pragma mark -

#pragma mark DMOfferWallManagerDelegate
// 积分查询成功之后，回调该接口，获取总积分和总已消费积分。
- (void)offerWallDidFinishCheckPointWithTotalPoint:(NSInteger)totalPoint
                             andTotalConsumedPoint:(NSInteger)consumed {
    SNSLog(@"offerWallDidFinishCheckPoint");
    if(totalPoint<=consumed) return;
    pendingCoins = totalPoint - consumed;
    [_offerWallManager requestOnlineConsumeWithPoint:pendingCoins];
}

// 积分查询失败之后，回调该接口，返回查询失败的错误原因。
- (void)offerWallDidFailCheckPointWithError:(NSError *)error {
    SNSLog(@"offerWallDidFailCheckPointWithError:%@", error);
}

// 消费请求正常应答后，回调该接口，并返回消费状态（成功或余额不足），以及总积分和总已消费积分。
- (void)offerWallDidFinishConsumePointWithStatusCode:(DMOfferWallConsumeStatusCode)statusCode
                                          totalPoint:(NSInteger)totalPoint
                                  totalConsumedPoint:(NSInteger)consumed {
    SNSLog(@"offerWallDidFinishConsumePoint");
    if(statusCode!=DMOfferWallConsumeStatusCodeSuccess) return;
    
    int coinType = [[SystemUtils getGlobalSetting:@"kDomobCoinType"] intValue];
    if(coinType<=0) coinType = [[SystemUtils getSystemInfo:@"kDomobCoinType"] intValue];
    if(coinType<=0) coinType = 1;
	int amount = pendingCoins; pendingCoins = 0;
	if (amount <= 0) return;
	// int localAmount = [SystemUtils getTapjoyPoint];
	// TODO: add log
    
	[SystemUtils addGameResource:amount ofType:coinType];
    
    NSString *coinKey = [NSString stringWithFormat:@"CoinName%d",coinType];
    
    NSString *leafName = [SystemUtils getLocalizedString:coinKey];
    if(amount>1) leafName = [StringUtils getPluralFormOfWord:leafName];
	NSString *mesg = [NSString stringWithFormat:[SystemUtils getLocalizedString:@"Congratulations! You've got %1$i %2$@ for free!"], amount, leafName];
    NSString *title = [SystemUtils getLocalizedString:@"Ad Bonus Received"];
    [SystemUtils showSNSAlert:title message:mesg];

}

// 消费请求异常应答后，回调该接口，并返回异常的错误原因。
- (void)offerWallDidFailConsumePointWithError:(NSError *)error {
    SNSLog(@"offerWallDidFailConsumePointWithError:%@", error);
}



@end
