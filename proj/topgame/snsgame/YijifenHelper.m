//
//  TapjoyHelper.m
//  iPetHotel
//
//  Created by LEON on 11-7-22.
//  Copyright 2011 D.I.O Game. All rights reserved.
//
#import "SNSLogType.h"
#import "YijifenHelper.h"
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

static YijifenHelper *_gYijifenHelper = nil;

@implementation YijifenHelper

+(YijifenHelper *)helper
{
	@synchronized(self) {
		if(!_gYijifenHelper) {
			_gYijifenHelper = [[YijifenHelper alloc] init];
		}
	}
	return _gYijifenHelper;
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
    [HMInterstitial shareInstance].delegate = nil;
    [HMInterstitial destroyDealloc];
	[super dealloc];
}

-(void) initSession
{
	if(isSessionInitialized) return;

    stAppKey = [SystemUtils getGlobalSetting:@"kYijifenPublisherKey"];
    if(!stAppKey || [stAppKey length]<3) stAppKey = [SystemUtils getSystemInfo:@"kYijifenPublisherKey"];
    if(!stAppKey || [stAppKey length]<3) return;
    NSArray *arr = [stAppKey componentsSeparatedByString:@","];
    if([arr count]<3) return;
    
    isSessionInitialized = YES; pendingCoins = 0;
    [stAppKey retain];
    
    //开发者
    [HMUserMessage shareInstance].hmUserAppId =[arr objectAtIndex:0];;
    [HMUserMessage shareInstance].hmUserDevId =[arr objectAtIndex:1];
    [HMUserMessage shareInstance].hmAppKey =[arr objectAtIndex:2];
    [HMUserMessage shareInstance].hmChannel =@"IOS2.0";
    [HMUserMessage shareInstance].hmCoop_info =@"coopInfo";//此参数是服务器端回调必须使用的参数。值为用户id（用户指的是开发者app的用户），默认是coopinfo
    //初始化
    HMInitServer *InitData  = [[HMInitServer alloc]init];
    [InitData  getInitEscoreData];
    [InitData  release];
    
    
    interstitialStatus = OFFER_STATUS_NONE; offerStatus = OFFER_STATUS_NONE;
    [self loadInterstitial];
    [self checkPointsLazy];
}

// 如果昨天有打开广告墙，就检查是否有奖励
-(void) checkPointsLazy
{
    // 显示广告的时间
    int showTime = [[SystemUtils getNSDefaultObject:@"kYiJiFenShowTime"] intValue];
    if(showTime==0) return;
    // 检查奖励的时间
    int checkTime = [[SystemUtils getNSDefaultObject:@"kYiJiFenCheckTime"] intValue];
    if(checkTime>showTime+1) return;
    [self initSession];
    [self checkPoints];
}

- (void) loadOffer
{
}

- (void) loadInterstitial
{
    // 加载弹窗
    
    UIInterfaceOrientation interfaceOrientation = [SystemUtils getGameOrientation];
    UIViewController *root = [SystemUtils getAbsoluteRootViewController];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
        if (UIInterfaceOrientationIsLandscape(interfaceOrientation)) { //横屏
            [[HMInterstitial shareInstance]initWithFrame:root.view.bounds andPicFrame:CGRectMake(70,20 , 300, 270) andOrientation:@"Landscape"  andDelegate:self];
        }
        if (UIInterfaceOrientationIsPortrait(interfaceOrientation)) {//竖屏
            
            [[HMInterstitial shareInstance]initWithFrame:root.view.bounds andPicFrame:CGRectMake(20, 90, 270, 300) andOrientation:@"Portrait" andDelegate:self];
        }
    }
    else
    {
        if (UIInterfaceOrientationIsLandscape(interfaceOrientation)) {//横屏
            [[HMInterstitial shareInstance]initWithFrame:root.view.bounds andPicFrame:CGRectMake(250, 100, 600, 540) andOrientation:@"Landscape" andDelegate:self];
            
        }
        if (UIInterfaceOrientationIsPortrait(interfaceOrientation)) {//竖屏
            [[HMInterstitial shareInstance]initWithFrame:root.view.bounds andPicFrame:CGRectMake(80, 260, 540, 600) andOrientation:@"Portrait" andDelegate:self];
        }
    }
    
    [HMInterstitial shareInstance].viewController = [SystemUtils getAbsoluteRootViewController];
    
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
    [[HMInterstitial shareInstance] show];

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
    [SystemUtils setNSDefaultObject:[NSNumber numberWithInt:date] forKey:@"kYiJiFenShowTime"];
    
    //显示广告墙
    HMIntegralScore *integralWall = [[HMIntegralScore alloc] init];
    integralWall.delegate = self;
    UIViewController *root = [SystemUtils getAbsoluteRootViewController];
    [root presentViewController:integralWall animated:YES completion:nil];
    [integralWall release];
}

