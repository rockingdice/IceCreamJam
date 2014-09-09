//
//  TapjoyHelper.m
//  iPetHotel
//
//  Created by LEON on 11-7-22.
//  Copyright 2011 D.I.O Game. All rights reserved.
//
#import "SNSLogType.h"
#import "LiMeiHelper.h"
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

static LiMeiHelper *_gLiMeiHelper = nil;

@implementation LiMeiHelper

+(LiMeiHelper *)helper
{
	@synchronized(self) {
		if(!_gLiMeiHelper) {
			_gLiMeiHelper = [[LiMeiHelper alloc] init];
		}
	}
	return _gLiMeiHelper;
}

-(id)init
{
    self = [super init];
    
	isSessionInitialized = NO; stAppKey = nil;
	
	return self;
}

-(void)dealloc
{
    [pLimeiView release];
    [stAppKey release];
	[super dealloc];
}

-(void) initSession
{
	if(isSessionInitialized) return;
    
    stAppKey = [SystemUtils getGlobalSetting:@"kLiMeiEntranceID"];
    if(!stAppKey) stAppKey = [SystemUtils getSystemInfo:@"kLiMeiEntranceID"];
    if(!stAppKey) return;
    [stAppKey retain];
	
    isSessionInitialized = YES;
    
    // [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showOffers) name:@"PushAD" object:nil];
    // entranceID: 4834cdd70c90821fd807b4cfafeb2d63
    // mediaID: 7f297998776f5aaa3a45c9cca1fa5bf5
    // adWallID: 2d4ac11944143a74458dd5d6f42fef38
    // -(void)GetAdWallWithEntranceID:(NSString *)entranceid AndDelegate:(id<LmmobAdWallDelegate>)delegate;
    SNSLog(@"id:%@", stAppKey);
    pLimeiView = [[immobView alloc] initWithAdUnitID:stAppKey];
    pLimeiView.delegate = self;
	
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
    [pLimeiView immobViewRequest];
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
    [pLimeiView immobViewQueryScoreWithAdUnitID:stAppKey];
    // [[LmmobAdWallSDK defaultSDK] ScoreQuery];
	// This method requests the tapjoy server for current virtual currency of the user.
	// if([TapjoyConnect 
	// [TapjoyConnect getTapPoints];
    int date = [SystemUtils getTodayDate];
    [SystemUtils setNSDefaultObject:[NSNumber numberWithInt:date] forKey:@"kLimeiCheckTime"];
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

- (void) immobViewDidReceiveAd:(BOOL)AdReady
{
    SNSLog("receive ad:%d",AdReady);
    if (AdReady) {
        UIViewController *root = nil;
        root = [SystemUtils getRootViewController];
        if(!root) root = [SystemUtils getAbsoluteRootViewController];
        if(!root) {
            SNSLog("failed to get rootViewController");
            return;
        }
        
        /*
#ifdef SNS_LIMEI_FORCE_LANDSCAPE
        // set frame size
        CGRect r = root.view.frame;
        if(r.size.height>r.size.width) {
            // root.view.frame = CGRectMake(r.origin.x, r.origin.y, r.size.height, r.size.width);
            if([SystemUtils isiPad]) {
                pLimeiView.frame = CGRectMake(0, 0, r.size.height, r.size.width);
            }
            else {
                pLimeiView.frame = CGRectMake(80, -80, r.size.width, r.size.height);
                pLimeiView.transform = CGAffineTransformMakeRotation(-M_PI_2);
            }
        }
#endif
         */
        [root.view addSubview:pLimeiView];
        [pLimeiView immobViewDisplay];
        
        [SystemUtils setNSDefaultObject:@"1" forKey:@"showingOffer"];
        int date = [SystemUtils getTodayDate];
        [SystemUtils setNSDefaultObject:[NSNumber numberWithInt:date] forKey:@"kLimeiShowTime"];
    }
    else {
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
}

- (void) immobView: (immobView*) immobView didFailReceiveimmobViewWithError: (NSInteger) errorCode
{
    SNSLog("errorCode:%i", errorCode);
}

- (void) emailNotSetupForAd:(immobView *)adView
{
    SNSLog("email not setup");
}

- (void) onDismissScreen:(immobView *)immobView
{
    NSLog(@"%s", __func__);
    [self hideOffers];
    [[NSNotificationCenter defaultCenter] postNotificationName:LIMEI_SHOW_BOX_CLOSE_NOTIFICATION object:nil userInfo:nil];
    [SystemUtils setNSDefaultObject:@"0" forKey:@"showingOffer"];
}

- (void) immobViewQueryScore:(NSUInteger)score WithMessage:(NSString *)message 
{
    
    int rate = [[SystemUtils getSystemInfo:@"kLimeiLeafRate"] intValue];
    if(rate<=0) rate = 1;
	int amount = score/rate;
    SNSLog(@"get %i points(%i)", amount, score);
	if (amount <= 0) return;
	// int localAmount = [SystemUtils getTapjoyPoint];
	// TODO: add log
    
	[SystemUtils addGameResource:amount ofType:kGameResourceTypeLeaf];
    // [pLimeiView immobViewReducscore:amount*rate WithAdUnitID:stAppKey];
    [pLimeiView immobViewReduceScore:amount*rate WithAdUnitID:stAppKey];
    
    NSString *leafName = [SystemUtils getLocalizedString:@"CoinName2"];
    if(amount>1) leafName = [StringUtils getPluralFormOfWord:leafName];
	NSString *mesg = [NSString stringWithFormat:[SystemUtils getLocalizedString:@"Congratulations! You've got %1$i %2$@ for free!"], amount, leafName];
	// show notice
	smPopupWindowNotice *swqAlert = [[smPopupWindowNotice alloc] initWithNibName:@"smPopupWindowNotice" bundle:nil];
	swqAlert.setting = [NSDictionary dictionaryWithObjectsAndKeys:mesg, @"content", @"", @"action", @"0", @"prizeCoin", @"0", @"prizeLeaf", nil];
	[[smPopupWindowQueue createQueue] pushToQueue:swqAlert timeOut:0];
    [swqAlert release];
}



@end
