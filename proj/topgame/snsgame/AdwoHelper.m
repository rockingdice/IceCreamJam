//
//  TapjoyHelper.m
//  iPetHotel
//
//  Created by LEON on 11-7-22.
//  Copyright 2011 D.I.O Game. All rights reserved.
//
#import "SNSLogType.h"
#import "AdwoHelper.h"
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




static AdwoHelper *_gAdwoHelper = nil;

@implementation AdwoHelper

+(AdwoHelper *)helper
{
	@synchronized(self) {
		if(!_gAdwoHelper) {
			_gAdwoHelper = [[AdwoHelper alloc] init];
		}
	}
	return _gAdwoHelper;
}

-(id)init
{
    self = [super init];
    
	isSessionInitialized = NO; stAppKey = nil;
	return self;
}


-(void)dealloc
{
    //开发者在销毁控制器的时候，注意销毁注册响应事件，否则可能会因为异步处理问题造成程序崩溃。
    ZKcmoneOWUnregisterResponseEvents(ZKCMONE_ZKCM_TWO_RESPONSE_EVENTS_ZKCMT_PRESENT | ZKCMONE_ZKCM_TWO_RESPONSE_EVENTS_ZKCMT_DISMISS|ZKCMONE_ZKCM_TWO_REFRESH_PT|ZKCMONE_ZKCM_TWO_CONSUMEPTS_PT|ZKCMONE_ZKCM_TWO_SUZKCMARY_MESSAGE);
    
    [stAppKey release];
	[super dealloc];
}

-(void) initSession
{
	if(isSessionInitialized) return;

    stAppKey = [SystemUtils getGlobalSetting:@"kAdwoAppID"];
    if(!stAppKey || [stAppKey length]<3) stAppKey = [SystemUtils getSystemInfo:@"kAdwoAppID"];
    if(!stAppKey || [stAppKey length]<3) return;
    
    isSessionInitialized = YES; isOfferLoaded = NO; pendingCoins = 0; isOfferShowing = NO;
    [stAppKey retain];
    
    // 积分墙打开
    ZKcmoneOWRegisterResponseEvent(ZKCMONE_ZKCM_TWO_RESPONSE_EVENTS_ZKCMT_PRESENT, self, @selector(loginSelector));
    // 注册积分墙被关闭事件消息
    ZKcmoneOWRegisterResponseEvent(ZKCMONE_ZKCM_TWO_RESPONSE_EVENTS_ZKCMT_DISMISS, self, @selector(dismissSelector));
    // 注册积分消费响应事件消息
    ZKcmoneOWRegisterResponseEvent(ZKCMONE_ZKCM_TWO_CONSUMEPTS_PT, self, @selector(ZKcmoneOWConsumepoint));
    // 注册积分墙刷新最新积分响应事件消息，使用分数的时候，开发者应该先刷新积分接口获得服务器的最新积分，再利用此分数进行相关操作
    ZKcmoneOWRegisterResponseEvent(ZKCMONE_ZKCM_TWO_REFRESH_PT, self, @selector(ZKcmoneOWRefreshPoint));
    // 注册积分墙刷新最新服务器响应事件消息
    ZKcmoneOWRegisterResponseEvent(ZKCMONE_ZKCM_TWO_SUZKCMARY_MESSAGE, self, @selector(ZKcmoneOWSummary));
    
    [self checkPointsLazy];
}

