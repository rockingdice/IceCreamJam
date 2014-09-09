//
//  TapjoyHelper.m
//  iPetHotel
//
//  Created by LEON on 11-7-22.
//  Copyright 2011 D.I.O Game. All rights reserved.
//
#import "SNSLogType.h"
#import "WapsHelper.h"
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

static WapsHelper *_gWapsHelper = nil;

@implementation WapsHelper

+(WapsHelper *)helper
{
	@synchronized(self) {
		if(!_gWapsHelper) {
			_gWapsHelper = [[WapsHelper alloc] init];
		}
	}
	return _gWapsHelper;
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
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    stAppKey = [SystemUtils getGlobalSetting:@"kWapsAppID"];
    if(!stAppKey || [stAppKey length]<3) stAppKey = [SystemUtils getSystemInfo:@"kWapsAppID"];
    if(!stAppKey || [stAppKey length]<3) return;
    
    isSessionInitialized = YES; pendingCoins = 0;
    [stAppKey retain];
    
    [AppConnect getConnect:stAppKey pid:@"appstore"];
    interstitialStatus = OFFER_STATUS_NONE; offerStatus = OFFER_STATUS_NONE;
    
    //获取连接状态事件 连接成功
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onConnectSuccess:)
                                                 name:WP_CONNECT_SUCCESS
                                               object:nil];
    //连接失败
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onConnectFailed:)
                                                 name:WP_CONNECT_FAILED
                                               object:nil];
    
    
    //指定处理获取用户积分的回调⽅方法
	//只有getPoints成功会通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onGetPointsSuccess:)
                                                 name:WP_GET_POINTS_SUCCESS
                                               object:nil];
    
    //只有getPoints失败会通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onGetPointsFailed:)
                                                 name:WP_GET_POINTS_FAILED
                                               object:nil];
    
    
    //获取用户消费积成功事件
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onSpendPointsSuccess:)
                                                 name:WP_SPEND_POINTS_SUCCESS
                                               object:nil];
    
    
    //从积分墙返回的事件回调⽅方法(可选):
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onOfferClosed:)
                                                 name:WP_LIST_CLOSED
                                               object:nil];
    
    //插屏广告初始化成功的回调
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onPopAdInitSuccess:)
                                                 name:WP_POPAD_INIT_SUCESS
                                               object:nil];
    
    //插屏广告初始化没有广告内容的回调
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onPopAdInitNull:)
                                                 name:WP_POPAD_INIT_NULL
                                               object:nil];
    //插屏⼲告初始化失败的回调
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onPopAdInitFail:)
                                                 name:WP_POPAD_INIT_FAILED
                                               object:nil];
    //插屏⼲⼴广告显⽰示成功的回调
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onPopAdShow:)
                                                 name:WP_POPAD_SHOW_SUCESS
                                               object:nil];
    
    //插屏⼲告没有广告显⽰示的回调⽅方法
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onPopAdShowFail:)
                                                 name:WP_POPAD_SHOW_FAILED
                                               object:nil];
    //插屏⼲告关闭回调⽅方法
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onPopAdClosed:)
                                                 name:WP_POPAD_CLOSED
                                               object:nil];
    //初始化插屏广告
    [AppConnect initPop];
    [self checkPointsLazy];

	
}





- (void) onConnectSuccess:(NSNotification*)notifyObj
{
    NSLog(@"连接成功");
}

- (void) onConnectFailed:(NSNotification*)notifyObj
{
    NSLog(@"连接失败");
}


//获取积分成功
-(void)onGetPointsSuccess:(NSNotification*)notifyObj
{
    NSLog(@"onGetPointsSuccess");
    WPUserPoints *userPointsObj = notifyObj.object;
    NSString * pointsName=[userPointsObj getPointsName];
    int  pointsValue=[userPointsObj getPointsValue];
	//NSString *pointsStr = [NSString stringWithFormat:@"您的%@: %d",pointsName, pointsValue];
    [AppConnect spendPoints:pointsValue];
}

- (void)onGetPointsFailed:(NSNotification*)notifyObj
{
    
}