-(void) hideOffers
{
    
}

-(void)checkPoints
{
    [self initSession];
    SNSLog(@"start checking points");
    [HMScore getScore:self];
    int date = [SystemUtils getTodayDate];
    [SystemUtils setNSDefaultObject:[NSNumber numberWithInt:date] forKey:@"kYiJiFenCheckTime"];
}

-(BOOL) isOfferReady
{
    return (offerStatus==OFFER_STATUS_READY);
}






#pragma mark - IntegralWall delegate

-(void)OpenIntegralScore:(int)_value//1 打开成功  0 打开失败
{
    if (_value == 1) {
        NSLog(@"积分墙打开成功");
        offerStatus = OFFER_STATUS_SHOWING;
    }
    else
    {
        NSLog(@"积分墙获取数据失败");
        offerStatus = OFFER_STATUS_LOADFAIL;
    }
}


-(void)CloseIntegralScore//墙关闭
{
    offerStatus = OFFER_STATUS_NONE;
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
}

#pragma mark - 获取积分回调
-(void)getHmScore:(int)_score  status:(int)_value unit:(NSString *) unit;// status:1 获取成功  0 获取失败
{
    if(_value == 1 && _score > 0){
        //获取成功就把所有积分换成 gold 或者 gem
        [HMScore consumptionScore:_score delegate:self];
    }
    
    NSLog(@"当前积分为：%d,获取状态：%d,单位:%@",_score,_value,unit);
}

#pragma mark - 消耗积分回调
-(void)consumptionHmScore:(int)_score status:(int)_value;//消耗积分 status:1 消耗成功  0 消耗失败
{
    if (_score == 0) return;
    
    if (_value == 1) {
        int coinType = [[SystemUtils getGlobalSetting:@"kYijifenCoinType"] intValue];
        if(coinType<=0) coinType = [[SystemUtils getSystemInfo:@"kYijifenCoinType"] intValue];
        if(coinType<=0) coinType = 1;
        int amount = _score;
        [SystemUtils addGameResource:amount ofType:coinType];
        
        NSString *coinKey = [NSString stringWithFormat:@"CoinName%d",coinType];
        
        NSString *leafName = [SystemUtils getLocalizedString:coinKey];
        if(amount>1) leafName = [StringUtils getPluralFormOfWord:leafName];
        NSString *mesg = [NSString stringWithFormat:[SystemUtils getLocalizedString:@"Congratulations! You've got %1$i %2$@ for free!"], amount, leafName];
        NSString *title = [SystemUtils getLocalizedString:@"Ad Bonus Received"];
        [SystemUtils showSNSAlert:title message:mesg];
        
        NSLog(@"消耗积分为：%d,消耗状态：%d",_score,_value);
    }
    
}


#pragma mark - interstitial delegate

//1 插屏弹出成功  0 插屏弹出失败
-(void)openInterstitial:(int)_value
{
    if (_value == 1) {
        NSLog(@"弹出插屏_成功");
    }
    else
    {
        NSLog(@"弹出插屏_失败");
    }
}

//插屏关闭
-(void)closeInterstitial
{
    interstitialStatus = OFFER_STATUS_NONE;
    [self loadInterstitial];
}

//预加载成功
-(void)getInterstitialDataSuccess
{
    interstitialStatus = OFFER_STATUS_READY;
}


//预加载失败
-(void)getInterstitialDataFail
{
   interstitialStatus = OFFER_STATUS_LOADFAIL;
}



@end