// 如果昨天有打开广告墙，就检查是否有奖励
-(void) checkPointsLazy
{
    // 显示广告的时间
    int showTime = [[SystemUtils getNSDefaultObject:@"kAdwoShowTime"] intValue];
    if(showTime==0) return;
    // 检查奖励的时间
    int checkTime = [[SystemUtils getNSDefaultObject:@"kAdwoCheckTime"] intValue];
    if(checkTime>showTime+1) return;
    [self initSession];
    [self checkPoints];
}
/*
static NSString* const errCodeList[] = {
    @"successful",
    @"offer wall is disabled",
    @"login connection failed",
    @"offer wall has not been loginned",
    @"offer wall is not initialized",
    @"offer wall has been loginned",
    @"unknown error",
    @"invalid event flag",
    @"app list request failed",
    @"app list response failed",
    @"app list parameter malformatted",
    @"app list is being requested",
    @"offer wall is not ready for show",
    @"keywords malformatted",
    @"current device has not enough space to save resource",
    @"resource malformatted",
    @"resource load failed",
    @"you are have already loginned",
    @"exceed max show count",
    @"exceed max login count",
    @"you have not enough points",
    @"points consumption is not available",
    @"point is negative number",
    @"receive point is error",
    @"network request error"
};
*/
- (void) showOffers
{
    NSLog(@"%s",__func__);
    [self initSession];
    
    if(isOfferShowing) {
        SNSLog(@"offers is showing");
        return;
    }
    
    isOfferShowing = YES;
    int date = [SystemUtils getTodayDate];
    [SystemUtils setNSDefaultObject:[NSNumber numberWithInt:date] forKey:@"kAdwoShowTime"];
    
    // 初始化并登录积分墙
    BOOL result = ZKcmoneOWPresentZKcmtwo(stAppKey, [SystemUtils getRootViewController]);

    if(!result)
    {
        
        NSInteger errCode = ZKcmoneOWFetchLatestErrorCode();
        
        //NSLog(@"Initialization error, because %@", errCodeList[errCode]);
    }
    else
        NSLog(@"Initialization successfully!");
}

- (void) showInterstitial
{
    [self initSession];
    
    if(mAdView != nil)
        return;
    
    hasAdLoaded = NO;
    
    // 初始化AWAdView对象
    mAdView = AdwoAdGetFullScreenAdHandle(stAppKey, YES, self, ADWOSDK_FSAD_SHOW_FORM_APPFUN_WITH_BRAND);
    if(mAdView == nil)
    {
        NSLog(@"ZKcmone full-screen ad failed to create!");
        return;
    }
    
    // 这里使用ADWO_ADSDK_AD_TYPE_FULL_SCREEN标签来加载全屏广告
    // 全屏广告是立即加载的，因此不需要设置adRequestTimeIntervel属性，当然也不需要设置其frame属性
    AdwoAdLoadFullScreenAd(mAdView, NO,1);
    
}

-(void) hideOffers
{
    
}

-(void)checkPoints
{
    [self initSession];
    SNSLog(@"start checking youmi points");
    ZKcmoneOWRefreshPoint();

    // [[LmmobAdWallSDK defaultSDK] ScoreQuery];
	// This method requests the tapjoy server for current virtual currency of the user.
	// if([TapjoyConnect 
	// [TapjoyConnect getTapPoints];
    int date = [SystemUtils getTodayDate];
    [SystemUtils setNSDefaultObject:[NSNumber numberWithInt:date] forKey:@"kAdwoCheckTime"];
}

-(BOOL) isOfferReady
{
    [self initSession];
    return isOfferLoaded;
}


#pragma mark - adwo ZKcmtwo delegates
//登陆积分墙的代理方法
- (void)loginSelector
{
    enum ZKCMONE_ZKCM_TWO_ERRORCODE errCode = ZKcmoneOWFetchLatestErrorCode();
    if(errCode == ZKCMONE_ZKCM_TWO_ERRORCODE_SUCCESS)
        SNSLog(@"Login successfully!");
    else
        SNSLog(@"Login failed, errCode: %d", errCode);
}
//退出积分墙的代理方法
- (void)dismissSelector
{
    isOfferShowing = NO;
    SNSLog(@"I know, the wall is dismissed!");
}

//消费积分响应的代理方法，开发者每次消费积分之后，需要在收到此响应之后才表示完成一次消费
-(void)ZKcmoneOWConsumepoint{
    enum ZKCMONE_ZKCM_TWO_ERRORCODE errCode = ZKcmoneOWFetchLatestErrorCode();
    if(errCode != ZKCMONE_ZKCM_TWO_ERRORCODE_SUCCESS) return;
    
    int score = pendingCoins; pendingCoins = 0;
    if(score<=0) return;
    int coinType = [[SystemUtils getGlobalSetting:@"kAdwoCoinType"] intValue];
    if(coinType<=0)coinType = [[SystemUtils getSystemInfo:@"kAdwoCoinType"] intValue];
    if(coinType<=0) coinType = 1;
	
    int amount = score;
    
	[SystemUtils addGameResource:amount ofType:coinType];
    
    NSString *coinKey = [NSString stringWithFormat:@"CoinName%d",coinType];
    
    NSString *leafName = [SystemUtils getLocalizedString:coinKey];
    if(amount>1) leafName = [StringUtils getPluralFormOfWord:leafName];
	NSString *mesg = [NSString stringWithFormat:[SystemUtils getLocalizedString:@"Congratulations! You've got %1$i %2$@ for free!"], amount, leafName];
    NSString *title = [SystemUtils getLocalizedString:@"Ad Bonus Received"];
    [SystemUtils showSNSAlert:title message:mesg];

}