//使用积分成功
- (void)onSpendPointsSuccess:(NSNotification*)notifyObj
{
    NSNumber* number = (NSNumber* )notifyObj.object;
    int pointsValue = [number intValue];
    if (pointsValue <= 0) return;
    
    int coinType = [[SystemUtils getGlobalSetting:@"kWapsCoinType"] intValue];
    if(coinType<=0)coinType = [[SystemUtils getSystemInfo:@"kWapsCoinType"] intValue];
    if(coinType<=0) coinType = 1;
    int amount = pointsValue;
    [SystemUtils addGameResource:amount ofType:coinType];
    
    NSString *coinKey = [NSString stringWithFormat:@"CoinName%d",coinType];
    NSString *leafName = [SystemUtils getLocalizedString:coinKey];
    if(amount>1) leafName = [StringUtils getPluralFormOfWord:leafName];
    NSString *mesg = [NSString stringWithFormat:[SystemUtils getLocalizedString:@"Congratulations! You've got %1$i %2$@ for free!"], amount, leafName];
    NSString *title = [SystemUtils getLocalizedString:@"Ad Bonus Received"];
    [SystemUtils showSNSAlert:title message:mesg];
}

//积分墙关闭
-(void)onOfferClosed:(NSNotification*)notifyObj
{
    NSLog(@"Offer列表已关闭");
    offerStatus = OFFER_STATUS_NONE;
}

//插屏广告初始化成功
- (void) onPopAdInitSuccess:(NSNotification*)notifyObj
{
    interstitialStatus = OFFER_STATUS_READY;
    NSLog(@"%@", @"初始化成功");
}


- (void) onPopAdInitNull:(NSNotification*)notifyObj
{
    NSLog(@"没有插屏广告内容");
    interstitialStatus = OFFER_STATUS_LOADFAIL;
}


- (void) onPopAdInitFail:(NSNotification*)notifyObj
{
    NSLog(@"初始化失败");
    interstitialStatus = OFFER_STATUS_LOADFAIL;
}

- (void) onPopAdShow:(NSNotification*)notifyObj
{
    NSLog(@"插屏⼲告展⽰示成功");
    interstitialStatus = OFFER_STATUS_SHOWING;
}


- (void) onPopAdShowFail:(NSNotification*)notifyObj
{
    NSLog(@"插屏幕广告展⽰示失败,或没有广告可展⽰");
    interstitialStatus = OFFER_STATUS_LOADFAIL;
}

- (void) onPopAdClosed:(NSNotification*)notifyObj
{
    NSLog(@"插屏广告关闭");
    interstitialStatus = OFFER_STATUS_NONE;
    [self loadInterstitial];
}


// 如果昨天有打开广告墙，就检查是否有奖励
-(void) checkPointsLazy
{
    // 显示广告的时间
    int showTime = [[SystemUtils getNSDefaultObject:@"kWapsShowTime"] intValue];
    if(showTime==0) return;
    // 检查奖励的时间
    int checkTime = [[SystemUtils getNSDefaultObject:@"kWapsCheckTime"] intValue];
    if(checkTime>showTime+1) return;
    [self initSession];
    [self checkPoints];
}

- (void) loadOffer
{

}


- (void) loadInterstitial
{
    if(interstitialStatus==OFFER_STATUS_LOADING || interstitialStatus==OFFER_STATUS_READY || interstitialStatus==OFFER_STATUS_SHOWING) return;
    interstitialStatus = OFFER_STATUS_LOADING;
    // 加载弹窗
    [AppConnect initPop];
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
    UIViewController *root = [SystemUtils getAbsoluteRootViewController];
    [AppConnect showPop:root];
    
}

- (void) showOffers
{
    NSLog(@"%s",__func__);
    [self initSession];

    if(interstitialStatus==OFFER_STATUS_SHOWING || offerStatus==OFFER_STATUS_SHOWING) {
        SNSLog(@"offers is showing");
        return;
    }
    offerStatus = OFFER_STATUS_SHOWING;
    
    int date = [SystemUtils getTodayDate];
    [SystemUtils setNSDefaultObject:[NSNumber numberWithInt:date] forKey:@"kWapsShowTime"];
    
    //显示广告墙
    UIViewController *root = [SystemUtils getAbsoluteRootViewController];
    [AppConnect showList:root];
}

-(void) hideOffers
{
    
}

-(void)checkPoints
{
    [self initSession];
    SNSLog(@"start checking points");
    [AppConnect getPoints];
    int date = [SystemUtils getTodayDate];
    [SystemUtils setNSDefaultObject:[NSNumber numberWithInt:date] forKey:@"kWapsCheckTime"];
}

-(BOOL) isOfferReady
{
    return (offerStatus==OFFER_STATUS_READY);
}




@end
