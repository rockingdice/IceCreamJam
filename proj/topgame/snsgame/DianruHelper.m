//
//  TapjoyHelper.m
//  iPetHotel
//
//  Created by LEON on 11-7-22.
//  Copyright 2011 D.I.O Game. All rights reserved.
//
#import "SNSLogType.h"
#import "DianruHelper.h"
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

static DianruHelper *_gDianruHelper = nil;

@implementation DianruHelper

+(DianruHelper *)helper
{
	@synchronized(self) {
		if(!_gDianruHelper) {
			_gDianruHelper = [[DianruHelper alloc] init];
		}
	}
	return _gDianruHelper;
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

    stAppKey = [SystemUtils getGlobalSetting:@"kDianruAppID"];
    if(!stAppKey || [stAppKey length]<3) stAppKey = [SystemUtils getSystemInfo:@"kDianruAppID"];
    if(!stAppKey || [stAppKey length]<3) return;
    
    isSessionInitialized = YES; isOfferLoaded = NO; pendingCoins = 0; isOfferShowing = NO;
    [stAppKey retain];
    
    // 初始化代理，用于接收获取积分和消费积分结果，并设置系统ApplicationKey
    [DianRuAdWall initAdWallWithDianRuAdWallDelegate:self];
    
    [self checkPointsLazy];

	
}

// 如果昨天有打开广告墙，就检查是否有奖励
-(void) checkPointsLazy
{
    // 显示广告的时间
    int showTime = [[SystemUtils getNSDefaultObject:@"kDianruShowTime"] intValue];
    if(showTime==0) return;
    // 检查奖励的时间
    int checkTime = [[SystemUtils getNSDefaultObject:@"kDianruCheckTime"] intValue];
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
    [SystemUtils setNSDefaultObject:[NSNumber numberWithInt:date] forKey:@"kDianruShowTime"];
    
    UIViewController *root = [SystemUtils getRootViewController];
    //显示广告墙
    [DianRuAdWall showAdWall:root];
}

-(void) hideOffers
{
    
}

-(void)checkPoints
{
    [self initSession];
    SNSLog(@"start checking youmi points");
    [DianRuAdWall getRemainPoint];

    // [[LmmobAdWallSDK defaultSDK] ScoreQuery];
	// This method requests the tapjoy server for current virtual currency of the user.
	// if([TapjoyConnect 
	// [TapjoyConnect getTapPoints];
    int date = [SystemUtils getTodayDate];
    [SystemUtils setNSDefaultObject:[NSNumber numberWithInt:date] forKey:@"kDianruCheckTime"];
}

-(BOOL) isOfferReady
{
    [self initSession];
    return isOfferLoaded;
}

#pragma mark DianRuAdWallDelegate

-(void)didReceiveSpendScoreResult:(BOOL)isSuccess
{
    if(!isSuccess) return;
    int score = pendingCoins;
    pendingCoins = 0;
    if(score<=0) return;
    int coinType = [[SystemUtils getGlobalSetting:@"kDianruCoinType"] intValue];
    if(coinType<=0)coinType = [[SystemUtils getSystemInfo:@"kDianruCoinType"] intValue];
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

-(void)didReceiveGetScoreResult:(int)point
{
    //返回-1，为获取积分失败，可能是由于网络原因，或者服务器暂时无法访问等。提示用户
    SNSLog(@"%d",point);
    
    if(point>0) {
        pendingCoins = point;
        [DianRuAdWall spendPoint:point];
    }
}
/*
 用户关闭点积分时的回调
 */
-(void)dianruAdWallClose
{
    isOfferShowing = NO;
}

-(NSString *)applicationKey
{
    return stAppKey;
}

-(NSString *)dianruAdWallAppType
{
    // NSString *model = [SystemUtils getDeviceType];
    if([SystemUtils isiPad]) return @"ipad";
    return @"iphone";
}

@end