//刷新积分响应的代理方法
-(void)ZKcmoneOWRefreshPoint{
    enum ZKCMONE_ZKCM_TWO_ERRORCODE errCode = ZKcmoneOWFetchLatestErrorCode();
    if(errCode == ZKCMONE_ZKCM_TWO_ERRORCODE_SUCCESS)
    {
        SNSLog(@"ZKcmoneOWRefreshPoint successfully!");
        pendingCoins = 0;
        //当刷新到最新积分之后，利用此函数获得当前积分。
        ZKcmoneOWGetCurrentPoints(&pendingCoins);
        if(pendingCoins>0) ZKcmoneOWConsumePoints(pendingCoins);
    }
}

//获得积分墙最新信息的代理方法
-(void)ZKcmoneOWSummary{
    enum ZKCMONE_ZKCM_TWO_ERRORCODE errCode = ZKcmoneOWFetchLatestErrorCode();
    if(errCode == ZKCMONE_ZKCM_TWO_ERRORCODE_SUCCESS)
    {
        NSDictionary *dic =  ZKcmoneOWGetSummaryMessage();
        SNSLog(@"summary:%@",dic);
    }
}

#pragma mark - AWAdView delegates

// 此接口必须被实现，并且不能返回空！
- (UIViewController*)adwoGetBaseViewController
{
    return [SystemUtils getAbsoluteRootViewController];
}

static NSString* const ZKcmoneResponseErrorInfoList[] = {
    @"操作成功",
    @"广告初始化失败",
    @"当前广告已调用了加载接口",
    @"不该为空的参数为空",
    @"参数值非法",
    @"非法广告对象句柄",
    @"代理为空或ZKcmoneGetBaseViewController方法没实现",
    @"非法的广告对象句柄引用计数",
    @"意料之外的错误",
    @"已创建了过多的Banner广告，无法继续创建",
    @"广告加载失败",
    @"全屏广告已经展示过",
    @"全屏广告还没准备好来展示",
    @"全屏广告资源破损",
    @"开屏全屏广告正在请求",
    @"当前全屏已设置为自动展示",
    
    @"服务器繁忙",
    @"当前没有广告",
    @"未知请求错误",
    @"PID不存在",
    @"PID未被激活",
    @"请求数据有问题",
    @"接收到的数据有问题",
    @"当前IP下广告已经投放完",
    @"当前广告都已经投放完",
    @"没有低优先级广告",
    @"开发者在ZKcmone官网注册的Bundle ID与当前应用的Bundle ID不一致",
    @"服务器响应出错",
    @"设备当前没连网络，或网络信号不好",
    @"请求URL出错"
};

- (void)adwoGetBaseViewController:(UIView*)ad
{
    NSLog(@"Failed to load ad! Because: %@", ZKcmoneResponseErrorInfoList[AdwoAdGetLatestErrorCode()]);
    
    // 你这里可以再创建全屏广告对象来请求全屏广告
    // 但这里必须注意，如果要重新获取全屏广告，必须间隔至少3秒
    mAdView = nil;
}

- (void)adwoAdViewDidLoadAd:(UIView*)ad
{
    NSLog(@"Ad did load!");
    
    hasAdLoaded = YES;
    
    // 广告加载成功，可以把全屏广告展示上去
    AdwoAdShowFullScreenAd(mAdView);
}

- (void)adwoFullScreenAdDismissed:(UIView*)ad
{
    NSLog(@"Full-screen ad closed by user!");
    
    mAdView = nil;
}

- (void)adwoDidPresentModalViewForAd:(UIView*)ad
{
    NSLog(@"Browser presented!");
}

- (void)adwoDidDismissModalViewForAd:(UIView*)ad
{
    NSLog(@"Browser dismissed!");
}




@end
