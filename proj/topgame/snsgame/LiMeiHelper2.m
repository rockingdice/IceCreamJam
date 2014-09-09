//
//  TapjoyHelper.m
//  iPetHotel
//
//  Created by LEON on 11-7-22.
//  Copyright 2011 D.I.O Game. All rights reserved.
//
#import "SNSLogType.h"
#import "LiMeiHelper2.h"
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

static LiMeiHelper2 *_gLiMeiHelper2 = nil;

@implementation LiMeiHelper2

+(LiMeiHelper2 *)helper
{
	@synchronized(self) {
		if(!_gLiMeiHelper2) {
			_gLiMeiHelper2 = [[LiMeiHelper2 alloc] init];
		}
	}
	return _gLiMeiHelper2;
}

-(id)init
{
    self = [super init];
    
	isSessionInitialized = NO; stAppKey = nil; stPopupKey = nil; pPopupView = nil;
	
	return self;
}

-(void)dealloc
{
    [pLimeiView release];
    [stAppKey release];
    if(pPopupView) [pPopupView release];
    [stPopupKey release];
	[super dealloc];
}

-(void) initSession
{
	if(isSessionInitialized) return;
    
    stAppKey = [SystemUtils getGlobalSetting:@"kLiMeiEntranceID"];
    if(!stAppKey || [stAppKey length]<3) stAppKey = [SystemUtils getSystemInfo:@"kLiMeiEntranceID"];
    stPopupKey = [SystemUtils getGlobalSetting:@"kLiMeiPopupID"];
    if(!stPopupKey || [stPopupKey length]<3) stPopupKey = [SystemUtils getSystemInfo:@"kLiMeiPopupID"];
    
    if(!stAppKey || [stAppKey length]<3) return;
    if(!stPopupKey || [stPopupKey length]<3) stPopupKey = nil;
    else [stPopupKey retain];
    [stAppKey retain];
	
    isSessionInitialized = YES;
    
    // [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showOffers) name:@"PushAD" object:nil];
    // entranceID: 4834cdd70c90821fd807b4cfafeb2d63
    // mediaID: 7f297998776f5aaa3a45c9cca1fa5bf5
    // adWallID: 2d4ac11944143a74458dd5d6f42fef38
    // -(void)GetAdWallWithEntranceID:(NSString *)entranceid AndDelegate:(id<LmmobAdWallDelegate>)delegate;
    SNSLog(@"id:%@ popupID:%@", stAppKey,stPopupKey);
    pLimeiView = [[immobView alloc] initWithAdUnitID:stAppKey];
    pLimeiView.delegate = self; // [pLimeiView immobViewRequest];
    // [pLimeiView immobViewRequest];
    if(stPopupKey) {
        pPopupView = [[immobView alloc] initWithAdUnitID:stPopupKey];
        pPopupView.delegate = self;
        [pPopupView immobViewRequest];
    }
	
}

// 如果昨天有打开广告墙，就检查是否有奖励
-(void) checkPointsLazy
{
    // 显示广告的时间
    int showTime = [[SystemUtils getNSDefaultObject:@"kLimeiShowTime"] intValue];
    if(showTime==0) return;
    // 检查奖励的时间
    int checkTime = [[SystemUtils getNSDefaultObject:@"kLimeiCheckTime"] intValue];
    if(checkTime>showTime+1) return;
    [self initSession];
    [self checkPoints];
}


- (void) showOffers
{
    NSLog(@"%s",__func__);
    [self initSession];
#ifndef DEBUG
    if(![SystemUtils getInterruptMode]) return;
#endif
    adType = 0;
    
    if(![pLimeiView isAdReady]) return;
    
    [SystemUtils showInGameLoadingView];
    [pLimeiView immobViewRequest];

    [SystemUtils setInterruptMode:NO];
    /*
    if ([self isOfferReady]) {
        if(container) {
            [container release]; container = nil;
        }

        UIViewController * V = (UIViewController *)viewController;
        // [[CCDirector sharedDirector].openGLView addSubview:V.view];
        UIViewController *root = [SystemUtils getRootViewController];
        if(!root) root = [SystemUtils getAbsoluteRootViewController];
        [root.view addSubview:V.view];
        
        [SystemUtils setNSDefaultObject:@"1" forKey:@"showingOffer"];
        int date = [SystemUtils getTodayDate];
        [SystemUtils setNSDefaultObject:[NSNumber numberWithInt:date] forKey:@"kLimeiShowTime"];
    }
     */
}

