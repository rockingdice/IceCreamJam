//
//  TapjoyHelper.m
//  iPetHotel
//
//  Created by LEON on 11-7-22.
//  Copyright 2011 D.I.O Game. All rights reserved.
//
#import "SNSLogType.h"
#import "YoumiHelper.h"
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
#import "YouMiWall.h"
#import "YouMiPointsManager.h"

static YoumiHelper *_gYoumiHelper = nil;

@implementation YoumiHelper

+(YoumiHelper *)helper
{
	@synchronized(self) {
		if(!_gYoumiHelper) {
			_gYoumiHelper = [[YoumiHelper alloc] init];
		}
	}
	return _gYoumiHelper;
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

    stAppKey = [SystemUtils getGlobalSetting:@"kYoumiAppID"];
    if(!stAppKey || [stAppKey length]<3) stAppKey = [SystemUtils getSystemInfo:@"kYoumiAppID"];
    NSString *stAppSecret = [SystemUtils getGlobalSetting:@"kYoumiAppSecret"];
    if(!stAppSecret || [stAppSecret length]<3) stAppSecret = [SystemUtils getSystemInfo:@"kYoumiAppSecret"];
    if(!stAppKey || [stAppKey length]<3) return;
    if(!stAppSecret || [stAppSecret length]<3) return;
    
    isSessionInitialized = YES; isOfferLoaded = NO; pendingCoins = 0; isOfferShowing = NO;
    [stAppKey retain];
    
    [YouMiConfig setShouldGetLocation:NO];
    // 替换下面的appID和appSecret为你的appid和appSecret
    [YouMiConfig launchWithAppID:stAppKey appSecret:stAppSecret];
    // 开启积分管理[本例子使用自动管理];
    [YouMiPointsManager enable];
    [YouMiPointsManager setManualCheck:YES];//设置为yes，禁止YouMiSDK自动向服务器发送查询积分请求
    // 开启积分墙
    [YouMiWall enable];
    [YouMiConfig setFullScreenWindow:[UIApplication sharedApplication].keyWindow];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pointsGotted:) name:kYouMiPointsManagerRecivedPointsNotification object:nil];
 
    [self checkPointsLazy];

	
}

// 如果昨天有打开广告墙，就检查是否有奖励
-(void) checkPointsLazy
{
    // 显示广告的时间
    int showTime = [[SystemUtils getNSDefaultObject:@"kYoumiShowTime"] intValue];
    if(showTime==0) return;
    // 检查奖励的时间
    int checkTime = [[SystemUtils getNSDefaultObject:@"kYoumiCheckTime"] intValue];
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
    int date = [SystemUtils getTodayDate];
    [SystemUtils setNSDefaultObject:[NSNumber numberWithInt:date] forKey:@"kYoumiShowTime"];
    
    [YouMiWall showOffers:YES didShowBlock:^{
        SNSLog(@"有米积分墙已显示");
    } didDismissBlock:^{
        SNSLog(@"有米积分墙已退出");
        isOfferShowing = NO;
    }];

}

-(void) hideOffers
{
    
}

-(void)checkPoints
{
    [self initSession];
    SNSLog(@"start checking youmi points");
    [YouMiPointsManager checkPoints];

    // [[LmmobAdWallSDK defaultSDK] ScoreQuery];
	// This method requests the tapjoy server for current virtual currency of the user.
	// if([TapjoyConnect 
	// [TapjoyConnect getTapPoints];
    int date = [SystemUtils getTodayDate];
    [SystemUtils setNSDefaultObject:[NSNumber numberWithInt:date] forKey:@"kYoumiCheckTime"];
}

-(BOOL) isOfferReady
{
    [self initSession];
    return isOfferLoaded;
}


- (void)pointsGotted:(NSNotification *)notification {
    int score = [YouMiPointsManager pointsRemained];
    if(score<=0) return;
    int coinType = [[SystemUtils getGlobalSetting:@"kYoumiCoinType"] intValue];
    if(coinType<=0)coinType = [[SystemUtils getSystemInfo:@"kYoumiCoinType"] intValue];
    if(coinType<=0) coinType = 1;
	
    int amount = score;
    
	[SystemUtils addGameResource:amount ofType:coinType];
    
    NSString *coinKey = [NSString stringWithFormat:@"CoinName%d",coinType];
    
    NSString *leafName = [SystemUtils getLocalizedString:coinKey];
    if(amount>1) leafName = [StringUtils getPluralFormOfWord:leafName];
	NSString *mesg = [NSString stringWithFormat:[SystemUtils getLocalizedString:@"Congratulations! You've got %1$i %2$@ for free!"], amount, leafName];
    NSString *title = [SystemUtils getLocalizedString:@"Ad Bonus Received"];
    [SystemUtils showSNSAlert:title message:mesg];
    
    [YouMiPointsManager spendPoints:amount];
    
    /*
    NSDictionary *dict = [notification userInfo];
    NSNumber *freshPoints = [dict objectForKey:kYouMiPointsManagerFreshPointsKey];
    // freshPoints的积分不应该拿来使用,积分已经被YouMiSDK保存了, 只是用于告知一下用户, 可以通过 [YouMiPointsManager spendPoints:]来使用积分。
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"通知" message:[NSString stringWithFormat:@"获得%@积分", freshPoints] delegate:nil cancelButtonTitle:@"好的" otherButtonTitles:nil];
    [alert show];
    [alert release];
    self.pointsLabel.text = [NSString stringWithFormat:@"当前积分: %d", [YouMiPointsManager pointsRemained]];
     */
}



@end