- (void) showInterstitial
{
    NSLog(@"%s",__func__);
    [self initSession];
    if(pPopupView==nil) return;
#ifndef DEBUG
    if(![SystemUtils getInterruptMode]) return;
#endif
    adType = 1;
    // [pPopupView immobViewRequest];
    if(![pPopupView isAdReady]) return;
    
    UIViewController *root = nil;
    root = [SystemUtils getRootViewController];
    if(!root) root = [SystemUtils getAbsoluteRootViewController];
    [root.view addSubview:pPopupView];
    [pPopupView immobViewDisplay];
    int date = [SystemUtils getTodayDate];
    [SystemUtils setNSDefaultObject:[NSNumber numberWithInt:date] forKey:@"kLimeiShowTime"];

    [SystemUtils setInterruptMode:NO];
    
}
-(void) hideOffers
{
    /*
    if(viewController) {
        UIViewController * V = (UIViewController *)viewController;
        [V.view removeFromSuperview];
    }
     */
    
}

-(void)checkPoints
{
    [self initSession];
    SNSLog(@"start checking limei points");
    checkPointType = 0;
    [pLimeiView immobViewQueryScoreWithAdUnitID:stAppKey];
    // [[LmmobAdWallSDK defaultSDK] ScoreQuery];
	// This method requests the tapjoy server for current virtual currency of the user.
	// if([TapjoyConnect 
	// [TapjoyConnect getTapPoints];
    int date = [SystemUtils getTodayDate];
    [SystemUtils setNSDefaultObject:[NSNumber numberWithInt:date] forKey:@"kLimeiCheckTime"];
}

-(void) checkPoints2
{
    if(pPopupView==nil) return;
    checkPointType = 1;
    [pPopupView immobViewQueryScoreWithAdUnitID:stPopupKey];
}

-(BOOL) isOfferReady
{
    [self initSession];
    // if(viewController) return YES;
    return YES;
}


#pragma mark immobViewDelegate

- (UIViewController *)immobViewController
{
    return [SystemUtils getAbsoluteRootViewController];
}

- (void) immobViewDidReceiveAd:(immobView *)adView
{
    // BOOL AdReady = YES;
    SNSLog("receive adReady:%d",adView.isAdReady);
    
    if(adType==0) {
        [SystemUtils hideInGameLoadingView];
        UIViewController *root = nil;
        root = [SystemUtils getRootViewController];
        if(!root) root = [SystemUtils getAbsoluteRootViewController];
        [root.view addSubview:pLimeiView];
        [pLimeiView immobViewDisplay];
        int date = [SystemUtils getTodayDate];
        [SystemUtils setNSDefaultObject:[NSNumber numberWithInt:date] forKey:@"kLimeiShowTime"];
    }
    /*
    if(adView==nil) AdReady = NO;
    if (AdReady && adView.isAdReady) {
     UIViewController *root = nil;
     root = [SystemUtils getRootViewController];
     if(!root) root = [SystemUtils getAbsoluteRootViewController];
     if(!root) {
     SNSLog("failed to get rootViewController");
     return;
     }
     
     [root.view addSubview:adView];
     [adView immobViewDisplay];
     
     int date = [SystemUtils getTodayDate];
     [SystemUtils setNSDefaultObject:[NSNumber numberWithInt:date] forKey:@"kLimeiShowTime"];
    }
    else if(adType==0) {
        SNSAlertView *av = [[SNSAlertView alloc]
                            initWithTitle:[SystemUtils getLocalizedString: @"No Offer Now"]
                            message:[SystemUtils getLocalizedString: @"There's no free offer now, please try again later!"]
                            delegate:nil
                            cancelButtonTitle:[SystemUtils getLocalizedString:@"OK"]
                            otherButtonTitle: nil];
        
        av.tag = kTagAlertNone;
        // [[smPopupWindowQueue createQueue] pushToQueue:av timeOut:0];
        [av showHard];
        [av release];
    }
     */
}

- (void) immobView: (immobView*) immobView didFailReceiveimmobViewWithError: (NSInteger) errorCode
{
    SNSLog("errorCode:%i", errorCode);
    [SystemUtils setInterruptMode:YES];
}

- (void) emailNotSetupForAd:(immobView *)adView
{
    SNSLog("email not setup");
    [SystemUtils setInterruptMode:YES];
}

- (void) onDismissScreen:(immobView *)immobView
{
    SNSLog(@"dismissed");
    [self hideOffers];
    [[NSNotificationCenter defaultCenter] postNotificationName:LIMEI_SHOW_BOX_CLOSE_NOTIFICATION object:nil userInfo:nil];
    [SystemUtils setNSDefaultObject:@"0" forKey:@"showingOffer"];
    [SystemUtils setInterruptMode:YES];
    if(adType==1) [pPopupView immobViewRequest];
}
/**
 * Called when an ad is clicked and going to start a new page that will leave the application
 * 当广告调用一个新的页面并且会导致离开目前运行程序时被调用。如：调用本地地图程序。
 *
 */
- (void) onLeaveApplication:(immobView *)immobView
{
    [SystemUtils setNSDefaultObject:@"0" forKey:@"showingOffer"];
    [SystemUtils setInterruptMode:YES];
}

/**
 * Called when an page is created in front of the app.
 * 当广告页面被创建并且显示在覆盖在屏幕上面时调用本方法。
 */
- (void) onPresentScreen:(immobView *)immobView
{
    [SystemUtils setNSDefaultObject:@"1" forKey:@"showingOffer"];
}

- (void) immobViewQueryScore:(NSUInteger)score WithMessage:(NSString *)message 
{
    
    int rate = [[SystemUtils getGlobalSetting:@"kLimeiLeafRate"] intValue];
    if(rate<=0) rate = [[SystemUtils getSystemInfo:@"kLimeiLeafRate"] intValue];
    if(rate<=0) rate = 1;
    int coinType = [[SystemUtils getSystemInfo:@"kLimeiCoinType"] intValue];
    if(coinType<=0) coinType = 2;
	int amount = score/rate;
    SNSLog(@"get %i points(%i) message:%@", amount, score, message);
	if (amount <= 0) {
        if(checkPointType==0) {
            [self checkPoints2];
        }
        return;
    }
	// int localAmount = [SystemUtils getTapjoyPoint];
	// TODO: add log
    
	[SystemUtils addGameResource:amount ofType:coinType];
    // [pLimeiView immobViewReducscore:amount*rate WithAdUnitID:stAppKey];
    if(checkPointType==0) {
        [pLimeiView immobViewReduceScore:amount*rate WithAdUnitID:stAppKey];
    }
    else {
//#ifndef DEBUG
        [pPopupView immobViewReduceScore:amount*rate WithAdUnitID:stPopupKey];
//#endif
    }
    NSString *coinKey = [NSString stringWithFormat:@"CoinName%d",coinType];
    
    NSString *leafName = [SystemUtils getLocalizedString:coinKey];
    if(amount>1) leafName = [StringUtils getPluralFormOfWord:leafName];
	NSString *mesg = [NSString stringWithFormat:[SystemUtils getLocalizedString:@"Congratulations! You've got %1$i %2$@ for free!"], amount, leafName];
    NSString *title = [SystemUtils getLocalizedString:@"Ad Bonus Received"];
    [SystemUtils showSNSAlert:title message:mesg];
    /*
	// show notice
	smPopupWindowNotice *swqAlert = [[smPopupWindowNotice alloc] initWithNibName:@"smPopupWindowNotice" bundle:nil];
	swqAlert.setting = [NSDictionary dictionaryWithObjectsAndKeys:mesg, @"content", @"", @"action", @"0", @"prizeCoin", @"0", @"prizeLeaf", nil];
	[[smPopupWindowQueue createQueue] pushToQueue:swqAlert timeOut:0];
    [swqAlert release];
     */
    if(checkPointType==0) {
        [self checkPoints2];
    }

}



@end
